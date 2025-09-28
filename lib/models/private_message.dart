import 'dart:typed_data';

/// A message received from a private chat
class PrivateMessage {
  final int senderId;
  final Uint8List content; // Encrypted content
  final Uint8List key; // Encrypted symmetric key
  final Uint8List nonce; // Unique nonce for encryption
  final Uint8List mac; // Message Authentication Code for integrity
  final DateTime sentAt;
  final bool recipientOnline;

  PrivateMessage.fromJson(Map<String, dynamic> json)
      : senderId = json['senderId'] as int,
        content = Uint8List.fromList(List<int>.from(json['content'])),
        key = Uint8List.fromList(List<int>.from(json['key'])),
        nonce = Uint8List.fromList(List<int>.from(json['nonce'])),
        mac = Uint8List.fromList(List<int>.from(json['mac'])),
        sentAt = DateTime.parse(json['sentAt']),
        recipientOnline = json['recipientOnline'] as bool;
}
