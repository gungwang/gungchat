import 'dart:convert';

class DataChannelTextFramer {
  DataChannelTextFramer({
    this.maxFramePayloadLength = 12000,
    this.reassemblyTtl = const Duration(minutes: 2),
    String Function()? nextMessageId,
    DateTime Function()? now,
  })  : _nextMessageId = nextMessageId ?? _defaultMessageId,
        _now = now ?? DateTime.now;

  static const String _chunkPrefix = '__gc_chunk__:';

  final int maxFramePayloadLength;
  final Duration reassemblyTtl;
  final String Function() _nextMessageId;
  final DateTime Function() _now;
  final Map<String, _PendingFrameBuffer> _pendingBuffers =
      <String, _PendingFrameBuffer>{};

  Iterable<String> frame(String message) sync* {
    if (message.length <= maxFramePayloadLength) {
      yield message;
      return;
    }

    final messageId = _nextMessageId();
    final totalChunks = (message.length / maxFramePayloadLength).ceil();
    for (var index = 0; index < totalChunks; index++) {
      final start = index * maxFramePayloadLength;
      final end = start + maxFramePayloadLength > message.length
          ? message.length
          : start + maxFramePayloadLength;
      final chunkPayload = message.substring(start, end);
      yield _chunkPrefix +
          jsonEncode(<String, Object?>{
            'id': messageId,
            'index': index,
            'total': totalChunks,
            'payload': chunkPayload,
          });
    }
  }

  String? consumeFrame(String frame) {
    _purgeExpiredBuffers();
    if (!frame.startsWith(_chunkPrefix)) {
      return frame;
    }

    final chunk = Map<String, Object?>.from(
      jsonDecode(frame.substring(_chunkPrefix.length)) as Map<String, dynamic>,
    );
    final messageId = chunk['id']! as String;
    final index = chunk['index']! as int;
    final total = chunk['total']! as int;
    final payload = chunk['payload']! as String;
    final buffer = _pendingBuffers.putIfAbsent(
      messageId,
      () => _PendingFrameBuffer(
        createdAt: _now(),
        parts: List<String?>.filled(total, null),
      ),
    );

    if (buffer.parts.length != total || index < 0 || index >= total) {
      _pendingBuffers.remove(messageId);
      throw const FormatException('Malformed chunked data-channel frame.');
    }

    buffer.parts[index] = payload;
    if (buffer.parts.any((part) => part == null)) {
      return null;
    }

    _pendingBuffers.remove(messageId);
    return buffer.parts.join();
  }

  void clear() {
    _pendingBuffers.clear();
  }

  void _purgeExpiredBuffers() {
    final now = _now();
    final expiredIds = _pendingBuffers.entries
        .where(
          (entry) => now.difference(entry.value.createdAt) > reassemblyTtl,
        )
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final messageId in expiredIds) {
      _pendingBuffers.remove(messageId);
    }
  }

  static int _messageSeed = 0;

  static String _defaultMessageId() {
    _messageSeed += 1;
    return 'chunk-${DateTime.now().microsecondsSinceEpoch}-$_messageSeed';
  }
}

class _PendingFrameBuffer {
  _PendingFrameBuffer({
    required this.createdAt,
    required this.parts,
  });

  final DateTime createdAt;
  final List<String?> parts;
}