import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
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

  /// Connect to the WebSocket server
  void connect(String oneTimeAccessToken) {
    // Connect to the WebSocket server
    _channel = WebSocketChannel.connect(
        Uri.parse('$_url?wsAccessToken=$oneTimeAccessToken'));

    // Listen for incoming messages
    _channel!.stream.listen((data) {
      if (onReceived != null) {
        onReceived!(WsResponse.fromUint8List(data));
      }
    });
  }

  /// Check if the WebSocket connection is established
  bool get isConnected {
    return _channel != null && _channel!.closeCode == null;
  }

  /// Disconnect from the WebSocket server
  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    } else {
      throw Exception('WebSocket connection not established');
    }
  }

  /// Send a message to the WebSocket server
  DateTime sendMessage(WsMessage message) {
    if (_channel != null) {
      _channel!.sink.add(utf8.encode(jsonEncode(message)));
      return DateTime.now();
    } else {
      throw Exception('WebSocket connection not established');
    }
  }
}
