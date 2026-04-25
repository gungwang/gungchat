import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gungchat/app/providers.dart';
import 'package:gungchat/media/media_gallery_screen.dart';
import 'package:gungchat/media/media_gallery_service.dart';
import 'package:gungchat/models/message.dart';

Widget _buildGalleryApp(ConversationMediaSnapshot snapshot) {
  return ProviderScope(
    overrides: [
      conversationMediaProvider.overrideWith((ref, conversationId) async => snapshot),
    ],
    child: const MaterialApp(
      home: MediaGalleryScreen(
        conversationId: 'peer:alice',
        title: 'Alice',
      ),
    ),
  );
}

void main() {
  testWidgets('media gallery screen renders empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildGalleryApp(const ConversationMediaSnapshot()),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No shared media is available for this conversation yet.'),
      findsOneWidget,
    );
  });

  testWidgets('media gallery screen renders audio and docs tabs', (
    WidgetTester tester,
  ) async {
    final baseMessage = Message(
      id: 'gallery-1',
      conversationId: 'peer:alice',
      senderId: 'peer:alice',
      body: '',
      type: MessageType.multiAttachment,
      deliveryState: MessageDeliveryState.read,
      createdAt: DateTime(2026, 4, 24, 12),
      isOutgoing: false,
    );

    final snapshot = ConversationMediaSnapshot(
      audio: [
        MediaGalleryItem(
          message: baseMessage,
          attachmentType: AttachmentType.audio,
          displayName: 'Voice message',
          filePath: '/tmp/audio-message.ogg',
        ),
      ],
      documents: [
        MediaGalleryItem(
          message: baseMessage,
          attachmentType: AttachmentType.location,
          displayName: 'Location',
          attachment: Attachment(
            id: 'loc-1',
            type: AttachmentType.location,
            displayName: 'Current location',
            metadata: {
              'latitude': 37.7749,
              'longitude': -122.4194,
            },
          ),
        ),
        MediaGalleryItem(
          message: baseMessage,
          attachmentType: AttachmentType.contactCard,
          displayName: 'Alice card',
          attachment: Attachment(
            id: 'contact-1',
            type: AttachmentType.contactCard,
            displayName: '',
            metadata: {
              'displayName': 'Alice',
              'fingerprint': 'peer:alice',
            },
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      _buildGalleryApp(snapshot),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alice Media'), findsOneWidget);

    await tester.tap(find.text('Audio'));
    await tester.pumpAndSettle();

    expect(find.text('Voice message'), findsOneWidget);
    expect(find.text('/tmp/audio-message.ogg'), findsOneWidget);

    await tester.tap(find.text('Docs'));
    await tester.pumpAndSettle();

    expect(find.text('Location'), findsOneWidget);
    expect(find.textContaining('latitude: 37.7749'), findsOneWidget);
    expect(find.text('Alice card'), findsOneWidget);
    expect(find.textContaining('fingerprint: peer:alice'), findsOneWidget);
  });
}