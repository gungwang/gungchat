import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';

import '../app/providers.dart';
import '../models/message.dart';
import 'media_gallery_service.dart';

class MediaGalleryScreen extends ConsumerWidget {
  const MediaGalleryScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  final String conversationId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(conversationMediaProvider(conversationId));

    return Scaffold(
      appBar: AppBar(title: Text('$title Media')),
      body: mediaAsync.when(
        data: (media) {
          if (media.isEmpty) {
            return const Center(
              child: Text('No shared media is available for this conversation yet.'),
            );
          }

          return DefaultTabController(
            length: 4,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Images'),
                    Tab(text: 'Videos'),
                    Tab(text: 'Audio'),
                    Tab(text: 'Docs'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ImageGalleryTab(items: media.images),
                      _MediaListTab(items: media.videos),
                      _MediaListTab(items: media.audio),
                      _MediaListTab(items: media.documents),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load media: $error')),
      ),
    );
  }
}

class _ImageGalleryTab extends StatelessWidget {
  const _ImageGalleryTab({required this.items});

  final List<MediaGalleryItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No images yet.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final filePath = item.filePath;
        if (filePath == null || filePath.isEmpty) {
          return _EmptyMediaTile(label: item.displayName);
        }

        return Semantics(
          button: true,
          label: 'Open image ${item.displayName}',
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _ImageViewerScreen(
                    title: item.displayName,
                    filePath: filePath,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(filePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _EmptyMediaTile(label: item.displayName),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MediaListTab extends StatelessWidget {
  const _MediaListTab({required this.items});

  final List<MediaGalleryItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Nothing to show here yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        final metadataText = item.attachment?.metadata.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(' • ');
        return ListTile(
          leading: Icon(_iconForType(item.attachmentType)),
          title: Text(item.displayName),
          subtitle: Text(
            [
              if (item.filePath != null && item.filePath!.isNotEmpty) item.filePath!,
              if (metadataText != null && metadataText.isNotEmpty) metadataText,
            ].join('\n'),
          ),
          isThreeLine: metadataText != null && metadataText.isNotEmpty,
        );
      },
    );
  }

  IconData _iconForType(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return Icons.image_outlined;
      case AttachmentType.video:
        return Icons.videocam_outlined;
      case AttachmentType.audio:
        return Icons.audio_file_outlined;
      case AttachmentType.document:
        return Icons.insert_drive_file_outlined;
      case AttachmentType.location:
        return Icons.place_outlined;
      case AttachmentType.contactCard:
        return Icons.contact_page_outlined;
    }
  }
}

class _ImageViewerScreen extends StatelessWidget {
  const _ImageViewerScreen({
    required this.title,
    required this.filePath,
  });

  final String title;
  final String filePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PhotoView(
        imageProvider: FileImage(File(filePath)),
        backgroundDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}

class _EmptyMediaTile extends StatelessWidget {
  const _EmptyMediaTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            label,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}