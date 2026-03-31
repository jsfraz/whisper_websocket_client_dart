class LinkRequestPayload {
  final String sessionToken;
  final String deviceId;
  final String deviceName;
  final String platform;

  LinkRequestPayload.fromJson(Map<String, dynamic> json)
      : sessionToken = json['sessionToken'] as String,
        deviceId = json['deviceId'] as String,
        deviceName = json['deviceName'] as String,
        platform = json['platform'] as String;
}
