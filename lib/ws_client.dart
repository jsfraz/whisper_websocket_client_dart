import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'models/ws_message.dart';
import 'models/ws_response.dart';

class WsClient {
  /// WebSocket server URL in format 'wss://example.com/ws' or 'ws://example.com/ws'
  /// Use 'wss://' for secure WebSocket connections (recommended)
  /// Use 'ws://' for non-secure WebSocket connections
  final String _url;
  final Function(WsResponse) _onReceived;
  late WebSocketChannel? _channel;

  WsClient(this._url, this._onReceived);

  /// Connect to the WebSocket server
  void connect(String oneTimeAccessToken) {
    // Connect to the WebSocket server
    _channel = WebSocketChannel.connect(
        Uri.parse('$_url?wsAccessToken=$oneTimeAccessToken'));

    // Listen for incoming messages
    _channel!.stream.listen((data) {
      _onReceived(WsResponse.fromUint8List(data));
    });
  }

  /// Check if the WebSocket connection is established
  bool get isConnected {
    return _channel != null && _channel!.closeCode == null;
  }

  /// Disconnect from the WebSocket server
  void disconnect() {
    _channel!.sink.close();
    _channel = null;
  }

  /// Send a message to the WebSocket server
  void sendMessage(WsMessage message) {
    _channel!.sink.add(utf8.encode(jsonEncode(message)));
  }
}
