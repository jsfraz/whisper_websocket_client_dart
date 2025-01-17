import 'dart:typed_data';

/// A message received from a private chat
class PrivateMessage {
  final int senderId;
  final Uint8List message;
  final DateTime sentAt;

  PrivateMessage.fromJson(Map<String, dynamic> json)
      : senderId = json['senderId'] as int,
        message = Uint8List.fromList(List<int>.from(json['message'])),
        sentAt = DateTime.parse(json['sentAt']);
}
