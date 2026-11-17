/// An account referenced by a synced batch, so a fresh device can render names
/// and public keys without one request per message.
class Peer {
  final String id;
  final String username;
  final String publicKey;

  Peer(this.id, this.username, this.publicKey);

  factory Peer.fromJson(Map<String, dynamic> json) {
    return Peer(
      json['id'] as String,
      json['username'] as String,
      json['publicKey'] as String,
    );
  }
}
