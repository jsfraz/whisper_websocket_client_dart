class RejectLinkPayload {
  final String deviceId;

  RejectLinkPayload({required this.deviceId});

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
    };
  }
}
