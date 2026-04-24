import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../chat/presence_status.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final readReceiptsEnabled = ref.watch(readReceiptsEnabledProvider);
    final localPresenceStatus = ref.watch(localPresenceStatusProvider);
    final linkPreviewsEnabled = ref.watch(linkPreviewsEnabledProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Appearance',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ThemeMode>(
                    initialValue: themeMode,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Theme mode',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(themeModeProvider.notifier).state = value;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: SwitchListTile.adaptive(
              value: true,
              onChanged: null,
              title: const Text('Screenshot protection'),
              subtitle: const Text(
                'Android now enables secure windows. iOS and desktop recording detection still need platform-specific follow-up.',
              ),
            ),
          ),
          Card(
            child: SwitchListTile.adaptive(
              value: readReceiptsEnabled,
              onChanged: (value) {
                unawaited(
                  ref
                      .read(readReceiptsEnabledProvider.notifier)
                      .setEnabled(value),
                );
              },
              title: const Text('Read receipts'),
              subtitle: const Text(
                'Opt in to send encrypted read confirmations when you open a conversation and view delivered messages.',
              ),
            ),
          ),
          Card(
            child: SwitchListTile.adaptive(
              value: linkPreviewsEnabled,
              onChanged: (value) {
                unawaited(
                  ref
                      .read(linkPreviewsEnabledProvider.notifier)
                      .setEnabled(value),
                );
              },
              title: const Text('Link previews'),
              subtitle: const Text(
                'Off by default for privacy. Enabling previews lets your device fetch webpage metadata directly, which can reveal your IP address to those sites.',
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Presence status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PeerPresenceStatus>(
                    initialValue: localPresenceStatus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Shared presence',
                    ),
                    items: PeerPresenceStatus.values
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      unawaited(
                        ref
                            .read(localPresenceStatusProvider.notifier)
                            .setStatus(value),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Online is shared while the app is in the foreground and automatically falls back to Away in the background. Hidden suppresses your presence updates.',
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: SwitchListTile.adaptive(
              value: true,
              onChanged: null,
              title: const Text('Burn after read default'),
              subtitle: const Text(
                'The chat bootstrap flow already assumes ephemeral-first messaging.',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Anti-surveillance guard'),
              subtitle: const Text(
                'Transport is in place. Next platform work is expanding recording detection and privacy guard behavior beyond Android secure windows.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
