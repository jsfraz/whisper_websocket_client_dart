import 'dart:typed_data';

/// A message to be sent to a private chat
class NewPrivateMessage {
  final int receiverId;
  final Uint8List content; // Encrypted content
  final Uint8List key; // Encrypted symmetric key
  final Uint8List nonce; // Unique nonce for encryption
  final Uint8List mac; // Message Authentication Code for integrity
  final DateTime sentAt;

  factory NewPrivateMessage(int receiverId, Uint8List content, Uint8List key,
      Uint8List nonce, Uint8List mac) {
    return NewPrivateMessage._internal(
        receiverId, content, key, nonce, mac, DateTime.now());
  }

  NewPrivateMessage._internal(this.receiverId, this.content, this.key,
      this.nonce, this.mac, this.sentAt);

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'key': key,
      'nonce': nonce,
      'mac': mac,
      'receiverId': receiverId,
      'sentAt': sentAt.toUtc().toIso8601String(),
    };
  }
}
