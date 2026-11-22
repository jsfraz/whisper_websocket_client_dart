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

  /// Encrypted content. Null on a tombstone: the message was deleted for
  /// everyone and only its slot is left.
  final Uint8List? content;

  /// Encrypted symmetric key.
  final Uint8List? key;

  /// Unique nonce for encryption.
  final Uint8List? nonce;

  /// Message Authentication Code for integrity.
  final Uint8List? mac;
  final DateTime sentAt;

  /// Set when the message was deleted for everyone.
  final DateTime? deletedAt;

  /// Set when the sender edited the message.
  final DateTime? editedAt;

  /// Set when the receiver opened a view-once attachment.
  final DateTime? openedAt;
  final bool recipientOnline;

  PrivateMessage({
    required this.id,
    required this.seq,
    required this.senderId,
    required this.peerId,
    required this.content,
    required this.key,
    required this.nonce,
    required this.mac,
    required this.sentAt,
    required this.deletedAt,
    required this.editedAt,
    this.openedAt,
    required this.recipientOnline,
  });

  PrivateMessage.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        seq = json['seq'] as int,
        senderId = json['senderId'] as String,
        peerId = json['peerId'] as String,
        content = bytesFromJson(json['content']),
        key = bytesFromJson(json['key']),
        nonce = bytesFromJson(json['nonce']),
        mac = bytesFromJson(json['mac']),
        sentAt = DateTime.parse(json['sentAt']),
        deletedAt = instantFromJson(json['deletedAt']),
        editedAt = instantFromJson(json['editedAt']),
        openedAt = instantFromJson(json['openedAt']),
        recipientOnline = json['recipientOnline'] as bool;
}

/// Decodes a nullable byte array of the wire format.
Uint8List? bytesFromJson(dynamic value) {
  if (value == null) {
    return null;
  }
  return Uint8List.fromList(List<int>.from(value));
}

/// Decodes a nullable timestamp of the wire format.
DateTime? instantFromJson(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.parse(value as String);
}
