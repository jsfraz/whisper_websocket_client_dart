import 'dart:typed_data';

import 'media_type.dart';

/// A reference to an encrypted media file stored on the server.
///
/// Media files are uploaded over HTTP (see `MediaApi` in the
/// `whisper_openapi_client_dart` package) and only their *reference* travels
/// inside a private message. This reference (the media id plus the symmetric
/// [key] needed to decrypt the downloaded ciphertext, and the media metadata)
/// is the plaintext that the consumer serializes with [toJson] and then
/// encrypts into [NewPrivateMessage.content]. The server stays zero-knowledge:
/// it never sees the media type, key or any plaintext.
///
/// Recipient flow: decrypt the message content, parse it back into a
/// [MediaReference] with [MediaReference.fromJson], download the ciphertext via
/// `MediaApi.downloadMedia(mediaId)`, then decrypt it locally using [key].
class MediaReference {
  /// Server-side id of the uploaded media file (returned by the upload endpoint).
  final String mediaId;

  /// Symmetric key used to decrypt the downloaded media ciphertext.
  final Uint8List key;

  /// Kind of media (image, gif, video, voice).
  final MediaType type;

  /// Size of the (encrypted) media file in bytes.
  final int size;

  /// Optional pixel width (images, gifs, videos).
  final int? width;

  /// Optional pixel height (images, gifs, videos).
  final int? height;

  /// Optional duration in milliseconds (videos, voice messages).
  final int? durationMs;

  MediaReference(
    this.mediaId,
    this.key,
    this.type,
    this.size, {
    this.width,
    this.height,
    this.durationMs,
  });

  MediaReference.fromJson(Map<String, dynamic> json)
      : mediaId = json['mediaId'] as String,
        key = Uint8List.fromList(List<int>.from(json['key'])),
        type = MediaType.values.byName(json['type'] as String),
        size = json['size'] as int,
        width = json['width'] as int?,
        height = json['height'] as int?,
        durationMs = json['durationMs'] as int?;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'mediaId': mediaId,
      'key': key,
      'type': type.name,
      'size': size,
    };
    if (width != null) {
      json['width'] = width;
    }
    if (height != null) {
      json['height'] = height;
    }
    if (durationMs != null) {
      json['durationMs'] = durationMs;
    }
    return json;
  }
}
