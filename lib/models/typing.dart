/// One "I am typing" hint for a peer. Nothing about it is stored: the server
/// relays it to the peer's live devices and forgets it.
class TypingRequest {
  final String peerId;

  TypingRequest(this.peerId);

  Map<String, dynamic> toJson() => {'peerId': peerId};
}

/// The other participant is typing right now. The indicator expires on its own,
/// so there is no "stopped typing" frame.
class TypingFrame {
  /// Frame version; everything from this release on is version 1.
  final int v;
  final String peerId;

  TypingFrame({required this.v, required this.peerId});

  factory TypingFrame.fromJson(Map<String, dynamic> json) {
    return TypingFrame(
      v: (json['v'] as int?) ?? 1,
      peerId: json['peerId'] as String,
    );
  }
}
