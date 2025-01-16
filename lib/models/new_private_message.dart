import 'dart:typed_data';

class NewPrivateMessage {
  final int receiverId;
  final Uint8List message;

  NewPrivateMessage.newPrivateMessage(this.receiverId, this.message);

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'receiverId': receiverId,
    };
  }
}
