import 'package:flutter/foundation.dart';

import '../core/storage/message_db.dart';

@immutable
class ConversationNotificationSettings {
  const ConversationNotificationSettings({
    required this.contactId,
    required this.muted,
    this.snoozedUntil,
  });

  final String contactId;
  final bool muted;
  final DateTime? snoozedUntil;

  bool isSnoozedAt(DateTime now) {
    final until = snoozedUntil;
    return until != null && now.isBefore(until);
  }

  bool shouldNotifyAt(DateTime now) {
    if (muted) {
      return false;
    }

    return !isSnoozedAt(now);
  }
}

class ConversationMuteService {
  ConversationMuteService(
    this._database, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final MessageDatabase _database;
  final DateTime Function() _now;

  Future<void> mute(String contactId) {
    return _database.saveConversationSettings(
      contactId: contactId,
      muted: true,
    );
  }

  Future<void> snoozeUntil(String contactId, DateTime until) {
    return _database.saveConversationSettings(
      contactId: contactId,
      muted: false,
      snoozedUntil: until,
    );
  }

  Future<void> unmute(String contactId) {
    return _database.clearConversationSettings(contactId);
  }

  Future<ConversationNotificationSettings> getSettings(String contactId) async {
    final row = await _database.getConversationSettings(contactId);
    if (row == null) {
      return ConversationNotificationSettings(
        contactId: contactId,
        muted: false,
      );
    }

    return ConversationNotificationSettings(
      contactId: row['contact_id']! as String,
      muted: (row['muted']! as int) == 1,
      snoozedUntil: row['snoozed_until'] == null
          ? null
          : DateTime.parse(row['snoozed_until']! as String),
    );
  }

  Future<bool> shouldNotify(String contactId) async {
    final settings = await getSettings(contactId);
    return settings.shouldNotifyAt(_now());
  }
}