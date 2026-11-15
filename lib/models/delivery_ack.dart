/// Confirmation that the server accepted an outgoing message: it was either
/// handed to the receiver's connection or stored in the receiver's offline
/// queue. It is the only proof of a successful send, so the client keeps the
/// message pending until it arrives.
class DeliveryAck {
  /// The recipient the acknowledged message was addressed to.
  final String receiverId;

  /// The client timestamp the message was sent with; together with the
  /// recipient it identifies the stored message.
  final DateTime sentAt;

  DeliveryAck(this.receiverId, this.sentAt);

  factory DeliveryAck.fromJson(Map<String, dynamic> json) {
    return DeliveryAck(
      json['receiverId'] as String,
      DateTime.parse(json['sentAt'] as String),
    );
  }
}

/// One received message the client confirms it has stored.
class AckedMessage {
  final String senderId;
  final DateTime sentAt;

  AckedMessage(this.senderId, this.sentAt);

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'sentAt': sentAt.toUtc().toIso8601String(),
      };
}
