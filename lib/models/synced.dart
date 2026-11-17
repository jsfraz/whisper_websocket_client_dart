import 'peer.dart';
import 'private_message.dart';

/// Answer to a sync request: the archive delta above the client's cursor.
class Synced {
  final List<PrivateMessage> messages;
  final List<Peer> peers;

  /// The cursor to send next. It never moves backwards.
  final int syncedThrough;

  /// True when the page was full; ask again with [syncedThrough].
  final bool hasMore;

  Synced(this.messages, this.peers, this.syncedThrough, this.hasMore);

  factory Synced.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    final rawPeers = json['peers'];
    if (rawMessages is! List || rawPeers is! List) {
      throw const FormatException('synced payload is not a list pair');
    }
    return Synced(
      rawMessages
          .whereType<Map<String, dynamic>>()
          .map(PrivateMessage.fromJson)
          .toList(),
      rawPeers.whereType<Map<String, dynamic>>().map(Peer.fromJson).toList(),
      json['syncedThrough'] as int,
      json['hasMore'] as bool,
    );
  }
}
