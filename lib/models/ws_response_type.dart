/// The type of response received from the WebSocket server
enum WsResponseType {
  error,
  messages,
  deleteAccount,

  /// The server accepted an outgoing message (delivered or queued).
  ack
}
