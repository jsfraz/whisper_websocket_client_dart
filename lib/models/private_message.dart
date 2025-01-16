import 'dart:typed_data';

class PrivateMessage {
  final int senderId;
  final Uint8List message;

  PrivateMessage.fromJson(Map<String, dynamic> json)
      : senderId = json['senderId'] as int,
        message = Uint8List.fromList(List<int>.from(json['message']));
}
