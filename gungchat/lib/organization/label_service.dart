import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/storage/message_db.dart';

@immutable
class ConversationLabel {
  const ConversationLabel({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String colorHex;
  final DateTime createdAt;

  factory ConversationLabel.fromMap(Map<String, Object?> map) {
    return ConversationLabel(
      id: map['id']! as String,
      name: map['name']! as String,
      colorHex: map['color']! as String,
      createdAt: DateTime.parse(map['created_at']! as String),
    );
  }
}

class LabelService {
  LabelService(this._database, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final MessageDatabase _database;
  final Uuid _uuid;

  Future<ConversationLabel> createLabel(String name, String colorHex) async {
    final normalizedName = name.trim();
    final normalizedColor = colorHex.trim();
    if (normalizedName.isEmpty || normalizedColor.isEmpty) {
      throw ArgumentError('Labels require both a name and a color.');
    }

    final label = ConversationLabel(
      id: _uuid.v4(),
      name: normalizedName,
      colorHex: normalizedColor,
      createdAt: DateTime.now(),
    );
    await _database.saveLabel(
      id: label.id,
      name: label.name,
      color: label.colorHex,
      createdAt: label.createdAt,
    );
    return label;
  }

  Future<List<ConversationLabel>> getAllLabels() async {
    final rows = await _database.listLabels();
    return rows.map(ConversationLabel.fromMap).toList(growable: false);
  }

  Future<List<ConversationLabel>> getLabelsForConversation(String contactId) async {
    final labelIds = await _database.listConversationLabelIds(contactId);
    if (labelIds.isEmpty) {
      return const <ConversationLabel>[];
    }

    final labels = await getAllLabels();
    return labels
        .where((label) => labelIds.contains(label.id))
        .toList(growable: false);
  }

  Future<void> addLabelToConversation(String contactId, String labelId) {
    return _database.assignLabelToConversation(contactId, labelId);
  }

  Future<void> removeLabelFromConversation(String contactId, String labelId) {
    return _database.removeLabelFromConversation(contactId, labelId);
  }

  Future<List<String>> getConversationsByLabel(String labelId) {
    return _database.listConversationIdsForLabel(labelId);
  }
}