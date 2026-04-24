import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/features/chat/chat_export_service.dart';
import 'package:gungchat/models/message.dart';

void main() {
  test('exports a conversation as a zip archive with json payload', () async {
    final tempDir = await Directory.systemTemp.createTemp('gungchat-export-test');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final service = ChatExportService(
      loadExportDirectory: () async => tempDir,
      shareFiles: (_, {text}) async {},
    );

    final exportFile = await service.exportConversation(
      conversationId: 'peer:aa:bb',
      conversationLabel: 'Alice Example',
      messages: [
        Message(
          id: 'message-1',
          conversationId: 'peer:aa:bb',
          senderId: 'aa:bb',
          body: 'Hello export',
          type: MessageType.text,
          deliveryState: MessageDeliveryState.sent,
          createdAt: DateTime.utc(2026, 4, 24, 12, 0),
          isOutgoing: true,
        ),
      ],
    );

    expect(await exportFile.exists(), isTrue);

    final archive = ZipDecoder().decodeBytes(await exportFile.readAsBytes());
    final entry = archive.findFile('chat_export.json');
    expect(entry, isNotNull);

    final payload = jsonDecode(
      utf8.decode(entry!.content as List<int>),
    ) as Map<String, dynamic>;
    expect(payload['conversationId'], 'peer:aa:bb');
    expect(payload['messageCount'], 1);
    expect((payload['messages'] as List<dynamic>).single['body'], 'Hello export');
  });
}