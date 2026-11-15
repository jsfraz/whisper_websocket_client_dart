import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:whisper_websocket_client_dart/models/delivery_ack.dart';
import 'package:whisper_websocket_client_dart/models/ws_response.dart';
import 'package:whisper_websocket_client_dart/models/ws_response_type.dart';

Uint8List bytes(Object json) =>
    Uint8List.fromList(utf8.encode(jsonEncode(json)));

void main() {
  // The delivery ack is what turns "written to the socket" into "accepted by
  // the server"; the payload has to parse into the values the client stored.
  test('a delivery ack carries the receiver and the client timestamp', () {
    final response = WsResponse.fromUint8List(bytes({
      'type': 'ack',
      'payload': {
        'receiverId': '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d11',
        'sentAt': '2026-11-15T20:00:00.123456789Z',
      },
    }));

    expect(response.type, WsResponseType.ack);
    final ack = response.payload as DeliveryAck;
    expect(ack.receiverId, '2f8c1c1e-6c55-4d8f-9d3f-6f6b8a0c2d11');
    expect(ack.sentAt.toUtc(), DateTime.utc(2026, 11, 15, 20, 0, 0, 123, 456));
  });

  test('an unknown response type is reported as an error, not a crash', () {
    final response = WsResponse.fromUint8List(bytes({
      'type': 'somethingNew',
      'payload': null,
    }));
    expect(response.type, WsResponseType.error);
  });
}
