import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordedVoiceClip {
  const RecordedVoiceClip({
    required this.filePath,
    required this.durationMs,
    required this.mimeType,
  });

  final String filePath;
  final int durationMs;
  final String mimeType;
}

class VoiceMessageService extends ChangeNotifier {
  VoiceMessageService({
    AudioRecorder? recorder,
    AudioPlayer? player,
  })  : _recorder = recorder ?? AudioRecorder(),
        _player = player ?? AudioPlayer() {
    _playerCompleteSubscription = _player.onPlayerComplete.listen((_) {
      _playingMessageId = null;
      notifyListeners();
    });
  }

  static const int maxDurationSeconds = 120;
  static const String defaultMimeType = 'audio/ogg';

  final AudioRecorder _recorder;
  final AudioPlayer _player;

  StreamSubscription<void>? _playerCompleteSubscription;
  DateTime? _recordingStartedAt;
  String? _recordingPath;
  String? _playingMessageId;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  String? get playingMessageId => _playingMessageId;

  Future<bool> startRecording() async {
    if (_isRecording) {
      return true;
    }
    if (!await _recorder.hasPermission()) {
      return false;
    }

    final outputPath = await _nextClipPath(prefix: 'recording');
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.opus,
        bitRate: 32000,
        sampleRate: 16000,
      ),
      path: outputPath,
    );
    _recordingStartedAt = DateTime.now();
    _recordingPath = outputPath;
    _isRecording = true;
    notifyListeners();
    return true;
  }

  Future<RecordedVoiceClip?> stopRecording() async {
    if (!_isRecording) {
      return null;
    }

    final startedAt = _recordingStartedAt;
    final outputPath = await _recorder.stop() ?? _recordingPath;
    _recordingStartedAt = null;
    _recordingPath = null;
    _isRecording = false;
    notifyListeners();

    if (outputPath == null || startedAt == null) {
      return null;
    }

    final durationMs =
        DateTime.now().difference(startedAt).inMilliseconds.clamp(1000, 120000);
    return RecordedVoiceClip(
      filePath: outputPath,
      durationMs: durationMs,
      mimeType: defaultMimeType,
    );
  }

  Future<void> cancelRecording() async {
    if (!_isRecording) {
      return;
    }

    final outputPath = _recordingPath;
    await _recorder.cancel();
    _recordingStartedAt = null;
    _recordingPath = null;
    _isRecording = false;
    notifyListeners();
    if (outputPath != null) {
      final file = File(outputPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> togglePlayback({
    required String messageId,
    required String filePath,
  }) async {
    if (_playingMessageId == messageId) {
      await stopPlayback();
      return;
    }

    await _player.stop();
    _playingMessageId = messageId;
    notifyListeners();
    await _player.play(DeviceFileSource(filePath));
  }

  Future<void> stopPlayback() async {
    await _player.stop();
    _playingMessageId = null;
    notifyListeners();
  }

  Future<Uint8List> loadClipBytes(String filePath) async {
    return File(filePath).readAsBytes();
  }

  Future<String> saveInboundClipBytes({
    required Uint8List bytes,
    required String messageId,
    String extension = '.ogg',
  }) async {
    final clipPath = await _nextClipPath(
      prefix: 'voice-$messageId',
      extension: extension,
    );
    final file = File(clipPath);
    await file.writeAsBytes(bytes, flush: true);
    return clipPath;
  }

  @override
  void dispose() {
    unawaited(_playerCompleteSubscription?.cancel());
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<String> _nextClipPath({
    required String prefix,
    String extension = '.ogg',
  }) async {
    final directory = await getApplicationSupportDirectory();
    final clipsDirectory = Directory(
      path.join(directory.path, 'voice_messages'),
    );
    if (!await clipsDirectory.exists()) {
      await clipsDirectory.create(recursive: true);
    }

    return path.join(
      clipsDirectory.path,
      '$prefix-${DateTime.now().microsecondsSinceEpoch}$extension',
    );
  }
}