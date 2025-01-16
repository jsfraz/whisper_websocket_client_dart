import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'models/ws_message.dart';
import 'models/ws_response.dart';

class WsClient {
  /// WebSocket server URL in format 'wss://example.com/ws' or 'ws://example.com/ws'
  /// Use 'wss://' for secure WebSocket connections (recommended)
  /// Use 'ws://' for non-secure WebSocket connections
  final String url;
  WebSocketChannel? channel;
  Function(WsResponse) onReceived;

  WsClient(this.url, this.onReceived);

  /// Connect to the WebSocket server
  void connect(String oneTimeAccessToken) {
    // Connect to the WebSocket server
    channel = WebSocketChannel.connect(
        Uri.parse('$url?wsAccessToken=$oneTimeAccessToken'));

    // Listen for incoming messages
    channel!.stream.listen((data) {
      onReceived(WsResponse.fromUint8List(data));
    });
  }

  /// Check if the WebSocket connection is established
  bool get isConnected {
    return channel != null && channel!.closeCode == null;
  }

  /// Disconnect from the WebSocket server
  void disconnect() {
    channel!.sink.close();
    channel = null;
  }

  /// Send a message to the WebSocket server
  void sendMessage(WsMessage message) {
    channel!.sink.add(utf8.encode(jsonEncode(message)));
  }
}
