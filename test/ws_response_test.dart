import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:shept_websocket_client_dart/models/delivery_ack.dart';
import 'package:shept_websocket_client_dart/models/live_location.dart';
import 'package:shept_websocket_client_dart/models/message_event.dart';
import 'package:shept_websocket_client_dart/models/new_private_message.dart';
import 'package:shept_websocket_client_dart/models/presence.dart';
import 'package:shept_websocket_client_dart/models/synced.dart';
import 'package:shept_websocket_client_dart/models/typing.dart';
import 'package:shept_websocket_client_dart/models/ws_message.dart';
import 'package:shept_websocket_client_dart/models/ws_response.dart';
import 'package:shept_websocket_client_dart/models/ws_response_type.dart';
import 'package:shept_websocket_client_dart/ws_client.dart';

Uint8List bytes(Object json) =>
    Uint8List.fromList(utf8.encode(jsonEncode(json)));

Map<String, dynamic> messageJson({int seq = 1, String content = '"x"'}) => {
      'id': 'message-id',
      'seq': seq,
      'senderId': '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d11',
      'peerId': '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d12',
      'content': utf8.encode(content),
      'key': utf8.encode('k'),
      'nonce': utf8.encode('n'),
      'mac': utf8.encode('m'),
      'sentAt': '2026-11-15T20:00:00.123456789Z',
      'recipientOnline': false,
    };

