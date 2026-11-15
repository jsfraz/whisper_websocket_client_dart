import 'delivery_ack.dart';
import 'new_private_message.dart';
import 'ws_message_type.dart';

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

  /// Message confirming that [messages] are stored locally.
  factory WsMessage.ack(List<AckedMessage> messages) {
    return WsMessage._internal(WsMessageType.ack, {
      'messages': messages.map((message) => message.toJson()).toList(),
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'payload': payload,
    };
  }
}
