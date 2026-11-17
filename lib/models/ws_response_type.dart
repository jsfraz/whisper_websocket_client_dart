/// The type of response received from the WebSocket server
enum WsResponseType {
  error,
  messages,
  deleteAccount,

  /// The server accepted an outgoing message into the archive.
  ack,

  /// Answer to a sync request: the archive delta.
  synced
}
