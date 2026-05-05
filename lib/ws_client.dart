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

  /// Connect to the WebSocket server
  Future<void> connect(String oneTimeAccessToken, Duration timeout) async {
    try {
      final uri = Uri.parse('$_url?wsAccessToken=$oneTimeAccessToken');
      final socket = await WebSocket.connect(uri.toString()).timeout(timeout);

      _channel = IOWebSocketChannel(socket);

      // Listen for incoming messages
      _channel!.stream.listen((data) {
        if (onReceived != null) {
          onReceived!(WsResponse.fromUint8List(data));
        }
      });
    } catch (e) {
      throw Exception('WebSocket connection timeout or failed: $e');
    }
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
