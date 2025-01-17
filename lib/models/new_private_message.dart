import 'dart:typed_data';

/// A message to be sent to a private chat
class NewPrivateMessage {
  final int receiverId;
  final Uint8List message;

  NewPrivateMessage(this.receiverId, this.message);

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'receiverId': receiverId,
    };
  }
}
