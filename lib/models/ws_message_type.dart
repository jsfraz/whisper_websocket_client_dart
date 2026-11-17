/// The type of message to be sent to the WebSocket server
enum WsMessageType {
  message,

  /// Asks for the archive delta above the client's cursor. Replaces the old
  /// full offline-queue drain.
  sync
}
