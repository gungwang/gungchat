import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/message.dart';

class MessageDatabase {
  Database? _database;

  Future<void> open() async {
    if (_database != null) {
      return;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final databasePath = path.join(documentsDirectory.path, 'gungchat.db');

    _database = await openDatabase(
      databasePath,
      version: 6,
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
            audio_duration_ms INTEGER
          )
        ''');
        await database.execute('''
          CREATE TABLE starred_messages(
            message_id TEXT PRIMARY KEY,
            starred_at TEXT NOT NULL
          )
        ''');
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
      },
    );
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
