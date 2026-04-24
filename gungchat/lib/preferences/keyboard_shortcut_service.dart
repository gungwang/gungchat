import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum AppShortcutAction {
  quickSearch,
  cycleTheme,
  nextTab,
  previousTab,
  focusComposer,
  muteConversation,
}

class KeyboardShortcutService {
  const KeyboardShortcutService();

  Map<AppShortcutAction, ShortcutActivator> get shortcuts {
    return const <AppShortcutAction, ShortcutActivator>{
      AppShortcutAction.quickSearch: SingleActivator(
        LogicalKeyboardKey.keyK,
        control: true,
      ),
      AppShortcutAction.cycleTheme: SingleActivator(
        LogicalKeyboardKey.keyD,
        control: true,
        shift: true,
      ),
      AppShortcutAction.nextTab: SingleActivator(
        LogicalKeyboardKey.tab,
        control: true,
      ),
      AppShortcutAction.previousTab: SingleActivator(
        LogicalKeyboardKey.tab,
        control: true,
        shift: true,
      ),
      AppShortcutAction.focusComposer: SingleActivator(LogicalKeyboardKey.slash),
      AppShortcutAction.muteConversation: SingleActivator(
        LogicalKeyboardKey.keyM,
        control: true,
        shift: true,
      ),
    };
  }

  String describe(AppShortcutAction action) {
    return switch (action) {
      AppShortcutAction.quickSearch => 'Open quick search',
      AppShortcutAction.cycleTheme => 'Cycle theme mode',
      AppShortcutAction.nextTab => 'Move to the next app tab',
      AppShortcutAction.previousTab => 'Move to the previous app tab',
      AppShortcutAction.focusComposer => 'Focus the active chat composer',
      AppShortcutAction.muteConversation => 'Mute the selected conversation',
    };
  }
}