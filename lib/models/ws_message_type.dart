/// The type of message to be sent to the WebSocket server
enum WsMessageType {
  message,

  /// Confirms the client stored received messages, so the server may drop them
  /// from the offline queue.
  ack
}
