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

## Sending media (images, gifs, videos, voice)

Media files are transferred over HTTP, not over the WebSocket. The file is
encrypted locally and uploaded as ciphertext; only a small encrypted reference
to it travels inside a normal private message, so the server never learns
anything about the media (zero-knowledge). The server stores the file on disk
with a TTL and deletes it after the recipient downloads it once (or when the
TTL expires).

Sender flow:

1. Encrypt the media file locally and upload the ciphertext with
   `MediaApi.uploadMedia(receiverId, file)` from `whisper_openapi_client_dart`,
   which returns the media `id`.
2. Build a `MediaReference(id, key, type, size, ...)` describing the upload
   (including the symmetric `key` needed to decrypt it).
3. Serialize the reference (`mediaReference.toJson()`), encrypt it the same way
   text messages are encrypted, and send it as the `content` of a
   `NewPrivateMessage`.

Recipient flow:

1. Decrypt the received message `content` and parse it with
   `MediaReference.fromJson(...)`.
2. Download the ciphertext via `MediaApi.downloadMedia(mediaReference.mediaId)`.
3. Decrypt it locally using `mediaReference.key`.
4. Only after the file is successfully downloaded, decrypted and persisted, call
   `MediaApi.confirmMediaDownload(mediaReference.mediaId)` to delete it from the
   server. The download is retriable until confirmed; if the client never
   confirms, the file is removed once its server-side TTL expires.

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
