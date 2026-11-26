import 'live_location.dart';
import 'new_private_message.dart';
import 'presence.dart';
import 'typing.dart';
import 'ws_message_type.dart';
import 'ws_sync.dart';

/// A message to be sent to the WebSocket server
class WsMessage {
  final WsMessageType type; // Type of the message
  final dynamic payload; // Payload to be sent

  /// Internal constructor
  WsMessage._internal(this.type, this.payload);

  /// Message for publishing private message
  factory WsMessage.privateMessage(NewPrivateMessage privateMessage) {
    return WsMessage._internal(WsMessageType.message, privateMessage);
  }

  /// Message asking for the archive delta above the client's cursor, and the
  /// mutation log above [sinceEventSeq] when it is given.
  factory WsMessage.sync(int sinceSeq, {int? sinceEventSeq}) {
    return WsMessage._internal(
      WsMessageType.sync,
      WsSync(sinceSeq, sinceEventSeq: sinceEventSeq),
    );
  }

  /// One "I am typing" hint for [peerId]. Relayed to the peer, never archived.
  factory WsMessage.typing(String peerId) {
    return WsMessage._internal(WsMessageType.typing, TypingRequest(peerId));
  }

  /// The caller's own presence for the named peers. Relayed, never stored.
  factory WsMessage.presence(List<String> peerIds, {required bool online}) {
    return WsMessage._internal(
      WsMessageType.presence,
      PresenceRequest(peerIds, online: online),
    );
  }

  /// One encrypted position for [peerId]. Relayed, never stored.
  factory WsMessage.liveLocation(String peerId, String payload) {
    return WsMessage._internal(
      WsMessageType.liveLocation,
      LiveLocationRequest(peerId, payload),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'payload': payload,
    };
  }
}
