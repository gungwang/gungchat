import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/storage/message_db.dart';

@immutable
class ContactNote {
  const ContactNote({
    required this.id,
    required this.contactId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String contactId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ContactNote.fromMap(Map<String, Object?> map) {
    return ContactNote(
      id: map['id']! as String,
      contactId: map['contact_id']! as String,
      content: map['content']! as String,
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
    );
  }
}

class ContactNotesService {
  ContactNotesService(this._database, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final MessageDatabase _database;
  final Uuid _uuid;

  Future<ContactNote> addNote(String contactId, String noteText) async {
    final normalizedContactId = contactId.trim();
    final normalizedText = noteText.trim();
    if (normalizedContactId.isEmpty || normalizedText.isEmpty) {
      throw ArgumentError('Contact notes require a contact and note text.');
    }

    final now = DateTime.now();
    final note = ContactNote(
      id: _uuid.v4(),
      contactId: normalizedContactId,
      content: normalizedText,
      createdAt: now,
      updatedAt: now,
    );
    await _database.insertContactNote(
      id: note.id,
      contactId: note.contactId,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
    );
    return note;
  }

  Future<void> updateNote(String noteId, String newText) async {
    final normalizedText = newText.trim();
    if (normalizedText.isEmpty) {
      throw ArgumentError('Updated note text must not be empty.');
    }

    await _database.updateContactNote(
      noteId: noteId,
      content: normalizedText,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> deleteNote(String noteId) {
    return _database.deleteContactNote(noteId);
  }

  Future<List<ContactNote>> getNotesForContact(String contactId) async {
    final rows = await _database.listContactNotes(contactId);
    return rows.map(ContactNote.fromMap).toList(growable: false);
  }
}