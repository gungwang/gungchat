import 'dart:io' show Platform;

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

import '../../models/message.dart';

class MessageDatabase {
  MessageDatabase({
    Future<String> Function()? loadDatabasePath,
    DatabaseFactory? databaseFactory,
  })  : _loadDatabasePath = loadDatabasePath ?? _defaultDatabasePath,
      _databaseFactory = databaseFactory;

  Database? _database;
  final Future<String> Function() _loadDatabasePath;
    final DatabaseFactory? _databaseFactory;

  Future<void> open() async {
    if (_database != null) {
      return;
    }

    final databasePath = await _loadDatabasePath();

    _database = await (_databaseFactory ?? _defaultDatabaseFactory()).openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 7,
        onCreate: (database, version) async {
          await database.execute('''
          CREATE TABLE messages(
            id TEXT PRIMARY KEY,
            conversation_id TEXT NOT NULL,
            sender_id TEXT NOT NULL,
            body TEXT NOT NULL,
            type TEXT NOT NULL,
            delivery_state TEXT NOT NULL,
            created_at TEXT NOT NULL,
            is_outgoing INTEGER NOT NULL,
            burn_after_read INTEGER NOT NULL,
            expires_at TEXT,
            reply_to_message_id TEXT,
            reply_to_body TEXT,
            reactions_json TEXT,
            edited_at TEXT,
            deleted_at TEXT,
            delete_mode TEXT,
            audio_file_path TEXT,
            audio_duration_ms INTEGER,
            attachments_json TEXT
          )
          ''');
          await database.execute('''
          CREATE TABLE starred_messages(
            message_id TEXT PRIMARY KEY,
            starred_at TEXT NOT NULL
          )
        ''');
          await _createOrganizationTables(database);
        },
        onUpgrade: (database, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await database.execute(
            'ALTER TABLE messages ADD COLUMN reply_to_message_id TEXT',
            );
            await database.execute(
            'ALTER TABLE messages ADD COLUMN reply_to_body TEXT',
            );
          }
          if (oldVersion < 3) {
            await database.execute(
            'ALTER TABLE messages ADD COLUMN reactions_json TEXT',
            );
          }
          if (oldVersion < 4) {
            await database.execute('''
            CREATE TABLE starred_messages(
              message_id TEXT PRIMARY KEY,
              starred_at TEXT NOT NULL
            )
          ''');
          }
          if (oldVersion < 5) {
            await database.execute(
            'ALTER TABLE messages ADD COLUMN edited_at TEXT',
            );
            await database.execute(
            'ALTER TABLE messages ADD COLUMN deleted_at TEXT',
            );
            await database.execute(
            'ALTER TABLE messages ADD COLUMN delete_mode TEXT',
            );
          }
          if (oldVersion < 6) {
            await database.execute(
            'ALTER TABLE messages ADD COLUMN audio_file_path TEXT',
            );
            await database.execute(
            'ALTER TABLE messages ADD COLUMN audio_duration_ms INTEGER',
            );
          }
          if (oldVersion < 7) {
            await database.execute(
            'ALTER TABLE messages ADD COLUMN attachments_json TEXT',
            );
            await _createOrganizationTables(database);
          }
        },
      ),
    );
  }

  static DatabaseFactory _defaultDatabaseFactory() {
    if (Platform.isWindows) {
      sqflite_ffi.sqfliteFfiInit();
      return sqflite_ffi.databaseFactoryFfi;
    }

    return databaseFactory;
  }

  static Future<String> _defaultDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return path.join(documentsDirectory.path, 'gungchat.db');
  }

  Future<void> _createOrganizationTables(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS quick_replies(
        short_code TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        usage_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS labels(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS conversation_labels(
        contact_id TEXT NOT NULL,
        label_id TEXT NOT NULL,
        PRIMARY KEY(contact_id, label_id)
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS contact_notes(
        id TEXT PRIMARY KEY,
        contact_id TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS conversation_settings(
        contact_id TEXT PRIMARY KEY,
        muted INTEGER NOT NULL DEFAULT 0,
        snoozed_until TEXT
      )
    ''');
  }

  Future<void> upsertMessage(Message message) async {
    await _requireDatabase().insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Message?> getMessage(String messageId) async {
    final rows = await _requireDatabase().rawQuery(
      '''
      SELECT
        m.*,
        CASE WHEN s.message_id IS NULL THEN 0 ELSE 1 END AS is_starred
      FROM messages m
      LEFT JOIN starred_messages s ON s.message_id = m.id
      WHERE m.id = ?
      LIMIT 1
      ''',
      [messageId],
    );

    if (rows.isEmpty) {
      return null;
    }

    return Message.fromMap(rows.first);
  }

  Future<void> updateDeliveryState(
    String messageId,
    MessageDeliveryState deliveryState,
  ) async {
    await _requireDatabase().update(
      'messages',
      <String, Object?>{
        'delivery_state': deliveryState.name,
      },
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> updateReactions(
    String messageId,
    Map<String, List<String>> reactions,
  ) async {
    await _requireDatabase().update(
      'messages',
      <String, Object?>{
        'reactions_json': Message.encodeReactions(reactions),
      },
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> toggleStar(String messageId) async {
    final database = _requireDatabase();
    final existing = await database.query(
      'starred_messages',
      columns: const ['message_id'],
      where: 'message_id = ?',
      whereArgs: [messageId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await database.delete(
        'starred_messages',
        where: 'message_id = ?',
        whereArgs: [messageId],
      );
      return;
    }

    await database.insert(
      'starred_messages',
      <String, Object?>{
        'message_id': messageId,
        'starred_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMessageContent({
    required String messageId,
    required String body,
    required DateTime editedAt,
  }) async {
    await _requireDatabase().update(
      'messages',
      <String, Object?>{
        'body': body,
        'type': MessageType.text.name,
        'edited_at': editedAt.toIso8601String(),
        'deleted_at': null,
        'delete_mode': null,
        'audio_file_path': null,
        'audio_duration_ms': null,
        'attachments_json': null,
      },
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> markMessageDeleted({
    required String messageId,
    required DateTime deletedAt,
    required MessageDeleteMode mode,
  }) async {
    if (mode == MessageDeleteMode.hardDelete) {
      await deleteMessage(messageId);
      return;
    }

    await _requireDatabase().update(
      'messages',
      <String, Object?>{
        'body': '',
        'reply_to_message_id': null,
        'reply_to_body': null,
        'reactions_json': null,
        'edited_at': null,
        'deleted_at': deletedAt.toIso8601String(),
        'delete_mode': mode.name,
        'audio_file_path': null,
        'audio_duration_ms': null,
        'attachments_json': null,
      },
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> deleteMessage(String messageId) async {
    final database = _requireDatabase();
    await database.delete(
      'starred_messages',
      where: 'message_id = ?',
      whereArgs: [messageId],
    );
    await database.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<List<String>> listAudioFilePaths({String? conversationId}) async {
    final database = _requireDatabase();
    final rows = await database.query(
      'messages',
      columns: const ['audio_file_path'],
      where: conversationId == null
          ? 'audio_file_path IS NOT NULL AND TRIM(audio_file_path) <> ?'
          : 'conversation_id = ? AND audio_file_path IS NOT NULL AND TRIM(audio_file_path) <> ?',
      whereArgs: conversationId == null ? [''] : [conversationId, ''],
    );

    return rows
        .map((row) => row['audio_file_path'] as String?)
        .whereType<String>()
        .toList(growable: false);
  }

  Future<List<String>> listStoredFilePaths({String? conversationId}) async {
    final rows = await _requireDatabase().query(
      'messages',
      columns: const ['audio_file_path', 'attachments_json'],
      where: conversationId == null ? null : 'conversation_id = ?',
      whereArgs: conversationId == null ? null : [conversationId],
    );

    final filePaths = <String>[];
    for (final row in rows) {
      final audioPath = row['audio_file_path'] as String?;
      if (audioPath != null && audioPath.trim().isNotEmpty) {
        filePaths.add(audioPath);
      }

      final attachments = Message.decodeAttachments(row['attachments_json']);
      for (final attachment in attachments) {
        if (attachment.hasFilePath) {
          filePaths.add(attachment.filePath!);
        }
      }
    }

    return List<String>.unmodifiable(filePaths);
  }

  Future<void> deleteConversation(String conversationId) async {
    final database = _requireDatabase();
    await database.rawDelete(
      '''
      DELETE FROM starred_messages
      WHERE message_id IN (
        SELECT id FROM messages WHERE conversation_id = ?
      )
      ''',
      [conversationId],
    );
    await database.delete(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<void> clearAllData() async {
    final database = _requireDatabase();
    await database.delete('starred_messages');
    await database.delete('messages');
    await database.delete('quick_replies');
    await database.delete('labels');
    await database.delete('conversation_labels');
    await database.delete('contact_notes');
    await database.delete('conversation_settings');
  }

  Future<void> saveQuickReply({
    required String shortCode,
    required String content,
    int usageCount = 0,
    DateTime? createdAt,
  }) async {
    await _requireDatabase().insert(
      'quick_replies',
      <String, Object?>{
        'short_code': shortCode,
        'content': content,
        'usage_count': usageCount,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> listQuickReplies() async {
    final rows = await _requireDatabase().query(
      'quick_replies',
      orderBy: 'usage_count DESC, short_code ASC',
    );
    return rows.map((row) => Map<String, Object?>.from(row)).toList(growable: false);
  }

  Future<List<Map<String, Object?>>> searchQuickReplies(
    String prefix, {
    int limit = 10,
  }) async {
    final rows = await _requireDatabase().query(
      'quick_replies',
      where: 'short_code LIKE ?',
      whereArgs: ['$prefix%'],
      orderBy: 'usage_count DESC, short_code ASC',
      limit: limit,
    );
    return rows.map((row) => Map<String, Object?>.from(row)).toList(growable: false);
  }

  Future<void> incrementQuickReplyUsage(String shortCode) async {
    await _requireDatabase().rawUpdate(
      'UPDATE quick_replies SET usage_count = usage_count + 1 WHERE short_code = ?',
      [shortCode],
    );
  }

  Future<void> deleteQuickReply(String shortCode) async {
    await _requireDatabase().delete(
      'quick_replies',
      where: 'short_code = ?',
      whereArgs: [shortCode],
    );
  }

  Future<void> saveLabel({
    required String id,
    required String name,
    required String color,
    DateTime? createdAt,
  }) async {
    await _requireDatabase().insert(
      'labels',
      <String, Object?>{
        'id': id,
        'name': name,
        'color': color,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> listLabels() async {
    final rows = await _requireDatabase().query(
      'labels',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map((row) => Map<String, Object?>.from(row)).toList(growable: false);
  }

  Future<void> assignLabelToConversation(String contactId, String labelId) async {
    await _requireDatabase().insert(
      'conversation_labels',
      <String, Object?>{
        'contact_id': contactId,
        'label_id': labelId,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeLabelFromConversation(String contactId, String labelId) async {
    await _requireDatabase().delete(
      'conversation_labels',
      where: 'contact_id = ? AND label_id = ?',
      whereArgs: [contactId, labelId],
    );
  }

  Future<List<String>> listConversationLabelIds(String contactId) async {
    final rows = await _requireDatabase().query(
      'conversation_labels',
      columns: const ['label_id'],
      where: 'contact_id = ?',
      whereArgs: [contactId],
    );
    return rows
        .map((row) => row['label_id'] as String?)
        .whereType<String>()
        .toList(growable: false);
  }

  Future<List<String>> listConversationIdsForLabel(String labelId) async {
    final rows = await _requireDatabase().query(
      'conversation_labels',
      columns: const ['contact_id'],
      where: 'label_id = ?',
      whereArgs: [labelId],
    );
    return rows
        .map((row) => row['contact_id'] as String?)
        .whereType<String>()
        .toList(growable: false);
  }

  Future<void> insertContactNote({
    required String id,
    required String contactId,
    required String content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final created = createdAt ?? DateTime.now();
    await _requireDatabase().insert(
      'contact_notes',
      <String, Object?>{
        'id': id,
        'contact_id': contactId,
        'content': content,
        'created_at': created.toIso8601String(),
        'updated_at': (updatedAt ?? created).toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateContactNote({
    required String noteId,
    required String content,
    DateTime? updatedAt,
  }) async {
    await _requireDatabase().update(
      'contact_notes',
      <String, Object?>{
        'content': content,
        'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  Future<void> deleteContactNote(String noteId) async {
    await _requireDatabase().delete(
      'contact_notes',
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  Future<List<Map<String, Object?>>> listContactNotes(String contactId) async {
    final rows = await _requireDatabase().query(
      'contact_notes',
      where: 'contact_id = ?',
      whereArgs: [contactId],
      orderBy: 'updated_at DESC',
    );
    return rows.map((row) => Map<String, Object?>.from(row)).toList(growable: false);
  }

  Future<void> saveConversationSettings({
    required String contactId,
    required bool muted,
    DateTime? snoozedUntil,
  }) async {
    await _requireDatabase().insert(
      'conversation_settings',
      <String, Object?>{
        'contact_id': contactId,
        'muted': muted ? 1 : 0,
        'snoozed_until': snoozedUntil?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, Object?>?> getConversationSettings(String contactId) async {
    final rows = await _requireDatabase().query(
      'conversation_settings',
      where: 'contact_id = ?',
      whereArgs: [contactId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }

    return Map<String, Object?>.from(rows.first);
  }

  Future<void> clearConversationSettings(String contactId) async {
    await _requireDatabase().delete(
      'conversation_settings',
      where: 'contact_id = ?',
      whereArgs: [contactId],
    );
  }

  Future<List<Message>> listMessages(String conversationId) async {
    final rows = await _requireDatabase().rawQuery(
      '''
      SELECT
        m.*,
        CASE WHEN s.message_id IS NULL THEN 0 ELSE 1 END AS is_starred
      FROM messages m
      LEFT JOIN starred_messages s ON s.message_id = m.id
      WHERE m.conversation_id = ?
      ORDER BY m.created_at ASC
      ''',
      [conversationId],
    );

    return rows.map(Message.fromMap).toList(growable: false);
  }

  Future<List<Message>> listStarredMessages() async {
    final rows = await _requireDatabase().rawQuery('''
      SELECT
        m.*,
        1 AS is_starred
      FROM messages m
      INNER JOIN starred_messages s ON s.message_id = m.id
      ORDER BY s.starred_at DESC
    ''');

    return rows.map(Message.fromMap).toList(growable: false);
  }

  Future<void> purgeExpiredMessages() async {
    await _requireDatabase().delete(
      'messages',
      where: 'expires_at IS NOT NULL AND expires_at < ?',
      whereArgs: [DateTime.now().toIso8601String()],
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Database _requireDatabase() {
    final database = _database;
    if (database == null) {
      throw StateError('MessageDatabase.open() must be called before use.');
    }
    return database;
  }
}
