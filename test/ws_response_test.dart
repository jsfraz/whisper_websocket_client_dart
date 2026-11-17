import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:whisper_websocket_client_dart/models/delivery_ack.dart';
import 'package:whisper_websocket_client_dart/models/synced.dart';
import 'package:whisper_websocket_client_dart/models/ws_message.dart';
import 'package:whisper_websocket_client_dart/models/ws_response.dart';
import 'package:whisper_websocket_client_dart/models/ws_response_type.dart';
import 'package:whisper_websocket_client_dart/ws_client.dart';

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
    expect(synced.messages.single.peerId,
        '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d12');
    expect(synced.peers.single.username, 'sender');
  });

  test('a sync request serialises the cursor', () {
    final json = jsonDecode(jsonEncode(WsMessage.sync(15).toJson()));
    expect(json['type'], 'sync');
    expect(json['payload']['sinceSeq'], 15);
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

  test('an unknown response type is reported as an error, not a crash', () {
    final response = WsResponse.fromUint8List(bytes({
      'type': 'somethingNew',
      'payload': null,
    }));
    expect(response.type, WsResponseType.error);
  });
}
