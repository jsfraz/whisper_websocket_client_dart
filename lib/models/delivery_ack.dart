/// Confirmation that the server accepted an outgoing message and stored it in
/// the archive. It is the only proof of a successful send, so the client keeps
/// the message pending until it arrives.
class DeliveryAck {
  /// Server-side message id.
  final String id;

  /// Archive position of the stored message.
  final int seq;

  /// The recipient the acknowledged message was addressed to.
  final String receiverId;

  /// The client timestamp the message was sent with.
  final DateTime sentAt;

  DeliveryAck(this.id, this.seq, this.receiverId, this.sentAt);

  factory DeliveryAck.fromJson(Map<String, dynamic> json) {
    return DeliveryAck(
      json['id'] as String,
      json['seq'] as int,
      json['receiverId'] as String,
      DateTime.parse(json['sentAt'] as String),
    );
  }
}
