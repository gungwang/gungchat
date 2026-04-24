import 'package:flutter/foundation.dart';

import '../core/storage/message_db.dart';

@immutable
class QuickReply {
  const QuickReply({
    required this.shortCode,
    required this.content,
    required this.usageCount,
    required this.createdAt,
  });

  final String shortCode;
  final String content;
  final int usageCount;
  final DateTime createdAt;

  factory QuickReply.fromMap(Map<String, Object?> map) {
    return QuickReply(
      shortCode: map['short_code']! as String,
      content: map['content']! as String,
      usageCount: map['usage_count']! as int,
      createdAt: DateTime.parse(map['created_at']! as String),
    );
  }
}

class QuickReplyService {
  const QuickReplyService(this._database);

  final MessageDatabase _database;

  static String normalizeShortCode(String rawValue) {
    final trimmed = rawValue.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return '';
    }

    return trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
  }

  static bool looksLikeLookup(String input) {
    final trimmed = input.trimLeft();
    if (!trimmed.startsWith('/')) {
      return false;
    }

    return !trimmed.substring(1).contains(RegExp(r'\s'));
  }

  static String lookupPrefix(String input) {
    return normalizeShortCode(input.trimLeft());
  }

  Future<void> createTemplate(String shortCode, String content) async {
    final normalizedShortCode = normalizeShortCode(shortCode);
    final normalizedContent = content.trim();
    if (normalizedShortCode.isEmpty || normalizedContent.isEmpty) {
      throw ArgumentError('Quick reply shortcode and content must be present.');
    }

    await _database.saveQuickReply(
      shortCode: normalizedShortCode,
      content: normalizedContent,
    );
  }

  Future<List<QuickReply>> search(String prefix) async {
    final normalizedPrefix = normalizeShortCode(prefix);
    if (normalizedPrefix.isEmpty) {
      return const <QuickReply>[];
    }

    final rows = await _database.searchQuickReplies(normalizedPrefix);
    return rows.map(QuickReply.fromMap).toList(growable: false);
  }

  Future<String?> useTemplate(String shortCode) async {
    final normalizedShortCode = normalizeShortCode(shortCode);
    if (normalizedShortCode.isEmpty) {
      return null;
    }

    final rows = await _database.searchQuickReplies(normalizedShortCode, limit: 20);
    final matches = rows
        .map(QuickReply.fromMap)
        .where((template) => template.shortCode == normalizedShortCode)
        .toList(growable: false);
    if (matches.isEmpty) {
      return null;
    }

    await _database.incrementQuickReplyUsage(normalizedShortCode);
    return matches.first.content;
  }

  Future<void> deleteTemplate(String shortCode) async {
    final normalizedShortCode = normalizeShortCode(shortCode);
    if (normalizedShortCode.isEmpty) {
      return;
    }

    await _database.deleteQuickReply(normalizedShortCode);
  }

  Future<List<QuickReply>> getAllTemplates() async {
    final rows = await _database.listQuickReplies();
    return rows.map(QuickReply.fromMap).toList(growable: false);
  }
}