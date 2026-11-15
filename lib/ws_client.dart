import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'models/ws_message.dart';
import 'models/ws_response.dart';

class WsClient {
  /// WebSocket server URL in format 'wss://example.com/ws' or 'ws://example.com/ws'
  /// Use 'wss://' for secure WebSocket connections (recommended)
  /// Use 'ws://' for non-secure WebSocket connections
  final String _url;
  final Function(WsResponse)? onReceived;
  WebSocketChannel? _channel;

  WsClient(this._url, {this.onReceived});

  /// Connect to the WebSocket server.
  ///
  /// The one-time token travels in the Authorization header, not in the query
  /// string: URLs end up in proxy access logs, headers do not.
  Future<void> connect(String oneTimeAccessToken, Duration timeout) async {
    try {
      final socket = await WebSocket.connect(
        _url,
        headers: {'Authorization': 'Bearer $oneTimeAccessToken'},
      ).timeout(timeout);

      final channel = IOWebSocketChannel(socket);
      _channel = channel;

      // A closed or broken channel must clear itself: `isConnected` reads
      // _channel, and a stale reference would keep the app "online" forever.
      channel.stream.listen(
        (data) {
          final handler = onReceived;
          if (handler == null) {
            return;
          }
          // A malformed frame must not kill the subscription.
          try {
            handler(WsResponse.fromUint8List(data));
          } catch (_) {
            // Ignored: the next frame is still delivered.
          }
        },
        onDone: () => _clear(channel),
        onError: (Object _) => _clear(channel),
        cancelOnError: true,
      );
    } catch (e) {
      throw Exception('WebSocket connection timeout or failed: $e');
    }
  }

  /// Forgets [channel] unless a newer connection replaced it.
  void _clear(WebSocketChannel channel) {
    if (identical(_channel, channel)) {
      _channel = null;
    }
  }

  /// Check if the WebSocket connection is established
  bool get isConnected {
    return _channel != null && _channel!.closeCode == null;
  }

  /// Disconnect from the WebSocket server. Safe to call when not connected.
  void disconnect() {
    final channel = _channel;
    _channel = null;
    channel?.sink.close();
  }

  /// Send a message to the WebSocket server.
  ///
  /// Delivery is confirmed by the server (see [WsResponseType.ack]); writing to
  /// the sink proves nothing, so there is no return value to misinterpret.
  void sendMessage(WsMessage message) {
    final channel = _channel;
    if (channel == null) {
      throw Exception('WebSocket connection not established');
    }
    channel.sink.add(utf8.encode(jsonEncode(message)));
  }
}
