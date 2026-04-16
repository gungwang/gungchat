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
}
