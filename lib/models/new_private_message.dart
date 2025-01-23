import 'dart:typed_data';

/// A message to be sent to a private chat
class NewPrivateMessage {
  final int receiverId;
  final Uint8List message;
  final DateTime sentAt;

  factory NewPrivateMessage(int receiverId, Uint8List message) {
    return NewPrivateMessage._internal(receiverId, message, DateTime.now());
  }

  NewPrivateMessage._internal(this.receiverId, this.message, this.sentAt);

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'receiverId': receiverId,
      'sentAt': sentAt.toUtc().toIso8601String(),
    };
  }
}
