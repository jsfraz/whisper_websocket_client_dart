import 'dart:typed_data';

/// A message received from a private chat, or read back from the archive during
/// a delta sync.
class PrivateMessage {
  /// Server-side message id; stable across a resend.
  final String id;

  /// Monotonic position in the archive. The client sends the highest stored
  /// value back in a sync request to receive only what it missed.
  final int seq;

  final String senderId;

  /// The other participant of the conversation, as seen by this client.
  final String peerId;

  final Uint8List content; // Encrypted content
  final Uint8List key; // Encrypted symmetric key
  final Uint8List nonce; // Unique nonce for encryption
  final Uint8List mac; // Message Authentication Code for integrity
  final DateTime sentAt;
  final bool recipientOnline;

  PrivateMessage.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        seq = json['seq'] as int,
        senderId = json['senderId'] as String,
        peerId = json['peerId'] as String,
        content = Uint8List.fromList(List<int>.from(json['content'])),
        key = Uint8List.fromList(List<int>.from(json['key'])),
        nonce = Uint8List.fromList(List<int>.from(json['nonce'])),
        mac = Uint8List.fromList(List<int>.from(json['mac'])),
        sentAt = DateTime.parse(json['sentAt']),
        recipientOnline = json['recipientOnline'] as bool;
}
