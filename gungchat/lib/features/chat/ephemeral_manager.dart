import '../../models/message.dart';

class EphemeralManager {
  const EphemeralManager({this.defaultTtl = const Duration(minutes: 10)});

  final Duration defaultTtl;

  DateTime? resolveExpiry({
    required bool burnAfterRead,
    Duration? explicitTtl,
  }) {
    if (!burnAfterRead && explicitTtl == null) {
      return null;
    }
    return DateTime.now().add(explicitTtl ?? defaultTtl);
  }

  bool shouldPurge(Message message, DateTime now) {
    final expiresAt = message.expiresAt;
    return expiresAt != null && expiresAt.isBefore(now);
  }
}
