import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/accessibility/a11y_helper.dart';
import '../../preferences/notification_prefs_service.dart';
import '../../preferences/theme_service.dart';
import '../../templates/quick_reply_service.dart';
import '../chat/presence_status.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);
    final readReceiptsEnabled = ref.watch(readReceiptsEnabledProvider);
    final localPresenceStatus = ref.watch(localPresenceStatusProvider);
    final linkPreviewsEnabled = ref.watch(linkPreviewsEnabledProvider);
    final appLockSettings = ref.watch(appLockSettingsProvider);
    final notificationPreferences = ref.watch(notificationPreferencesProvider);
    final shortcutService = ref.watch(keyboardShortcutServiceProvider);

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
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AppThemeMode>(
                    initialValue: themeMode,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Theme mode',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: AppThemeMode.auto,
                        child: Text('Auto'),
                      ),
                      DropdownMenuItem(
                        value: AppThemeMode.light,
                        child: Text('Light'),
                      ),
                      DropdownMenuItem(
                        value: AppThemeMode.dark,
                        child: Text('Dark'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      unawaited(
                        ref.read(appThemeModeProvider.notifier).setTheme(value),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Keyboard shortcut: Ctrl+Shift+D cycles between Auto, Light, and Dark.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(child: _QuickReplyTemplatesCard()),
          const SizedBox(height: 12),
          Card(
            child: _CustomStatusCard(
              initialValue: ref.watch(customStatusTextProvider),
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile.adaptive(
              value: readReceiptsEnabled,
              onChanged: (value) {
                unawaited(
                  ref.read(readReceiptsEnabledProvider.notifier).setEnabled(value),
                );
              },
              title: const Text('Read receipts'),
              subtitle: const Text(
                'Opt in to send encrypted read confirmations when you open a conversation and view delivered messages.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile.adaptive(
              value: linkPreviewsEnabled,
              onChanged: (value) {
                unawaited(
                  ref.read(linkPreviewsEnabledProvider.notifier).setEnabled(value),
                );
              },
              title: const Text('Link previews'),
              subtitle: const Text(
                'Off by default for privacy. Enabling previews lets your device fetch webpage metadata directly, which can reveal your IP address to those sites.',
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                        ref.read(localPresenceStatusProvider.notifier).setStatus(value),
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
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification preferences',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final entry in notificationPreferences.entries)
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: entry.value,
                      onChanged: (value) {
                        unawaited(
                          ref
                              .read(notificationPreferencesProvider.notifier)
                              .setPreference(entry.key, value),
                        );
                      },
                      title: Text(entry.key.label),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keyboard shortcuts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final entry in shortcutService.shortcuts.entries)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(shortcutService.describe(entry.key)),
                      subtitle: Text(_shortcutLabel(entry.value)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App lock',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: appLockSettings.enabled,
                    onChanged: (value) {
                      unawaited(
                        ref.read(appLockSettingsProvider.notifier).setEnabled(value),
                      );
                    },
                    title: const Text('Require biometric or device unlock'),
                    subtitle: const Text(
                      'When enabled, GungChat prompts for device authentication on launch and after returning from the background.',
                    ),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: appLockSettings.timeoutSeconds,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Re-lock after',
                    ),
                    items: const [30, 60, 300, 600]
                        .map(
                          (seconds) => DropdownMenuItem(
                            value: seconds,
                            child: Text(
                              seconds < 60
                                  ? '$seconds seconds'
                                  : '${seconds ~/ 60} minute${seconds == 60 ? '' : 's'}',
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: appLockSettings.enabled
                        ? (value) {
                            if (value == null) {
                              return;
                            }
                            unawaited(
                              ref
                                  .read(appLockSettingsProvider.notifier)
                                  .setTimeoutSeconds(value),
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accessibility',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Reduced motion: ${A11yHelper.prefersReducedMotion(context) ? 'On' : 'Off'}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'High contrast: ${A11yHelper.isHighContrast(context) ? 'On' : 'Off'}',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This phase uses 48dp minimum touch targets, screen-reader announcements for key actions, and keyboard shortcut discovery surfaces.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
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

  String _shortcutLabel(ShortcutActivator activator) {
    if (activator is! SingleActivator) {
      return activator.toString();
    }

    final pieces = <String>[
      if (activator.control) 'Ctrl',
      if (activator.shift) 'Shift',
      if (activator.alt) 'Alt',
      activator.trigger.keyLabel.isEmpty
          ? activator.trigger.debugName ?? 'Key'
          : activator.trigger.keyLabel.toUpperCase(),
    ];
    return pieces.join('+');
  }
}

class _QuickReplyTemplatesCard extends ConsumerStatefulWidget {
  const _QuickReplyTemplatesCard();

  @override
  ConsumerState<_QuickReplyTemplatesCard> createState() =>
      _QuickReplyTemplatesCardState();
}

class _QuickReplyTemplatesCardState
    extends ConsumerState<_QuickReplyTemplatesCard> {
  final TextEditingController _shortCodeController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _shortCodeController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(allQuickRepliesProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick reply templates', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _shortCodeController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Shortcode',
                    hintText: '/hi',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _contentController,
                  minLines: 1,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Template text',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: A11yHelper.minimumTouchTarget,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveTemplate,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: const Text('Save template'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          templatesAsync.when(
            data: (templates) {
              if (templates.isEmpty) {
                return const Text(
                  'No quick replies saved yet. Create one here, then type its shortcode in chat to insert it instantly.',
                );
              }

              return Column(
                children: [
                  for (final template in templates)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('/${template.shortCode}'),
                      subtitle: Text(
                        '${template.content}\nUsed ${template.usageCount} time${template.usageCount == 1 ? '' : 's'}',
                      ),
                      isThreeLine: true,
                      trailing: ConstrainedBox(
                        constraints: A11yHelper.minimumTouchTarget,
                        child: IconButton(
                          tooltip: 'Delete template',
                          onPressed: () => _deleteTemplate(template),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Could not load quick replies: $error'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTemplate() async {
    final shortCode = _shortCodeController.text.trim();
    final content = _contentController.text.trim();
    if (shortCode.isEmpty || content.isEmpty) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final service = await ref.read(quickReplyServiceProvider.future);
      await service.createTemplate(shortCode, content);
      _shortCodeController.clear();
      _contentController.clear();
      ref.invalidate(allQuickRepliesProvider);
      if (mounted) {
        A11yHelper.announce('Quick reply saved', context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _deleteTemplate(QuickReply template) async {
    final service = await ref.read(quickReplyServiceProvider.future);
    await service.deleteTemplate(template.shortCode);
    ref.invalidate(allQuickRepliesProvider);
    if (mounted) {
      A11yHelper.announce('Quick reply deleted', context);
    }
  }
}

class _CustomStatusCard extends ConsumerStatefulWidget {
  const _CustomStatusCard({required this.initialValue});

  final String initialValue;

  @override
  ConsumerState<_CustomStatusCard> createState() => _CustomStatusCardState();
}

class _CustomStatusCardState extends ConsumerState<_CustomStatusCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _CustomStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Custom status', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLength: 80,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Status text',
              hintText: 'In a meeting, Do not disturb, Available later...',
            ),
            onChanged: (value) {
              unawaited(
                ref.read(customStatusTextProvider.notifier).setText(value),
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'This text is shared directly with the active peer session alongside your presence status.',
          ),
        ],
      ),
    );
  }
}
