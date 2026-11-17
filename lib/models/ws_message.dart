import 'new_private_message.dart';
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

  /// Message asking for the archive delta above the client's cursor.
  factory WsMessage.sync(int sinceSeq) {
    return WsMessage._internal(WsMessageType.sync, WsSync(sinceSeq));
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'payload': payload,
    };
  }
}
