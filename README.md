# whisper_websocket_client_dart

A WebSocket client for Whisper messaging server.

## Installation

Add the following dependency to your pubspec.yaml

```yaml
whisper_websocket_client_dart:
    git:
      url: https://github.com/jsfraz/whisper_websocket_client_dart.git
```

## Usage

```dart
import 'package:whisper_websocket_client_dart/ws_client.dart';

var wsClient = WsClient('ws://localhost:8080/ws', onReceived: (wsResponse) {
    // TODO handle server response
});
await wsClient.connect(accessToken, Duration(seconds: 5));

await Future.delayed(Duration(seconds: 5));
wsClient.disconnect();
```

For more detailed example see [test/ws_client_test.dart](test/ws_client_test.dart).

## Dependencies

- [web_socket_channel](https://pub.dev/packages/web_socket_channel)
  - provides WebSocket support for Dart

### Dev dependencies

- [lints](https://pub.dev/packages/lints)
  - lint rules for Dart code analysis
- [test](https://pub.dev/packages/test)
  - testing framework
- [dotenv](https://pub.dev/packages/dotenv)
  - environment variables from .env files
- [pointycastle](https://pub.dev/packages/pointycastle)
  - used for cryptography
- [basic_utils](https://pub.dev/packages/basic_utils)
  - used for cryptography
- [dart_jsonwebtoken](https://pub.dev/packages/dart_jsonwebtoken)
  - used for JWT token handling
- [whisper_openapi_client_dart](https://github.com/jsfraz/whisper_openapi_client_dart)
  - used for API communication with Whisper server

<!-- TODO license -->
