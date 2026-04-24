import 'dart:convert';
import 'dart:typed_data';

class VoiceMessagePayload {
  const VoiceMessagePayload({
    required this.bytes,
    required this.durationMs,
    this.mimeType = 'audio/ogg',
  });

  static const String _voiceMarkerKey = '_gc_voice_message';

  final Uint8List bytes;
  final int durationMs;
  final String mimeType;

  String encodeTransportString() {
    return jsonEncode(<String, Object?>{
      _voiceMarkerKey: true,
      'mimeType': mimeType,
      'durationMs': durationMs,
      'data': base64Encode(bytes),
    });
  }

  static VoiceMessagePayload? tryDecodeTransportString(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic> || decoded[_voiceMarkerKey] != true) {
        return null;
      }

      return VoiceMessagePayload(
        bytes: Uint8List.fromList(base64Decode(decoded['data'] as String)),
        durationMs: decoded['durationMs'] as int,
        mimeType: decoded['mimeType'] as String? ?? 'audio/ogg',
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}