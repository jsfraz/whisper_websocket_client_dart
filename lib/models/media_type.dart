/// The kind of media referenced by a private message.
///
/// This value is part of the plaintext [MediaReference] that the consumer
/// encrypts into the message content. The server never sees it (zero-knowledge).
enum MediaType {
  image,
  gif,
  video,
  voice,
}
