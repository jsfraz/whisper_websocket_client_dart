import 'dart:convert';
import 'dart:typed_data';
import 'private_message.dart';
import 'ws_response_type.dart';
import 'link_request_payload.dart';
import 'receive_key_payload.dart';

/// A response received from the WebSocket server
class WsResponse {
  final WsResponseType type;
  final dynamic payload;

  /// Internal constructor
  WsResponse._internal(this.type, this.payload);

  /// Constructor from Uint8List
  factory WsResponse.fromUint8List(Uint8List data) {
    var json = jsonDecode(utf8.decode(data));
    WsResponseType type;
    try {
      type = WsResponseType.values.byName(json['type'] as String);
    } on ArgumentError {
      // Return error on unknown type
      return WsResponse._internal(
        WsResponseType.error,
        'unknown response type: ${json['type']} received from server',
      );
    }

    dynamic payload;
    switch (type) {
      // List of messages
      case WsResponseType.messages:
        List<PrivateMessage> messages = (json['payload'] as List)
            .map((msg) => PrivateMessage.fromJson(msg as Map<String, dynamic>))
            .toList();
        payload = messages;
        break;
      // Requests
      case WsResponseType.linkRequest:
        payload = LinkRequestPayload.fromJson(json['payload'] as Map<String, dynamic>);
        break;
      case WsResponseType.receiveKey:
        payload = ReceiveKeyPayload.fromJson(json['payload'] as Map<String, dynamic>);
        break;
      // Empty payloads
      case WsResponseType.linkRejected:
      case WsResponseType.deviceRevoked:
      case WsResponseType.delivered:
      case WsResponseType.deleteAccount:
        payload = null;
        break;
      // Error
      case WsResponseType.error:
        payload = json['payload'] as String;
        break;
    }
    return WsResponse._internal(type, payload);
  }
}
