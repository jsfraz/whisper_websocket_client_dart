# whisper_websocket_client_dart — agent contract

Dart WebSocket client for Whisper (`dart:io`, no web target). Used by `whisper`.

## Commands

- deps: `dart pub get`
- analyze: `dart analyze`
- format: `dart format` on the files you touched
- test: `dart test` — **careful**: `test/ws_client_test.dart` is a live integration test against a running server and `.env.dev`; it does not run in CI

## Hard rules

1. Never commit `privateKey.pem`, `publicKey.pem`, `.env*` or any other key. Keys are generated locally (`generateKeys.sh`).
2. Do not change the auth flow (RSA JWT → `/api/auth`, WS token via `/api/wsauth`) without a matching server change and an update to the server's `AGENTS.md`.
3. Stay on `dart:io` — the library has no web target; adding `web_socket_channel` would break app compatibility.
4. Do not depend on `whisper_openapi_client_dart` through an unpinned git URL; a new dependency must be pinned (tag) or a local `path` in the monorepo.
5. Do not delete the live integration test or move it into CI; if you change it, keep it runnable against a local server.
6. Force-push only to your own feature branch, never to `main`.

## Definition of done

- `dart analyze` reports no findings.
- Formatting is clean on the files you touched.
- A protocol change ships the matching change in `whisper-server` and in the app.
