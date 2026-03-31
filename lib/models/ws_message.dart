import 'new_private_message.dart';
import 'ws_message_type.dart';
import 'send_private_key_payload.dart';
import 'reject_link_payload.dart';
import 'ack_payload.dart';

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

  factory WsMessage.sendPrivateKey(SendPrivateKeyPayload payload) {
    return WsMessage._internal(WsMessageType.sendPrivateKey, payload);
  }

  factory WsMessage.rejectLink(RejectLinkPayload payload) {
    return WsMessage._internal(WsMessageType.rejectLink, payload);
  }

  factory WsMessage.ack(AckPayload payload) {
    return WsMessage._internal(WsMessageType.ack, payload);
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'payload': payload,
    };
  }
}
