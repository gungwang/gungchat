import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/features/chat/voice_message_service.dart';
import 'package:record/record.dart';

void main() {
  group('VoiceMessageService.selectRecordingProfile', () {
    test('prefers AAC-LC when available', () {
      final profile = VoiceMessageService.selectRecordingProfile(
        aacLcSupported: true,
        wavSupported: true,
      );

      expect(profile.config.encoder, AudioEncoder.aacLc);
      expect(profile.extension, '.m4a');
      expect(profile.mimeType, VoiceMessageService.defaultMimeType);
    });

    test('falls back to WAV when AAC-LC is unavailable', () {
      final profile = VoiceMessageService.selectRecordingProfile(
        aacLcSupported: false,
        wavSupported: true,
      );

      expect(profile.config.encoder, AudioEncoder.wav);
      expect(profile.extension, '.wav');
      expect(profile.mimeType, 'audio/wav');
    });

    test('throws when no supported voice encoder is available', () {
      expect(
        () => VoiceMessageService.selectRecordingProfile(
          aacLcSupported: false,
          wavSupported: false,
        ),
        throwsStateError,
      );
    });
  });

  group('VoiceMessageService.extensionForMimeType', () {
    test('maps known voice mime types to stable file extensions', () {
      expect(VoiceMessageService.extensionForMimeType('audio/mp4'), '.m4a');
      expect(VoiceMessageService.extensionForMimeType('audio/x-m4a'), '.m4a');
      expect(VoiceMessageService.extensionForMimeType('audio/wav'), '.wav');
      expect(
        VoiceMessageService.extensionForMimeType('audio/ogg; codecs=opus'),
        '.ogg',
      );
      expect(VoiceMessageService.extensionForMimeType('audio/aac'), '.aac');
      expect(
        VoiceMessageService.extensionForMimeType('application/octet-stream'),
        '.audio',
      );
    });
  });
}