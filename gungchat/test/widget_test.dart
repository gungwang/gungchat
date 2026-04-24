import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gungchat/app/providers.dart';
import 'package:gungchat/features/chat/link_preview_service.dart';
import 'package:gungchat/features/chat/widgets/message_bubble.dart';
import 'package:gungchat/models/message.dart';

Widget _buildTestApp(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('message bubble renders message body and metadata', (
    WidgetTester tester,
  ) async {
    final message = Message(
      id: '1',
      conversationId: 'bootstrap',
      senderId: 'peer-a',
      body: 'hello gungchat',
      type: MessageType.text,
      deliveryState: MessageDeliveryState.sent,
      createdAt: DateTime(2026, 4, 16, 9, 30),
      isOutgoing: true,
    );

    await tester.pumpWidget(
      _buildTestApp(
        MessageBubble(message: message),
      ),
    );

    expect(find.text('hello gungchat'), findsOneWidget);
    expect(find.textContaining('sent'), findsOneWidget);
    expect(find.textContaining('Burn-after-read'), findsOneWidget);
  });

  testWidgets('message bubble renders quoted preview and supports reply', (
    WidgetTester tester,
  ) async {
    var replyInvoked = false;
    var jumpInvoked = false;
    final message = Message(
      id: '2',
      conversationId: 'bootstrap',
      senderId: 'peer-a',
      body: 'follow up message',
      type: MessageType.text,
      deliveryState: MessageDeliveryState.delivered,
      createdAt: DateTime(2026, 4, 16, 9, 32),
      isOutgoing: false,
      replyToMessageId: '1',
      replyToBody: 'earlier ||secret|| body',
    );

    await tester.pumpWidget(
      _buildTestApp(
        MessageBubble(
          message: message,
          onReply: () {
            replyInvoked = true;
          },
          onQuotedMessageTap: () {
            jumpInvoked = true;
          },
        ),
      ),
    );

    expect(find.text('Quoted message'), findsOneWidget);
    expect(find.text('earlier Spoiler body'), findsOneWidget);

    await tester.tap(find.text('earlier Spoiler body'));
    await tester.pump();

    expect(jumpInvoked, isTrue);

    await tester.longPress(find.text('follow up message'));
    await tester.pump();

    expect(replyInvoked, isTrue);
  });

  testWidgets('message bubble renders reactions and toggles them', (
    WidgetTester tester,
  ) async {
    String? toggledEmoji;
    final message = Message(
      id: '3',
      conversationId: 'bootstrap',
      senderId: 'peer-a',
      body: 'react to this message',
      type: MessageType.text,
      deliveryState: MessageDeliveryState.sent,
      createdAt: DateTime(2026, 4, 16, 9, 35),
      isOutgoing: true,
      reactions: const {
        '👍': ['peer-a', 'peer-b'],
      },
    );

    await tester.pumpWidget(
      _buildTestApp(
        MessageBubble(
          message: message,
          currentUserId: 'peer-a',
          onToggleReaction: (emoji) {
            toggledEmoji = emoji;
          },
        ),
      ),
    );

    expect(find.text('👍 2'), findsOneWidget);

    await tester.tap(find.text('👍 2'));
    await tester.pump();

    expect(toggledEmoji, '👍');
  });

  testWidgets('message bubble renders star toggle', (
    WidgetTester tester,
  ) async {
    var toggledStar = false;
    final message = Message(
      id: '4',
      conversationId: 'bootstrap',
      senderId: 'peer-a',
      body: 'bookmark me',
      type: MessageType.text,
      deliveryState: MessageDeliveryState.sent,
      createdAt: DateTime(2026, 4, 16, 9, 36),
      isOutgoing: true,
      isStarred: true,
    );

    await tester.pumpWidget(
      _buildTestApp(
        MessageBubble(
          message: message,
          onToggleStar: () {
            toggledStar = true;
          },
        ),
      ),
    );

    expect(find.byIcon(Icons.star), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star));
    await tester.pump();

    expect(toggledStar, isTrue);
  });

  testWidgets('message bubble renders edited metadata and action menu', (
    WidgetTester tester,
  ) async {
    var editTapped = false;
    MessageDeleteMode? deleteMode;
    final message = Message(
      id: '5',
      conversationId: 'bootstrap',
      senderId: 'peer-a',
      body: 'revised text',
      type: MessageType.text,
      deliveryState: MessageDeliveryState.read,
      createdAt: DateTime(2026, 4, 16, 9, 40),
      editedAt: DateTime(2026, 4, 16, 9, 41),
      isOutgoing: true,
    );

    await tester.pumpWidget(
      _buildTestApp(
        MessageBubble(
          message: message,
          onEdit: () {
            editTapped = true;
          },
          onDelete: (mode) {
            deleteMode = mode;
          },
        ),
      ),
    );

    expect(find.textContaining('edited'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('message-actions-button')));
    await tester.pumpAndSettle();

    final dynamic editItemState = tester.state(
      find.byKey(const ValueKey('message-action-edit')),
    );
    editItemState.handleTap();
    await tester.pumpAndSettle();

    expect(editTapped, isTrue);

    await tester.tap(find.byKey(const ValueKey('message-actions-button')));
    await tester.pumpAndSettle();

    final dynamic deleteItemState = tester.state(
      find.byKey(const ValueKey('message-action-delete')),
    );
    deleteItemState.handleTap();
    await tester.pumpAndSettle();

    expect(deleteMode, MessageDeleteMode.tombstone);
  });

  testWidgets('message bubble renders deleted placeholder', (
    WidgetTester tester,
  ) async {
    final message = Message(
      id: '6',
      conversationId: 'bootstrap',
      senderId: 'peer-a',
      body: '',
      type: MessageType.text,
      deliveryState: MessageDeliveryState.read,
      createdAt: DateTime(2026, 4, 16, 9, 42),
      deletedAt: DateTime(2026, 4, 16, 9, 43),
      deleteMode: MessageDeleteMode.tombstone,
      isOutgoing: true,
    );

    await tester.pumpWidget(
      _buildTestApp(
        MessageBubble(message: message),
      ),
    );

    expect(find.text('Message deleted'), findsOneWidget);
    expect(find.textContaining('• deleted'), findsOneWidget);
  });

  testWidgets('message bubble renders audio playback affordance', (
    WidgetTester tester,
  ) async {
    var playedAudio = false;
    final message = Message(
      id: '7',
      conversationId: 'bootstrap',
      senderId: 'peer-a',
      body: '',
      type: MessageType.audio,
      deliveryState: MessageDeliveryState.sent,
      createdAt: DateTime(2026, 4, 16, 9, 44),
      isOutgoing: false,
      audioFilePath: '/tmp/audio-message.ogg',
      audioDurationMs: 4200,
    );

    await tester.pumpWidget(
      _buildTestApp(
        MessageBubble(
          message: message,
          onPlayAudio: () {
            playedAudio = true;
          },
        ),
      ),
    );

    expect(find.text('Voice message'), findsOneWidget);
    expect(find.text('0:05'), findsOneWidget);

    await tester.tap(find.byTooltip('Play voice message'));
    await tester.pump();

    expect(playedAudio, isTrue);
  });

  testWidgets('message bubble renders link preview when previews are enabled', (
    WidgetTester tester,
  ) async {
    final message = Message(
      id: '8',
      conversationId: 'bootstrap',
      senderId: 'peer-a',
      body: 'Look at https://example.com right now',
      type: MessageType.text,
      deliveryState: MessageDeliveryState.sent,
      createdAt: DateTime(2026, 4, 16, 9, 45),
      isOutgoing: false,
    );
    await tester.pumpWidget(
      _buildTestApp(
        MessageBubble(message: message),
        overrides: [
          linkPreviewProvider.overrideWith(
            (ref, url) async => const LinkPreview(
              url: 'https://example.com',
              title: 'Example Domain',
              description: 'Preview description',
            ),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Example Domain'), findsOneWidget);
    expect(find.text('Preview description'), findsOneWidget);
  });

  testWidgets('message bubble hides spoiler text until tapped', (
    WidgetTester tester,
  ) async {
    final message = Message(
      id: '9',
      conversationId: 'bootstrap',
      senderId: 'peer-a',
      body: 'Keep ||top secret|| safe',
      type: MessageType.text,
      deliveryState: MessageDeliveryState.sent,
      createdAt: DateTime(2026, 4, 16, 9, 46),
      isOutgoing: false,
    );

    await tester.pumpWidget(
      _buildTestApp(
        MessageBubble(message: message),
      ),
    );

    expect(find.byKey(const ValueKey('spoiler-segment-1')), findsOneWidget);
    expect(find.text('Keep top secret safe', findRichText: true), findsNothing);

    await tester.tap(find.byKey(const ValueKey('spoiler-segment-1')));
    await tester.pump();

    expect(find.byKey(const ValueKey('spoiler-segment-1')), findsNothing);
    expect(find.text('Keep top secret safe', findRichText: true), findsOneWidget);
  });

  testWidgets('message bubble does not preview links hidden in spoilers', (
    WidgetTester tester,
  ) async {
    final message = Message(
      id: '10',
      conversationId: 'bootstrap',
      senderId: 'peer-a',
      body: 'Hold ||https://example.com|| back',
      type: MessageType.text,
      deliveryState: MessageDeliveryState.sent,
      createdAt: DateTime(2026, 4, 16, 9, 47),
      isOutgoing: false,
    );

    await tester.pumpWidget(
      _buildTestApp(
        MessageBubble(message: message),
        overrides: [
          linkPreviewProvider.overrideWith(
            (ref, url) async => const LinkPreview(
              url: 'https://example.com',
              title: 'Example Domain',
            ),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Example Domain'), findsNothing);
    expect(find.byKey(const ValueKey('spoiler-segment-1')), findsOneWidget);
  });
}
