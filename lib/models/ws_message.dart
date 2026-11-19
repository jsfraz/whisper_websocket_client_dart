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

  /// Message asking for the archive delta above the client's cursor, and the
  /// mutation log above [sinceEventSeq] when it is given.
  factory WsMessage.sync(int sinceSeq, {int? sinceEventSeq}) {
    return WsMessage._internal(
      WsMessageType.sync,
      WsSync(sinceSeq, sinceEventSeq: sinceEventSeq),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'payload': payload,
    };
  }
}
