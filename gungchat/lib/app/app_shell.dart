import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/accessibility/a11y_helper.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/pending_peer_input.dart';
import '../features/contacts/contacts_screen.dart';
import '../models/contact.dart';
import '../preferences/keyboard_shortcut_service.dart';
import '../features/settings/app_lock_preferences.dart';
import '../features/settings/settings_screen.dart';
import 'providers.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  StreamSubscription<Uri>? _deepLinkSubscription;
  bool _isAppLocked = false;
  bool _isUnlocking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final initialLifecycleState = WidgetsBinding.instance.lifecycleState;
    if (initialLifecycleState != null) {
      ref.read(appLifecycleStateProvider.notifier).state =
          initialLifecycleState;
    }
    _deepLinkSubscription =
        ref.read(appLinksProvider).uriLinkStream.listen(_handleIncomingUri);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLifecycleStateProvider.notifier).state = state;
    final appLockSettings = ref.read(appLockSettingsProvider);
    if (!appLockSettings.enabled) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      unawaited(_ensureUnlocked());
      return;
    }

    if (mounted) {
      setState(() {
        _isAppLocked = true;
      });
    }
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleIncomingUri(Uri uri) {
    final resolved = ref.read(peerDeepLinkServiceProvider).resolve(uri);
    if (resolved == null) {
      return;
    }

    ref.read(navigationIndexProvider.notifier).state = 0;
    ref.read(pendingPeerInputProvider.notifier).state = PendingPeerInput(
      rawValue: resolved.rawInput,
      source: PeerInputSource.deepLink,
      receivedAt: DateTime.now(),
    );
  }

  Future<void> _ensureUnlocked({bool force = false}) async {
    final settings = ref.read(appLockSettingsProvider);
    if (!settings.enabled) {
      if (mounted) {
        setState(() {
          _isAppLocked = false;
          _isUnlocking = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isUnlocking = true;
      });
    }

    final unlocked = await ref.read(appLockServiceProvider).ensureUnlocked(
          settings: settings,
          force: force,
        );
    if (!mounted) {
      return;
    }

    setState(() {
      _isUnlocking = false;
      _isAppLocked = !unlocked;
    });
  }

  void _selectTab(int index) {
    ref.read(navigationIndexProvider.notifier).state = index;
  }

  Future<void> _openQuickSearch(List<Contact> contacts) async {
    if (!mounted) {
      return;
    }

    final announcementView = View.of(context);
    final announcementDirection =
        Directionality.maybeOf(context) ?? TextDirection.ltr;

    final selectedContact = await showDialog<Contact>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        var query = '';

        return StatefulBuilder(
          builder: (context, setState) {
            final normalizedQuery = query.trim().toLowerCase();
            final matches = normalizedQuery.isEmpty
                ? contacts
                : contacts.where((contact) {
                    final haystack =
                        '${contact.displayName} ${contact.fingerprint}'.toLowerCase();
                    return haystack.contains(normalizedQuery);
                  }).toList(growable: false);

            return AlertDialog(
              title: const Text('Quick search'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Search contacts',
                        hintText: 'Name or fingerprint',
                      ),
                      onChanged: (value) {
                        setState(() {
                          query = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: matches.isEmpty
                          ? const Center(child: Text('No contacts match that search.'))
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: matches.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final contact = matches[index];
                                return ListTile(
                                  title: Text(contact.displayName),
                                  subtitle: Text(contact.fingerprint),
                                  onTap: () {
                                    Navigator.of(dialogContext).pop(contact);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedContact == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    ref.read(selectedContactFingerprintProvider.notifier).state =
        selectedContact.fingerprint;
    _selectTab(0);
    unawaited(
      A11yHelper.announceWithView(
        view: announcementView,
        message: 'Opened chat for ${selectedContact.displayName}',
        direction: announcementDirection,
      ),
    );
  }

  Future<void> _toggleMuteSelectedContact(Contact? contact) async {
    if (contact == null) {
      return;
    }

    final announcementView = View.of(context);
    final announcementDirection =
        Directionality.maybeOf(context) ?? TextDirection.ltr;

    final muteService = await ref.read(conversationMuteServiceProvider.future);
    final currentSettings = await muteService.getSettings(contact.fingerprint);
    if (currentSettings.muted) {
      await muteService.unmute(contact.fingerprint);
      unawaited(
        A11yHelper.announceWithView(
          view: announcementView,
          message: '${contact.displayName} unmuted',
          direction: announcementDirection,
        ),
      );
    } else {
      await muteService.mute(contact.fingerprint);
      unawaited(
        A11yHelper.announceWithView(
          view: announcementView,
          message: '${contact.displayName} muted',
          direction: announcementDirection,
        ),
      );
    }
    ref.invalidate(conversationMuteStateProvider(contact.fingerprint));
  }

  static const _screens = <Widget>[
    ChatScreen(),
    ContactsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    final peerSession = ref.watch(peerSessionControllerProvider);
    final effectivePresenceStatus = ref.watch(effectivePresenceStatusProvider);
    final customStatusText = ref.watch(customStatusTextProvider);
    final appLockSettings = ref.watch(appLockSettingsProvider);
    final savedContacts = ref.watch(contactBookProvider);
    final selectedContact = ref.watch(selectedContactProvider);
    final shortcuts = ref.watch(keyboardShortcutServiceProvider).shortcuts;

    ref.listen<AppLockSettings>(appLockSettingsProvider, (previous, next) {
      if (!next.enabled) {
        ref.read(appLockServiceProvider).clearSession();
        if (mounted) {
          setState(() {
            _isAppLocked = false;
            _isUnlocking = false;
          });
        }
        return;
      }

      final shouldForceUnlock = previous == null || !previous.enabled;
      unawaited(_ensureUnlocked(force: shouldForceUnlock));
    });

    if (peerSession.isTransportReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        unawaited(
          ref
              .read(peerSessionControllerProvider.notifier)
              .syncPresence(effectivePresenceStatus),
        );
        unawaited(
          ref
              .read(peerSessionControllerProvider.notifier)
              .syncCustomStatusText(customStatusText),
        );
      });
    }

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        shortcuts[AppShortcutAction.quickSearch]!: const _QuickSearchIntent(),
        shortcuts[AppShortcutAction.cycleTheme]!: const _CycleThemeIntent(),
        shortcuts[AppShortcutAction.nextTab]!: const _NextTabIntent(),
        shortcuts[AppShortcutAction.previousTab]!: const _PreviousTabIntent(),
        shortcuts[AppShortcutAction.focusComposer]!: const _FocusComposerIntent(),
        shortcuts[AppShortcutAction.muteConversation]!: const _ToggleMuteIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _QuickSearchIntent: CallbackAction<_QuickSearchIntent>(
            onInvoke: (_) {
              unawaited(_openQuickSearch(savedContacts));
              return null;
            },
          ),
          _CycleThemeIntent: CallbackAction<_CycleThemeIntent>(
            onInvoke: (_) {
              final announcementView = View.of(context);
              final announcementDirection =
                  Directionality.maybeOf(context) ?? TextDirection.ltr;
              unawaited(() async {
                await ref.read(appThemeModeProvider.notifier).cycleTheme();
                await A11yHelper.announceWithView(
                  view: announcementView,
                  message: 'Theme changed to ${ref.read(appThemeModeProvider).name}',
                  direction: announcementDirection,
                );
              }());
              return null;
            },
          ),
          _NextTabIntent: CallbackAction<_NextTabIntent>(
            onInvoke: (_) {
              _selectTab((selectedIndex + 1) % _screens.length);
              return null;
            },
          ),
          _PreviousTabIntent: CallbackAction<_PreviousTabIntent>(
            onInvoke: (_) {
              _selectTab((selectedIndex - 1 + _screens.length) % _screens.length);
              return null;
            },
          ),
          _FocusComposerIntent: CallbackAction<_FocusComposerIntent>(
            onInvoke: (_) {
              _selectTab(0);
              ref.read(chatComposerFocusNodeProvider).requestFocus();
              return null;
            },
          ),
          _ToggleMuteIntent: CallbackAction<_ToggleMuteIntent>(
            onInvoke: (_) {
              unawaited(_toggleMuteSelectedContact(selectedContact));
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              Scaffold(
                body: IndexedStack(index: selectedIndex, children: _screens),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: _selectTab,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.chat_bubble_outline),
                      selectedIcon: Icon(Icons.chat_bubble),
                      label: 'Chats',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.wifi_tethering_outlined),
                      selectedIcon: Icon(Icons.wifi_tethering),
                      label: 'Contacts',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
              if (appLockSettings.enabled && (_isAppLocked || _isUnlocking))
                Positioned.fill(
                  child: _AppLockOverlay(
                    unlocking: _isUnlocking,
                    onUnlock: () => _ensureUnlocked(force: true),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickSearchIntent extends Intent {
  const _QuickSearchIntent();
}

class _CycleThemeIntent extends Intent {
  const _CycleThemeIntent();
}

class _NextTabIntent extends Intent {
  const _NextTabIntent();
}

class _PreviousTabIntent extends Intent {
  const _PreviousTabIntent();
}

class _FocusComposerIntent extends Intent {
  const _FocusComposerIntent();
}

class _ToggleMuteIntent extends Intent {
  const _ToggleMuteIntent();
}

class _AppLockOverlay extends StatelessWidget {
  const _AppLockOverlay({
    required this.unlocking,
    required this.onUnlock,
  });

  final bool unlocking;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'GungChat is locked',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Unlock with your device credentials to continue.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: unlocking ? null : onUnlock,
                  icon: unlocking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open),
                  label: Text(unlocking ? 'Unlocking...' : 'Unlock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
