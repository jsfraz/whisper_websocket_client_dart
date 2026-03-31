/// The type of response received from the WebSocket server
enum WsResponseType {
  error,
  messages,
  deleteAccount,
  linkRequest,
  receiveKey,
  linkRejected,
  deviceRevoked,
  delivered
}
