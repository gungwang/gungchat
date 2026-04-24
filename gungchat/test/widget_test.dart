import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gungchat/features/chat/widgets/message_bubble.dart';
import 'package:gungchat/models/message.dart';

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
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: MessageBubble(message: message),
          ),
        ),
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
      replyToBody: 'earlier message body',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: MessageBubble(
              message: message,
              onReply: () {
                replyInvoked = true;
              },
              onQuotedMessageTap: () {
                jumpInvoked = true;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Quoted message'), findsOneWidget);
    expect(find.text('earlier message body'), findsOneWidget);

    await tester.tap(find.text('earlier message body'));
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
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: MessageBubble(
              message: message,
              currentUserId: 'peer-a',
              onToggleReaction: (emoji) {
                toggledEmoji = emoji;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('👍 2'), findsOneWidget);

    await tester.tap(find.text('👍 2'));
    await tester.pump();

    expect(toggledEmoji, '👍');
  });
}
