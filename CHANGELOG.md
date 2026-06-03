## 1.1.0

- Add media support helpers: `MediaType` and `MediaReference` models. Media files
  are uploaded/downloaded over HTTP via `whisper_openapi_client_dart`; only the
  encrypted `MediaReference` travels inside a private message, keeping the server
  zero-knowledge. Downloads are confirmed by the client
  (`MediaApi.confirmMediaDownload`) so they are retriable, with the server-side
  TTL as a backstop.

## 1.0.0

- Initial version.
