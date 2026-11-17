/// Asks the server for every archived message above [sinceSeq]. A new device
/// starts at zero and walks the history in pages.
class WsSync {
  final int sinceSeq;

  WsSync(this.sinceSeq);

  Map<String, dynamic> toJson() => {'sinceSeq': sinceSeq};
}
