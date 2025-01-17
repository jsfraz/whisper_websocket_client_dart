# whisper_websocket_client_dart

A WebSocket client for Whisper messaging server.

## Installation

Add the following dependency to your pubspec.yaml
```
whisper_websocket_client_dart:
    git:
      url: https://github.com/jsfraz/whisper_websocket_client_dart.git
```

## Usage

```dart
import 'package:whisper_websocket_client_dart/ws_client.dart';

var wsClient = WsClient('ws://localhost:8080/ws', (wsResponse) {
    // TODO handle server response
});
wsClient.connect(accessToken);

await Future.delayed(Duration(seconds: 5));
wsClient.disconnect();
```

For more detailed example see [test/ws_client_test.dart](test/ws_client_test.dart).

<!-- TODO license -->
