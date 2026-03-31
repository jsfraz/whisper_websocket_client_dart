import 'dart:typed_data';

class SendPrivateKeyPayload {
  final String deviceId;
  final Uint8List encryptedKey;
  final Uint8List nonce;
  final Uint8List mac;

  SendPrivateKeyPayload({
    required this.deviceId,
    required this.encryptedKey,
    required this.nonce,
    required this.mac,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'encryptedKey': encryptedKey.toList(),
      'nonce': nonce.toList(),
      'mac': mac.toList(),
    };
  }
}
