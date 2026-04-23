import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/chat/chat_screen.dart';
import '../features/chat/pending_peer_input.dart';
import '../features/contacts/contacts_screen.dart';
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
      });
    }

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
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
    );
  }
}
