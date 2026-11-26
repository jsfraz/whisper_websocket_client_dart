/// One position for a peer. [payload] is the ciphertext the sender built for
/// that peer, so the server relays a blob and never sees coordinates.
class LiveLocationRequest {
  final String peerId;
  final String payload;

  LiveLocationRequest(this.peerId, this.payload);

  Map<String, dynamic> toJson() => {'peerId': peerId, 'payload': payload};
}

/// One encrypted position of the other participant.
class LiveLocationFrame {
  /// Frame version; everything from this release on is version 1.
  final int v;
  final String peerId;
  final String payload;

  LiveLocationFrame({
    required this.v,
    required this.peerId,
    required this.payload,
  });

  factory LiveLocationFrame.fromJson(Map<String, dynamic> json) {
    return LiveLocationFrame(
      v: (json['v'] as int?) ?? 1,
      peerId: json['peerId'] as String,
      payload: json['payload'] as String,
    );
  }
}
