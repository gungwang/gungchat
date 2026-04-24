class ReactionService {
  const ReactionService();

  static const defaultEmojis = <String>['👍', '❤️', '😂', '😮', '😢', '👏'];

  Map<String, List<String>> toggleReaction({
    required String emoji,
    required String myUserId,
    required Map<String, List<String>> currentReactions,
  }) {
    final reactions = <String, List<String>>{
      for (final entry in currentReactions.entries)
        entry.key: List<String>.from(entry.value),
    };
    final users = List<String>.from(reactions[emoji] ?? const <String>[]);

    if (users.contains(myUserId)) {
      users.remove(myUserId);
      if (users.isEmpty) {
        reactions.remove(emoji);
      } else {
        reactions[emoji] = users;
      }
    } else {
      reactions[emoji] = <String>[...users, myUserId];
    }

    return reactions;
  }
}