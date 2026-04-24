import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../models/message.dart';
import 'attachment_message_payload.dart';

class AttachmentMessageService {
  const AttachmentMessageService();

  Future<List<TransportAttachment>> loadTransportAttachments(
    List<Attachment> attachments,
  ) async {
    final transportAttachments = <TransportAttachment>[];

    for (final attachment in attachments) {
      Uint8List? bytes;
      if (attachment.hasFilePath) {
        bytes = await File(attachment.filePath!).readAsBytes();
      }

      transportAttachments.add(
        TransportAttachment(
          id: attachment.id,
          type: attachment.type,
          displayName: attachment.displayName,
          mimeType: attachment.mimeType,
          sizeBytes: attachment.sizeBytes,
          metadata: attachment.metadata,
          bytes: bytes,
        ),
      );
    }

    return List<TransportAttachment>.unmodifiable(transportAttachments);
  }

  Future<List<Attachment>> saveInboundAttachments({
    required String messageId,
    required List<TransportAttachment> attachments,
  }) async {
    final savedAttachments = <Attachment>[];

    for (final attachment in attachments) {
      String? filePath;
      if (attachment.bytes != null) {
        filePath = await _saveInboundAttachmentBytes(
          messageId: messageId,
          attachment: attachment,
          bytes: attachment.bytes!,
        );
      }

      savedAttachments.add(
        Attachment(
          id: attachment.id,
          type: attachment.type,
          displayName: attachment.displayName,
          filePath: filePath,
          mimeType: attachment.mimeType,
          sizeBytes: attachment.sizeBytes,
          metadata: attachment.metadata,
        ),
      );
    }

    return List<Attachment>.unmodifiable(savedAttachments);
  }

  Future<String> _saveInboundAttachmentBytes({
    required String messageId,
    required TransportAttachment attachment,
    required Uint8List bytes,
  }) async {
    final directory = await getApplicationSupportDirectory();
    final attachmentsDirectory = Directory(
      path.join(directory.path, 'message_attachments'),
    );
    if (!await attachmentsDirectory.exists()) {
      await attachmentsDirectory.create(recursive: true);
    }

    final extension = path.extension(attachment.displayName).trim();
    final safeExtension = extension.isEmpty
        ? _defaultExtensionFor(attachment.type)
        : extension;
    final filePath = path.join(
      attachmentsDirectory.path,
      '$messageId-${attachment.id}$safeExtension',
    );
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  String _defaultExtensionFor(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return '.jpg';
      case AttachmentType.video:
        return '.mp4';
      case AttachmentType.audio:
        return '.ogg';
      case AttachmentType.document:
      case AttachmentType.location:
      case AttachmentType.contactCard:
        return '.bin';
    }
  }
}