/// The type of response received from the WebSocket server
enum WsResponseType {
  error,
  messages,
  deleteAccount,

  /// The server accepted an outgoing message into the archive.
  ack,

  /// Answer to a sync request: the archive delta.
  synced,

  /// Mutation log entry: an own message was edited.
  edit,

  /// Mutation log entry: a message was deleted for everyone.
  delete,

  /// Mutation log entry: a participant reacted, replaced or dropped a reaction.
  reaction,

  /// Mutation log entry: a message was pinned or unpinned.
  pin,

  /// The other participant moved their read cursor in this conversation.
  read,

  /// A frame this client version does not know. Ignored on purpose, so a newer
  /// server cannot turn every message it sends into an error.
  unknown,
}

/// Maps the wire name of a frame to a type without throwing on a name this
/// build does not know yet.
WsResponseType wsResponseTypeFromName(String? name) {
  for (final type in WsResponseType.values) {
    if (type != WsResponseType.unknown && type.name == name) {
      return type;
    }
  }
  return WsResponseType.unknown;
}
