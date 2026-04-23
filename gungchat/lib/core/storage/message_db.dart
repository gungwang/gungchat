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
      version: 3,
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
            reactions_json TEXT
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

  Future<List<Message>> listMessages(String conversationId) async {
    final rows = await _requireDatabase().query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );

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
