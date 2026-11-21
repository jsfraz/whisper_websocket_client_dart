/// The type of message to be sent to the WebSocket server
enum WsMessageType {
  message,

  /// Asks for the archive delta above the client's cursor. Replaces the old
  /// full offline-queue drain.
  sync,

  /// A typing hint for one peer. Relayed, never archived.
  typing,

  /// The caller's own presence. Relayed, never stored.
  presence,

  /// One encrypted position for one peer. Relayed, never stored.
  liveLocation
}