void main() {
  // The delivery ack is what turns "written to the socket" into "stored in the
  // archive"; the id is what the client dedupes a resend by.
  test('a delivery ack carries the id, seq, receiver and timestamp', () {
    final response = WsResponse.fromUint8List(bytes({
      'type': 'ack',
      'payload': {
        'id': 'message-id',
        'seq': 42,
        'receiverId': '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d11',
        'sentAt': '2026-11-15T20:00:00.123456789Z',
      },
    }));

    expect(response.type, WsResponseType.ack);
    final ack = response.payload as DeliveryAck;
    expect(ack.id, 'message-id');
    expect(ack.seq, 42);
    expect(ack.receiverId, '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d11');
    expect(ack.sentAt.toUtc(), DateTime.utc(2026, 11, 15, 20, 0, 0, 123, 456));
  });

  // A sync answer must carry the cursor forward; the app stores it so the next
  // reconnect only asks for what it missed.
  test('a synced frame carries the delta, the peers and the cursor', () {
    final response = WsResponse.fromUint8List(bytes({
      'type': 'synced',
      'payload': {
        'messages': [messageJson(seq: 7)],
        'peers': [
          {
            'id': '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d11',
            'username': 'sender',
            'publicKey': 'PEM',
          }
        ],
        'syncedThrough': 7,
        'hasMore': false,
      },
    }));

    expect(response.type, WsResponseType.synced);
    final synced = response.payload as Synced;
    expect(synced.syncedThrough, 7);
    expect(synced.hasMore, isFalse);
    expect(synced.messages.single.seq, 7);
    expect(
        synced.messages.single.peerId, '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d12');
    expect(synced.peers.single.username, 'sender');
  });

  test('a sync request serialises the cursor', () {
    final json = jsonDecode(jsonEncode(WsMessage.sync(15).toJson()));
    expect(json['type'], 'sync');
    expect(json['payload']['sinceSeq'], 15);
    expect(json['payload'].containsKey('sinceEventSeq'), isFalse);
  });

  test('a sync request can also ask for the mutation log', () {
    final json =
        jsonDecode(jsonEncode(WsMessage.sync(15, sinceEventSeq: 4).toJson()));
    expect(json['payload']['sinceSeq'], 15);
    expect(json['payload']['sinceEventSeq'], 4);
  });

  // A parser that throws kills the stream subscription and the client goes
  // silent until a restart, so every malformed frame must become an error.
  test('an unreadable frame is reported as an error', () {
    final response = WsResponse.fromUint8List(
        Uint8List.fromList(utf8.encode('not json at all')));
    expect(response.type, WsResponseType.error);
  });

  test('a frame that is not an object is reported as an error', () {
    final response = WsResponse.fromUint8List(bytes(['a', 'b']));
    expect(response.type, WsResponseType.error);
  });

  test('a messages frame without a list is reported as an error', () {
    final response = WsResponse.fromUint8List(bytes({
      'type': 'messages',
      'payload': null,
    }));
    expect(response.type, WsResponseType.error);
  });

  test('an ack frame with a missing field is reported as an error', () {
    final response = WsResponse.fromUint8List(bytes({
      'type': 'ack',
      'payload': {'receiverId': 'x'},
    }));
    expect(response.type, WsResponseType.error);
  });

  test('a synced frame without a cursor is reported as an error', () {
    final response = WsResponse.fromUint8List(bytes({
      'type': 'synced',
      'payload': {'messages': [], 'peers': []},
    }));
    expect(response.type, WsResponseType.error);
  });

  test('disconnect is safe when nothing is connected', () {
    final client = WsClient('ws://127.0.0.1:1/ws');
    expect(client.isConnected, isFalse);
    client.disconnect();
    client.disconnect();
    expect(client.isConnected, isFalse);
  });

  test('an unknown response type is ignored, not reported as an error', () {
    // A newer server sending a frame this build has never heard of must not
    // turn every message into an error toast for the user.
    final response = WsResponse.fromUint8List(bytes({
      'type': 'somethingNew',
      'payload': null,
    }));
    expect(response.type, WsResponseType.unknown);
    expect(response.payload, isNull);
  });

  // A delete for everyone leaves a tombstone: the slot stays, the ciphertext is
  // gone. The parser used to throw on it, which made the whole frame an error.
  test('a tombstone message parses with empty ciphertext', () {
    final response = WsResponse.fromUint8List(bytes({
      'type': 'messages',
      'payload': [
        {
          ...messageJson(seq: 9),
          'content': null,
          'key': null,
          'nonce': null,
          'mac': null,
          'deletedAt': '2026-11-15T20:05:00Z',
        }
      ],
    }));

    expect(response.type, WsResponseType.messages);
    final message = (response.payload as List).single;
    expect(message.content, isNull);
    expect(message.deletedAt, isNotNull);
  });

  test('a live edit frame carries its ciphertext and version', () {
    final response = WsResponse.fromUint8List(bytes({
      'type': 'edit',
      'payload': {
        'v': 1,
        'eventSeq': 3,
        'messageId': 'message-id',
        'peerId': '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d12',
        'sentAt': '2026-11-15T20:00:00Z',
        'kind': 'edit',
        'actorId': '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d11',
        'content': utf8.encode('"new"'),
        'key': utf8.encode('k'),
        'nonce': utf8.encode('n'),
        'mac': utf8.encode('m'),
        'pinned': null,
        'createdAt': '2026-11-15T20:06:00Z',
      },
    }));

    expect(response.type, WsResponseType.edit);
    final event = response.payload;
    expect(event.v, 1);
    expect(event.eventSeq, 3);
    expect(event.kind, MessageEventKind.edit);
    expect(utf8.decode(event.content), '"new"');
    expect(event.pinned, isNull);
  });

  test('an unpin frame decodes the flag', () {
    final response = WsResponse.fromUint8List(bytes({
      'type': 'pin',
      'payload': {
        'v': 1,
        'eventSeq': 5,
        'messageId': 'message-id',
        'peerId': '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d12',
        'sentAt': '2026-11-15T20:00:00Z',
        'kind': 'pin',
        'actorId': '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d11',
        'content': null,
        'key': null,
        'nonce': null,
        'mac': null,
        'pinned': false,
        'createdAt': '2026-11-15T20:06:00Z',
      },
    }));

    expect(response.type, WsResponseType.pin);
    expect(response.payload.pinned, isFalse);
  });

  test('an open frame carries the instant the receiver opened it', () {
    final response = WsResponse.fromUint8List(bytes({
      'type': 'open',
      'payload': {
        'v': 1,
        'eventSeq': 9,
        'messageId': 'message-id',
        'peerId': '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d12',
        'sentAt': '2026-11-15T20:00:00Z',
        'kind': 'open',
        'actorId': '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d12',
        'content': null,
        'key': null,
        'nonce': null,
        'mac': null,
        'openedAt': '2026-11-15T20:07:00Z',
        'createdAt': '2026-11-15T20:07:00Z',
      },
    }));

    expect(response.type, WsResponseType.open);
    expect(response.payload.kind, MessageEventKind.open);
    expect(response.payload.openedAt, DateTime.utc(2026, 11, 15, 20, 7));
  });

  // The whole point of the second cursor: what happened while the device was
  // offline must be replayable, not only what arrived live.
  test('a synced frame carries events and cleared chats', () {
    final response = WsResponse.fromUint8List(bytes({
      'type': 'synced',
      'payload': {
        'messages': [],
        'peers': [],
        'events': [
          {
            'v': 1,
            'eventSeq': 8,
            'messageId': 'message-id',
            'peerId': '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d12',
            'sentAt': '2026-11-15T20:00:00Z',
            'kind': 'reaction',
            'actorId': '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d12',
            'content': null,
            'key': null,
            'nonce': null,
            'mac': null,
            'createdAt': '2026-11-15T20:06:00Z',
          }
        ],
        'cleared': [
          {
            'peerId': '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d12',
            'clearedAt': '2026-11-15T20:07:00Z',
          }
        ],
        'reads': [
          {
            'v': 1,
            'peerId': '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d12',
            'readAt': '2026-11-15T20:05:30Z',
          }
        ],
        'syncedThrough': 7,
        'eventsThrough': 8,
        'hasMore': false,
      },
    }));

    expect(response.type, WsResponseType.synced);
    final synced = response.payload as Synced;
    expect(synced.events.single.kind, MessageEventKind.reaction);
    expect(synced.events.single.content, isNull);
    expect(synced.eventsThrough, 8);
    expect(
        synced.cleared.single.peerId, '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d12');
  });

  test('the ephemeral frames carry only their version and peer state', () {
    final typing = WsResponse.fromUint8List(bytes({
      'type': 'typing',
      'payload': {'v': 1, 'peerId': '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d12'},
    }));
    expect(typing.type, WsResponseType.typing);
    final typed = typing.payload as TypingFrame;
    expect(typed.v, 1);
    expect(typed.peerId, '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d12');

    final presence = WsResponse.fromUint8List(bytes({
      'type': 'presence',
      'payload': {
        'v': 1,
        'peerId': '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d12',
        'online': false,
        'lastSeenAt': '2026-11-15T20:05:30Z',
      },
    }));
    expect(presence.type, WsResponseType.presence);
    final seen = presence.payload as PresenceFrame;
    expect(seen.online, isFalse);
    expect(seen.lastSeenAt, DateTime.utc(2026, 11, 15, 20, 5, 30));

    final location = WsResponse.fromUint8List(bytes({
      'type': 'liveLocation',
      'payload': {
        'v': 1,
        'peerId': '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d12',
        'payload': 'c2VjcmV0',
      },
    }));
    expect(location.type, WsResponseType.liveLocation);
    expect((location.payload as LiveLocationFrame).payload, 'c2VjcmV0');
  });

  test('an outgoing ephemeral frame names its topic and payload', () {
    // The payload is an object with its own toJson, exactly like the sync frame;
    // the wire shape is what jsonEncode produces.
    Map<String, dynamic> wire(WsMessage message) =>
        jsonDecode(jsonEncode(message)) as Map<String, dynamic>;

    expect(wire(WsMessage.typing('peer')), {
      'type': 'typing',
      'payload': {'peerId': 'peer'},
    });
    expect(wire(WsMessage.presence(['a', 'b'], online: true)), {
      'type': 'presence',
      'payload': {
        'peerIds': ['a', 'b'],
        'online': true,
      },
    });
    expect(wire(WsMessage.liveLocation('peer', 'c2VjcmV0')), {
      'type': 'liveLocation',
      'payload': {'peerId': 'peer', 'payload': 'c2VjcmV0'},
    });
  });

  // A disappearing message asks the server for a shorter life than retention.
  test('a message carries an optional ttl', () {
    final message = NewPrivateMessage(
      'peer',
      Uint8List.fromList([1]),
      Uint8List.fromList([2]),
      Uint8List.fromList([3]),
      Uint8List.fromList([4]),
      ttlSeconds: 3600,
    );
    expect(message.toJson()['ttlSeconds'], 3600);
    final plain = NewPrivateMessage(
      'peer',
      Uint8List.fromList([1]),
      Uint8List.fromList([2]),
      Uint8List.fromList([3]),
      Uint8List.fromList([4]),
    );
    expect(plain.toJson().containsKey('ttlSeconds'), isFalse);
  });
}
