import 'dart:typed_data';

/// One entry of the server's mutation log: an edit, a deletion, a reaction or a
/// pin of an existing message. The ciphertext layout is the same as a message,
/// so an edit or a reaction is opened with exactly the key material a message
/// carries.
class MessageEvent {
  /// Frame version; everything from this release on is version 1.
  final int v;

  /// Position in the mutation log. The client sends the highest value back in a
  /// sync request to receive only what it missed.
  final int eventSeq;

  final String messageId;
  final String peerId;
  final DateTime sentAt;
  final MessageEventKind kind;
  final String actorId;
  final Uint8List? content;
  final Uint8List? key;
  final Uint8List? nonce;
  final Uint8List? mac;

  /// Set on a pin event only: true pins, false unpins.
  final bool? pinned;

  /// Set on an open event only: the instant the receiver opened the attachment.
  final DateTime? openedAt;
  final DateTime createdAt;

  MessageEvent({
    required this.v,
    required this.eventSeq,
    required this.messageId,
    required this.peerId,
    required this.sentAt,
    required this.kind,
    required this.actorId,
    required this.content,
    required this.key,
    required this.nonce,
    required this.mac,
    required this.pinned,
    this.openedAt,
    required this.createdAt,
  });

  factory MessageEvent.fromJson(Map<String, dynamic> json) {
    return MessageEvent(
      v: json['v'] as int,
      eventSeq: json['eventSeq'] as int,
      messageId: json['messageId'] as String,
      peerId: json['peerId'] as String,
      sentAt: DateTime.parse(json['sentAt']),
      kind: MessageEventKind.values.byName(json['kind'] as String),
      actorId: json['actorId'] as String,
      content: _bytes(json['content']),
      key: _bytes(json['key']),
      nonce: _bytes(json['nonce']),
      mac: _bytes(json['mac']),
      pinned: json['pinned'] as bool?,
      openedAt: json['openedAt'] == null
          ? null
          : DateTime.parse(json['openedAt'] as String),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// Kind of a mutation log entry.
enum MessageEventKind { edit, delete, reaction, pin, open }

Uint8List? _bytes(dynamic value) {
  if (value == null) {
    return null;
  }
  return Uint8List.fromList(List<int>.from(value));
}
