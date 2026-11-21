/// Announces the caller's own presence to the peers it names. The server relays
/// it and keeps no state, so turning presence off simply stops sending it.
class PresenceRequest {
  final List<String> peerIds;
  final bool online;

  PresenceRequest(this.peerIds, {required this.online});

  Map<String, dynamic> toJson() => {'peerIds': peerIds, 'online': online};
}

/// The other participant is online, or just went away.
class PresenceFrame {
  /// Frame version; everything from this release on is version 1.
  final int v;
  final String peerId;
  final bool online;

  /// Stamped by the server when [online] is false; null otherwise.
  final DateTime? lastSeenAt;

  PresenceFrame({
    required this.v,
    required this.peerId,
    required this.online,
    this.lastSeenAt,
  });

  factory PresenceFrame.fromJson(Map<String, dynamic> json) {
    final lastSeen = json['lastSeenAt'] as String?;
    return PresenceFrame(
      v: (json['v'] as int?) ?? 1,
      peerId: json['peerId'] as String,
      online: (json['online'] as bool?) ?? false,
      lastSeenAt: lastSeen == null ? null : DateTime.parse(lastSeen),
    );
  }
}
