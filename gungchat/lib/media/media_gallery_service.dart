import 'package:flutter/foundation.dart';

import '../core/storage/message_db.dart';
import '../models/message.dart';

@immutable
class MediaGalleryItem {
  const MediaGalleryItem({
    required this.message,
    required this.attachmentType,
    required this.displayName,
    this.filePath,
    this.attachment,
  });

  final Message message;
  final AttachmentType attachmentType;
  final String displayName;
  final String? filePath;
  final Attachment? attachment;
}

@immutable
class ConversationMediaSnapshot {
  const ConversationMediaSnapshot({
    this.images = const <MediaGalleryItem>[],
    this.videos = const <MediaGalleryItem>[],
    this.audio = const <MediaGalleryItem>[],
    this.documents = const <MediaGalleryItem>[],
  });

  final List<MediaGalleryItem> images;
  final List<MediaGalleryItem> videos;
  final List<MediaGalleryItem> audio;
  final List<MediaGalleryItem> documents;

  bool get isEmpty =>
      images.isEmpty && videos.isEmpty && audio.isEmpty && documents.isEmpty;
}

class MediaGalleryService {
  const MediaGalleryService(this._database);

  final MessageDatabase _database;

  Future<ConversationMediaSnapshot> getMediaByType(String conversationId) async {
    final messages = await _database.listMessages(conversationId);
    final images = <MediaGalleryItem>[];
    final videos = <MediaGalleryItem>[];
    final audio = <MediaGalleryItem>[];
    final documents = <MediaGalleryItem>[];

    for (final message in messages) {
      if (message.type == MessageType.audio && message.hasAudio) {
        audio.add(
          MediaGalleryItem(
            message: message,
            attachmentType: AttachmentType.audio,
            displayName: message.previewText,
            filePath: message.audioFilePath,
          ),
        );
      }

      for (final attachment in message.attachments) {
        final item = MediaGalleryItem(
          message: message,
          attachmentType: attachment.type,
          displayName: attachment.previewLabel,
          filePath: attachment.filePath,
          attachment: attachment,
        );
        switch (attachment.type) {
          case AttachmentType.image:
            images.add(item);
          case AttachmentType.video:
            videos.add(item);
          case AttachmentType.audio:
            audio.add(item);
          case AttachmentType.document:
          case AttachmentType.location:
          case AttachmentType.contactCard:
            documents.add(item);
        }
      }
    }

    return ConversationMediaSnapshot(
      images: List<MediaGalleryItem>.unmodifiable(images.reversed),
      videos: List<MediaGalleryItem>.unmodifiable(videos.reversed),
      audio: List<MediaGalleryItem>.unmodifiable(audio.reversed),
      documents: List<MediaGalleryItem>.unmodifiable(documents.reversed),
    );
  }
}