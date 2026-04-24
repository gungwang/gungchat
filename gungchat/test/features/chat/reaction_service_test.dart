import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/features/chat/reaction_service.dart';

void main() {
  group('ReactionService', () {
    const service = ReactionService();

    test('adds a reaction when the user has not reacted yet', () {
      final updated = service.toggleReaction(
        emoji: '👍',
        myUserId: 'alice',
        currentReactions: const {
          '❤️': ['bob'],
        },
      );

      expect(updated, {
        '❤️': ['bob'],
        '👍': ['alice'],
      });
    });

    test('removes a reaction when the user already reacted', () {
      final updated = service.toggleReaction(
        emoji: '👍',
        myUserId: 'alice',
        currentReactions: const {
          '👍': ['alice', 'bob'],
        },
      );

      expect(updated, {
        '👍': ['bob'],
      });
    });

    test('drops the emoji key when its last reaction is removed', () {
      final updated = service.toggleReaction(
        emoji: '👍',
        myUserId: 'alice',
        currentReactions: const {
          '👍': ['alice'],
        },
      );

      expect(updated, isEmpty);
    });
  });
}