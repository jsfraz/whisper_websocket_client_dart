import 'message_event.dart';
import 'peer.dart';
import 'private_message.dart';

/// Answer to a sync request: the archive delta above the client's cursor, plus
/// the mutation log and this account's whole-chat cuts.
class Synced {
  final List<PrivateMessage> messages;
  final List<Peer> peers;

  /// Edited, deleted, reacted to and pinned messages the device missed.
  final List<MessageEvent> events;

  /// Whole-chat cuts of this account. A device applies the later instant.
  final List<ConversationCleared> cleared;

  /// The message cursor to send next. It never moves backwards.
  final int syncedThrough;

  /// The event cursor to send next. Zero when the request carried none.
  final int eventsThrough;

  /// True when a page was full; ask again with both cursors.
  final bool hasMore;

  Synced({
    required this.messages,
    required this.peers,
    required this.events,
    required this.cleared,
    required this.syncedThrough,
    required this.eventsThrough,
    required this.hasMore,
  });

  factory Synced.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    final rawPeers = json['peers'];
    if (rawMessages is! List || rawPeers is! List) {
      throw const FormatException('synced payload is not a list pair');
    }
    final rawEvents = json['events'];
    final rawCleared = json['cleared'];
    return Synced(
      messages: rawMessages
          .whereType<Map<String, dynamic>>()
          .map(PrivateMessage.fromJson)
          .toList(),
      peers: rawPeers
          .whereType<Map<String, dynamic>>()
          .map(Peer.fromJson)
          .toList(),
      events: rawEvents is List
          ? rawEvents
              .whereType<Map<String, dynamic>>()
              .map(MessageEvent.fromJson)
              .toList()
          : const [],
      cleared: rawCleared is List
          ? rawCleared
              .whereType<Map<String, dynamic>>()
              .map(ConversationCleared.fromJson)
              .toList()
          : const [],
      syncedThrough: json['syncedThrough'] as int,
      eventsThrough: (json['eventsThrough'] as int?) ?? 0,
      hasMore: json['hasMore'] as bool,
    );
  }
}

/// One whole-chat cut of the calling account.
class ConversationCleared {
  final String peerId;
  final DateTime clearedAt;

  ConversationCleared(this.peerId, this.clearedAt);

  factory ConversationCleared.fromJson(Map<String, dynamic> json) {
    return ConversationCleared(
      json['peerId'] as String,
      DateTime.parse(json['clearedAt'] as String),
    );
  }
}
