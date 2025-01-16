import 'dart:convert';
import 'dart:typed_data';
import 'private_message.dart';
import 'ws_response_type.dart';

class WsResponse {
  final WsResponseType type;
  final dynamic payload;

  /// Internal constructor
  WsResponse._internal(this.type, this.payload);

  /// Constructor from Uint8List
  factory WsResponse.fromUint8List(Uint8List data) {
    var json = jsonDecode(utf8.decode(data));
    var type = WsResponseType.values.byName(json['type'] as String);
    dynamic payload;
    switch (type) {
      // Error
      case WsResponseType.error:
        payload = json['payload'] as String;
        break;
      // Message
      case WsResponseType.message:
        payload = PrivateMessage.fromJson(json['payload']);
        break;
    }
    return WsResponse._internal(type, payload);
  }
}
