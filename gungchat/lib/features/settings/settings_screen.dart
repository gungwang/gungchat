import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

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
                  Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
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
                'Phase 2 will wire platform flags such as secure windows and recording detection hooks.',
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
                'Capability reporting is stubbed now. Actual recording prevention is platform-specific and will follow after the base transport is stable.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
