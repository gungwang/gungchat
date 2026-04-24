import 'package:flutter/foundation.dart';

enum SlashCommandAction {
  clear,
  export,
  status,
  destroy,
  showHelp,
  showMessage,
}

@immutable
class SlashCommandResult {
  const SlashCommandResult({
    required this.action,
    this.message,
    this.statusText,
  });

  final SlashCommandAction action;
  final String? message;
  final String? statusText;
}

class SlashCommandRegistry {
  const SlashCommandRegistry();

  static const Map<String, String> _commandDescriptions = {
    'clear': 'Clear the current conversation from local storage.',
    'export': 'Export the current conversation to a ZIP archive and share it.',
    'status': 'Set or clear your custom status text.',
    'destroy': 'Wipe local app data, contacts, and identity keys.',
    'help': 'Show available slash commands.',
  };

  SlashCommandResult? execute(String input) {
    final normalized = input.trim();
    if (!normalized.startsWith('/')) {
      return null;
    }

    final body = normalized.substring(1).trim();
    if (body.isEmpty) {
      return const SlashCommandResult(
        action: SlashCommandAction.showMessage,
        message: 'Type /help to list available commands.',
      );
    }

    final separatorIndex = body.indexOf(RegExp(r'\s'));
    final name = (separatorIndex == -1 ? body : body.substring(0, separatorIndex))
        .toLowerCase();
    final args = separatorIndex == -1 ? '' : body.substring(separatorIndex + 1);

    switch (name) {
      case 'clear':
        return const SlashCommandResult(action: SlashCommandAction.clear);
      case 'export':
        return const SlashCommandResult(action: SlashCommandAction.export);
      case 'status':
        return SlashCommandResult(
          action: SlashCommandAction.status,
          statusText: args,
        );
      case 'destroy':
        return const SlashCommandResult(action: SlashCommandAction.destroy);
      case 'help':
        return SlashCommandResult(
          action: SlashCommandAction.showHelp,
          message: helpText,
        );
      default:
        return SlashCommandResult(
          action: SlashCommandAction.showMessage,
          message: 'Unknown command: /$name. Type /help for the list of commands.',
        );
    }
  }

  String get helpText {
    return _commandDescriptions.entries
        .map((entry) => '/${entry.key} - ${entry.value}')
        .join('\n');
  }
}