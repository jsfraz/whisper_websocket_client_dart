class AckPayload {
  final String messageKey;

  AckPayload({required this.messageKey});

  Map<String, dynamic> toJson() {
    return {
      'messageKey': messageKey,
    };
  }
}
