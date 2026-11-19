/// One participant's read cursor in a conversation: the instant up to which
/// they have read it. The server stores nothing else, so a receipt says "read
/// up to here", never which message was opened.
class ReadReceipt {
  /// Frame version; everything from this release on is version 1.
  final int v;

  /// The account the cursor belongs to, as the recipient sees it.
  final String peerId;
  final DateTime readAt;

  ReadReceipt({required this.v, required this.peerId, required this.readAt});

  factory ReadReceipt.fromJson(Map<String, dynamic> json) {
    return ReadReceipt(
      v: (json['v'] as int?) ?? 1,
      peerId: json['peerId'] as String,
      readAt: DateTime.parse(json['readAt'] as String),
    );
  }
}
