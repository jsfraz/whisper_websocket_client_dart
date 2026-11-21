import 'dart:typed_data';

/// A message to be sent to a private chat
class NewPrivateMessage {
  final String receiverId;
  final Uint8List content; // Encrypted content
  final Uint8List key; // Encrypted symmetric key
  final Uint8List nonce; // Unique nonce for encryption
  final Uint8List mac; // Message Authentication Code for integrity
  final DateTime sentAt;

  /// Disappearing message: the sender asks for a life shorter than the account
  /// retention. Null keeps the retention alone.
  final int? ttlSeconds;

  factory NewPrivateMessage(String receiverId, Uint8List content, Uint8List key,
      Uint8List nonce, Uint8List mac,
      {DateTime? sentAt, int? ttlSeconds}) {
    return NewPrivateMessage._internal(receiverId, content, key, nonce, mac,
        sentAt ?? DateTime.now(), ttlSeconds);
  }

  NewPrivateMessage._internal(this.receiverId, this.content, this.key,
      this.nonce, this.mac, this.sentAt, this.ttlSeconds);

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'key': key,
      'nonce': nonce,
      'mac': mac,
      'receiverId': receiverId,
      'sentAt': sentAt.toUtc().toIso8601String(),
      if (ttlSeconds != null) 'ttlSeconds': ttlSeconds,
    };
  }
}
