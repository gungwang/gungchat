import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/message.dart';

typedef LoadExportDirectory = Future<Directory> Function();
typedef ShareExportFiles = Future<void> Function(
  List<XFile> files, {
  String? text,
});

class ChatExportService {
  ChatExportService({
    LoadExportDirectory? loadExportDirectory,
    ShareExportFiles? shareFiles,
  })  : _loadExportDirectory = loadExportDirectory ?? getTemporaryDirectory,
        _shareFiles = shareFiles ?? Share.shareXFiles;

  final LoadExportDirectory _loadExportDirectory;
  final ShareExportFiles _shareFiles;

  Future<File> exportConversation({
    required String conversationId,
    required String conversationLabel,
    required List<Message> messages,
  }) async {
    final exportData = <String, Object?>{
      'app': 'GungChat',
      'exportedAt': DateTime.now().toIso8601String(),
      'conversationId': conversationId,
      'conversationLabel': conversationLabel,
      'messageCount': messages.length,
      'messages': messages.map(_messageToJson).toList(growable: false),
    };

    final jsonBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(exportData),
    );
    final archive = Archive()
      ..addFile(ArchiveFile('chat_export.json', jsonBytes.length, jsonBytes));
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw StateError('Failed to encode the export archive.');
    }

    final directory = await _loadExportDirectory();
    final safeLabel = conversationLabel
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final file = File(
      path.join(
        directory.path,
        'gungchat_export_${safeLabel.isEmpty ? 'conversation' : safeLabel}_${DateTime.now().millisecondsSinceEpoch}.zip',
      ),
    );
    await file.writeAsBytes(zipBytes, flush: true);
    return file;
  }

  Future<void> shareExport(File exportFile) async {
    await _shareFiles(
      [XFile(exportFile.path)],
      text: 'GungChat Export',
    );
  }

  Map<String, Object?> _messageToJson(Message message) {
    return <String, Object?>{
      'id': message.id,
      'conversationId': message.conversationId,
      'senderId': message.senderId,
      'body': message.body,
      'type': message.type.name,
      'deliveryState': message.deliveryState.name,
      'createdAt': message.createdAt.toIso8601String(),
      'isOutgoing': message.isOutgoing,
      'burnAfterRead': message.burnAfterRead,
      'expiresAt': message.expiresAt?.toIso8601String(),
      'replyToMessageId': message.replyToMessageId,
      'replyToBody': message.replyToBody,
      'reactions': message.reactions,
      'isStarred': message.isStarred,
      'editedAt': message.editedAt?.toIso8601String(),
      'deletedAt': message.deletedAt?.toIso8601String(),
      'deleteMode': message.deleteMode?.name,
      'audioDurationMs': message.audioDurationMs,
    };
  }
}