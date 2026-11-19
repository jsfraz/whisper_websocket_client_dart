/// Asks the server for every archived message above [sinceSeq]. A new device
/// starts at zero and walks the history in pages.
///
/// [sinceEventSeq] asks for the mutation log in the same answer: edits,
/// deletions, reactions and pins of messages the device already holds. A client
/// that omits it gets no events, which is what an older build does.
class WsSync {
  final int sinceSeq;
  final int? sinceEventSeq;

  WsSync(this.sinceSeq, {this.sinceEventSeq});

  Map<String, dynamic> toJson() => {
        'sinceSeq': sinceSeq,
        if (sinceEventSeq != null) 'sinceEventSeq': sinceEventSeq,
      };
}
