import 'dart:convert';
import 'dart:typed_data';
import 'delivery_ack.dart';
import 'message_event.dart';
import 'private_message.dart';
import 'read_receipt.dart';
import 'synced.dart';
import 'ws_response_type.dart';

/// A response received from the WebSocket server
class WsResponse {
  final WsResponseType type;
  final dynamic payload;

  /// Internal constructor
  WsResponse._internal(this.type, this.payload);

  /// Constructor from Uint8List. Never throws: anything the server sends that
  /// this version does not understand becomes an error response, because a
  /// throwing parser would kill the message subscription. A frame type this
  /// build has never heard of is [WsResponseType.unknown] instead, so a newer
  /// server stays compatible with an older client.
  factory WsResponse.fromUint8List(Uint8List data) {
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(data));
    } catch (_) {
      return WsResponse._internal(
        WsResponseType.error,
        'unreadable frame received from server',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      return WsResponse._internal(
        WsResponseType.error,
        'unexpected frame shape received from server',
      );
    }
    final json = decoded;

    final type = wsResponseTypeFromName(json['type'] as String?);

    try {
      dynamic payload;
      switch (type) {
        // List of messages
        case WsResponseType.messages:
          final rawMessages = json['payload'];
          if (rawMessages is! List) {
            throw const FormatException('messages payload is not a list');
          }
          payload = rawMessages
              .whereType<Map<String, dynamic>>()
              .map(PrivateMessage.fromJson)
              .toList();
          break;
        // Delivery acknowledgement of an outgoing message
        case WsResponseType.ack:
          final rawAck = json['payload'];
          if (rawAck is! Map<String, dynamic>) {
            throw const FormatException('ack payload is not an object');
          }
          payload = DeliveryAck.fromJson(rawAck);
          break;
        // Archive delta after a sync request
        case WsResponseType.synced:
          final rawSynced = json['payload'];
          if (rawSynced is! Map<String, dynamic>) {
            throw const FormatException('synced payload is not an object');
          }
          payload = Synced.fromJson(rawSynced);
          break;
        // One live mutation of an archived message
        case WsResponseType.edit:
        case WsResponseType.delete:
        case WsResponseType.reaction:
        case WsResponseType.pin:
          final rawEvent = json['payload'];
          if (rawEvent is! Map<String, dynamic>) {
            throw const FormatException('event payload is not an object');
          }
          payload = MessageEvent.fromJson(rawEvent);
          break;
        // The other participant moved their read cursor
        case WsResponseType.read:
          final rawReceipt = json['payload'];
          if (rawReceipt is! Map<String, dynamic>) {
            throw const FormatException('read payload is not an object');
          }
          payload = ReadReceipt.fromJson(rawReceipt);
          break;
        // Delete account
        case WsResponseType.deleteAccount:
        case WsResponseType.unknown:
          payload = null;
          break;
        // Error
        case WsResponseType.error:
          payload = json['payload'] as String;
          break;
      }
      return WsResponse._internal(type, payload);
    } catch (e) {
      return WsResponse._internal(
        WsResponseType.error,
        'malformed ${type.name} payload received from server: $e',
      );
    }
  }
}
