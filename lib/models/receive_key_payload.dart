import 'dart:typed_data';

class ReceiveKeyPayload {
  final Uint8List encryptedKey;
  final Uint8List nonce;
  final Uint8List mac;

  ReceiveKeyPayload.fromJson(Map<String, dynamic> json)
      : encryptedKey = Uint8List.fromList(List<int>.from(json['encryptedKey'])),
        nonce = Uint8List.fromList(List<int>.from(json['nonce'])),
        mac = Uint8List.fromList(List<int>.from(json['mac']));
}
