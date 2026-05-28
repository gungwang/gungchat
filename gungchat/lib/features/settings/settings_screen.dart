import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/accessibility/a11y_helper.dart';
import '../../l10n/l10n.dart';
import '../../preferences/keyboard_shortcut_service.dart';
import '../../preferences/locale_service.dart';
import '../../preferences/notification_prefs_service.dart';
import '../../preferences/theme_service.dart';
import '../../templates/quick_reply_service.dart';
import 'burn_after_read_delay_preferences.dart';
import '../chat/presence_status.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final appLocaleMode = ref.watch(appLocaleModeProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final readReceiptsEnabled = ref.watch(readReceiptsEnabledProvider);
    final burnAfterReadDelay = ref.watch(burnAfterReadDelayProvider);
    final localPresenceStatus = ref.watch(localPresenceStatusProvider);
    final linkPreviewsEnabled = ref.watch(linkPreviewsEnabledProvider);
    final appLockSettings = ref.watch(appLockSettingsProvider);
    final notificationPreferences = ref.watch(notificationPreferencesProvider);
    final shortcutService = ref.watch(keyboardShortcutServiceProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.settingsTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appearanceTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AppThemeMode>(
                    initialValue: themeMode,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: l10n.themeModeLabel,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: AppThemeMode.auto,
                        child: Text(_themeModeLabel(context, AppThemeMode.auto)),
                      ),
                      DropdownMenuItem(
                        value: AppThemeMode.light,
                        child: Text(_themeModeLabel(context, AppThemeMode.light)),
                      ),
                      DropdownMenuItem(
                        value: AppThemeMode.dark,
                        child: Text(_themeModeLabel(context, AppThemeMode.dark)),
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
                  Text(l10n.keyboardShortcutThemeHint),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AppLocaleMode>(
                    initialValue: appLocaleMode,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: l10n.languageLabel,
                    ),
                    items: AppLocaleMode.values
                        .map(
                          (mode) => DropdownMenuItem(
                            value: mode,
                            child: Text(_languageLabel(context, mode)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      unawaited(
                        ref.read(appLocaleModeProvider.notifier).setLocale(value),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.languageChangeHelp),
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
              title: Text(l10n.screenshotProtectionTitle),
              subtitle: Text(l10n.screenshotProtectionSubtitle),
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
              title: Text(l10n.readReceiptsTitle),
              subtitle: Text(l10n.readReceiptsSubtitle),
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
              title: Text(l10n.linkPreviewsTitle),
              subtitle: Text(l10n.linkPreviewsSubtitle),
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
                    l10n.presenceStatusTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PeerPresenceStatus>(
                    initialValue: localPresenceStatus,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: l10n.sharedPresenceLabel,
                    ),
                    items: PeerPresenceStatus.values
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(_presenceStatusLabel(context, status)),
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
                  Text(l10n.sharedPresenceHelp),
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
                    l10n.notificationPreferencesTitle,
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
                      title: Text(
                        _notificationPreferenceLabel(context, entry.key),
                      ),
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
                    l10n.keyboardShortcutsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final entry in shortcutService.shortcuts.entries)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_shortcutDescription(context, entry.key)),
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
                    l10n.appLockTitle,
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
                    title: Text(l10n.requireUnlockTitle),
                    subtitle: Text(l10n.requireUnlockSubtitle),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: appLockSettings.timeoutSeconds,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: l10n.relockAfterLabel,
                    ),
                    items: const [30, 60, 300, 600]
                        .map(
                          (seconds) => DropdownMenuItem(
                            value: seconds,
                            child: Text(
                              seconds < 60
                                  ? '$seconds ${seconds == 1 ? l10n.secondUnit : l10n.secondsUnit}'
                                  : '${seconds ~/ 60} ${(seconds ~/ 60) == 1 ? l10n.minuteUnit : l10n.minutesUnit}',
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
                    l10n.accessibilityTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${l10n.reducedMotionLabel}: ${A11yHelper.prefersReducedMotion(context) ? l10n.onValue : l10n.offValue}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.highContrastLabel}: ${A11yHelper.isHighContrast(context) ? l10n.onValue : l10n.offValue}',
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.accessibilitySummary),
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
                    l10n.burnAfterReadDefaultTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.burnAfterReadDefaultSubtitle),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Duration>(
                    initialValue: burnAfterReadDelay,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: l10n.burnAfterReadDelayLabel,
                      helperText: l10n.burnAfterReadDelayHelp,
                    ),
                    items: [
                      for (final option
                          in BurnAfterReadDelayPreferencesStorage.supportedDelays)
                        DropdownMenuItem<Duration>(
                          value: option,
                          child: Text(_burnAfterReadDelayLabel(context, option)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      unawaited(
                        ref
                            .read(burnAfterReadDelayProvider.notifier)
                            .setDelay(value),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: Text(l10n.antiSurveillanceGuardTitle),
              subtitle: Text(l10n.antiSurveillanceGuardSubtitle),
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

  String _burnAfterReadDelayLabel(BuildContext context, Duration delay) {
    final l10n = context.l10n;
    if (delay == Duration.zero) {
      return l10n.burnAfterReadDelayImmediate;
    }
    if (delay == const Duration(seconds: 5)) {
      return l10n.burnAfterReadDelay5Seconds;
    }
    if (delay == const Duration(seconds: 10)) {
      return l10n.burnAfterReadDelay10Seconds;
    }
    if (delay == const Duration(seconds: 30)) {
      return l10n.burnAfterReadDelay30Seconds;
    }
    if (delay == const Duration(minutes: 1)) {
      return l10n.burnAfterReadDelay1Minute;
    }
    if (delay == const Duration(minutes: 5)) {
      return l10n.burnAfterReadDelay5Minutes;
    }
    if (delay == const Duration(minutes: 10)) {
      return l10n.burnAfterReadDelay10Minutes;
    }
    return '${delay.inSeconds}s';
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
    final l10n = context.l10n;
    final templatesAsync = ref.watch(allQuickRepliesProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.quickReplyTemplatesTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _shortCodeController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.shortcodeLabel,
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
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.templateTextLabel,
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
                label: Text(l10n.saveTemplateAction),
              ),
            ),
          ),
          const SizedBox(height: 12),
          templatesAsync.when(
            data: (templates) {
              if (templates.isEmpty) {
                return Text(l10n.noQuickRepliesYet);
              }

              return Column(
                children: [
                  for (final template in templates)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('/${template.shortCode}'),
                      subtitle: Text(
                        '${template.content}\n${l10n.usedLabel} ${template.usageCount} ${template.usageCount == 1 ? l10n.timeSingular : l10n.timePlural}',
                      ),
                      isThreeLine: true,
                      trailing: ConstrainedBox(
                        constraints: A11yHelper.minimumTouchTarget,
                        child: IconButton(
                          tooltip: l10n.deleteTemplateTooltip,
                          onPressed: () => _deleteTemplate(template),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text(
              '${l10n.quickRepliesLoadFailedLabel}: $error',
            ),
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
        A11yHelper.announce(context.l10n.quickReplySavedLabel, context);
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
      A11yHelper.announce(context.l10n.quickReplyDeletedLabel, context);
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
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.customStatusTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLength: 80,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.statusTextLabel,
              hintText: l10n.statusTextHint,
            ),
            onChanged: (value) {
              unawaited(
                ref.read(customStatusTextProvider.notifier).setText(value),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(l10n.customStatusHelp),
        ],
      ),
    );
  }
}

extension on SettingsScreen {
  String _languageLabel(BuildContext context, AppLocaleMode mode) {
    final l10n = context.l10n;
    return switch (mode) {
      AppLocaleMode.system => l10n.languageSystem,
      AppLocaleMode.english => l10n.languageEnglish,
      AppLocaleMode.chineseSimplified => l10n.languageChineseSimplified,
      AppLocaleMode.chineseTraditional => l10n.languageChineseTraditional,
      AppLocaleMode.spanish => l10n.languageSpanish,
      AppLocaleMode.french => l10n.languageFrench,
    };
  }

  String _themeModeLabel(BuildContext context, AppThemeMode mode) {
    final l10n = context.l10n;
    return switch (mode) {
      AppThemeMode.auto => l10n.themeModeAuto,
      AppThemeMode.light => l10n.themeModeLight,
      AppThemeMode.dark => l10n.themeModeDark,
    };
  }

  String _presenceStatusLabel(BuildContext context, PeerPresenceStatus status) {
    final l10n = context.l10n;
    return switch (status) {
      PeerPresenceStatus.online => l10n.presenceOnline,
      PeerPresenceStatus.away => l10n.presenceAway,
      PeerPresenceStatus.hidden => l10n.presenceHidden,
    };
  }

  String _notificationPreferenceLabel(
    BuildContext context,
    NotificationPreferenceKey key,
  ) {
    final l10n = context.l10n;
    return switch (key) {
      NotificationPreferenceKey.messages => l10n.notificationMessages,
      NotificationPreferenceKey.calls => l10n.notificationCalls,
      NotificationPreferenceKey.presence => l10n.notificationPresenceChanges,
      NotificationPreferenceKey.connectionRequests =>
        l10n.notificationConnectionRequests,
      NotificationPreferenceKey.reactions => l10n.notificationReactions,
      NotificationPreferenceKey.sound => l10n.notificationSound,
      NotificationPreferenceKey.vibrate => l10n.notificationVibrate,
    };
  }

  String _shortcutDescription(BuildContext context, AppShortcutAction action) {
    final l10n = context.l10n;
    return switch (action) {
      AppShortcutAction.quickSearch => l10n.shortcutOpenQuickSearch,
      AppShortcutAction.cycleTheme => l10n.shortcutCycleThemeMode,
      AppShortcutAction.nextTab => l10n.shortcutNextTab,
      AppShortcutAction.previousTab => l10n.shortcutPreviousTab,
      AppShortcutAction.focusComposer => l10n.shortcutFocusComposer,
      AppShortcutAction.muteConversation => l10n.shortcutMuteConversation,
    };
  }
}
