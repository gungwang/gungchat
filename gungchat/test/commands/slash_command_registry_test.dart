import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/commands/slash_command_registry.dart';

void main() {
  const registry = SlashCommandRegistry();

  test('returns null for plain chat text', () {
    expect(registry.execute('hello peer'), isNull);
  });

  test('parses status slash commands', () {
    final result = registry.execute('/status In a meeting');

    expect(result, isNotNull);
    expect(result!.action, SlashCommandAction.status);
    expect(result.statusText, 'In a meeting');
  });

  test('returns a help message for unknown slash commands', () {
    final result = registry.execute('/unknown');

    expect(result, isNotNull);
    expect(result!.action, SlashCommandAction.showMessage);
    expect(result.message, contains('/help'));
  });
}