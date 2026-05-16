import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/providers.dart';
import '../../core/encryption/key_manager.dart';
import '../../models/contact.dart';
import '../../organization/label_service.dart';
import '../chat/peer_connect_intent.dart';
import 'contact_exchange_service.dart';
import 'contact_qr_scanner_screen.dart';
import 'discovery_service.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final TextEditingController _displayNameController = TextEditingController(
    text: 'GungChat',
  );

  bool get _supportsQrScanning {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _scanContactPayload() async {
    if (!_supportsQrScanning) {
      _showSnack(
        'QR scanning is not available on Windows. Use another GungChat device with a camera to scan this code.',
      );
      return;
    }

    final scannedValue = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const ContactQrScannerScreen(),
      ),
    );

    if (!mounted || scannedValue == null || scannedValue.isEmpty) {
      return;
    }

    await _connectFromPayload(scannedValue, trustImmediately: true);
  }

  Future<void> _connectFromPayload(
    String payload, {
    bool trustImmediately = false,
  }) async {
    final normalizedPayload = payload.trim();
    if (normalizedPayload.isEmpty) {
      _showSnack('Scan a GungChat QR code before trying to connect.');
      return;
    }

    try {
      final exchangeService = ref.read(contactExchangeServiceProvider);
      final contactCard =
          exchangeService.decodeContactCard(normalizedPayload);
      final contact = exchangeService.contactFromCard(
        contactCard,
        trustLevel: trustImmediately
            ? ContactTrustLevel.verified
            : ContactTrustLevel.unknown,
      );
      ref.read(contactBookProvider.notifier).addOrUpdate(contact);

      if (contact.lastKnownAddress == null) {
        _showSnack(
          'This QR code does not include a usable LAN address yet. Open the QR page on the other device again and rescan it.',
        );
        return;
      }

      _startConnectFlow(contact.fingerprint);
      _showSnack(
        trustImmediately
            ? 'Trusted ${contactCard.displayName}. Connecting automatically over LAN.'
            : 'Connecting automatically to ${contactCard.displayName}.',
      );
    } catch (error) {
      _showSnack('QR connection failed: $error');
    }
  }

  void _openContactInChat(String fingerprint) {
    ref.read(selectedContactFingerprintProvider.notifier).state = fingerprint;
    ref.read(navigationIndexProvider.notifier).state = 0;
  }

  void _startConnectFlow(String fingerprint) {
    if (ref.read(blockedContactsProvider).contains(fingerprint)) {
      _showSnack('Blocked contacts cannot start a peer session.');
      return;
    }

    ref.read(selectedContactFingerprintProvider.notifier).state = fingerprint;
    ref.read(pendingPeerConnectIntentProvider.notifier).state =
        PeerConnectIntent(fingerprint: fingerprint);
    ref.read(navigationIndexProvider.notifier).state = 0;
  }

  String _resolvedDisplayName(DeviceIdentity identity) {
    return ref.read(contactExchangeServiceProvider).resolveDisplayName(
          identity: identity,
          preferredDisplayName: _displayNameController.text,
        );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final identityAsync = ref.watch(deviceIdentityProvider);
    final savedContacts = ref.watch(contactBookProvider);
    final blockedContacts = ref.watch(blockedContactsProvider);
    final selectedContact = ref.watch(selectedContactProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Discovery', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'Scan once to establish trust. After the first QR exchange, both devices can reconnect with one tap.',
          ),
          if (selectedContact != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title:
                    Text('Active chat target: ${selectedContact.displayName}'),
                subtitle: Text(selectedContact.fingerprint),
                trailing: FilledButton.tonal(
                  onPressed: () =>
                      _openContactInChat(selectedContact.fingerprint),
                  child: const Text('Open'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: _ContactOrganizationCard(contact: selectedContact),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Connect QR',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Open this page on the other device and scan this QR code. GungChat will exchange identities and connect automatically over LAN.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  identityAsync.when(
                    data: (identity) {
                      return FutureBuilder<ContactCard>(
                        future: ref
                            .read(contactExchangeServiceProvider)
                            .buildLocalContactCard(
                              identity: identity,
                              displayName: _resolvedDisplayName(identity),
                              port: DiscoveryService.discoveryPort,
                            ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const LinearProgressIndicator();
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return Text(
                              'Contact card unavailable: ${snapshot.error}',
                            );
                          }

                          final card = snapshot.data!;
                          final payload = ref
                              .read(contactExchangeServiceProvider)
                              .buildQrReadyPayload(card);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fingerprint: ${card.fingerprint}'),
                              const SizedBox(height: 8),
                              Text(
                                card.addresses.isEmpty
                                    ? 'No LAN addresses detected yet.'
                                    : 'LAN addresses: ${card.addresses.join(', ')}',
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: QrImageView(
                                      data: payload,
                                      version: QrVersions.auto,
                                      size: 220,
                                      eyeStyle: const QrEyeStyle(
                                        color: Colors.black,
                                        eyeShape: QrEyeShape.square,
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        color: Colors.black,
                                        dataModuleShape:
                                            QrDataModuleShape.square,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Keep this QR visible until the other device finishes scanning and starts connecting.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stackTrace) =>
                        Text('Identity unavailable: $error'),
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
                    'Scan Peer QR',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _supportsQrScanning
                        ? 'Use this device camera to scan the other GungChat QR code. The first scan creates a trusted connection automatically.'
                        : 'This device cannot scan QR codes. Use another GungChat device with a camera to scan this QR code and complete the first trust exchange.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _supportsQrScanning ? _scanContactPayload : null,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(
                      _supportsQrScanning
                          ? 'Scan QR and Connect'
                          : 'Scan on Another Device',
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
                    'Saved Contacts',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (savedContacts.isEmpty)
                    const Text(
                      'Trusted devices appear here after the first QR scan.',
                    )
                  else
                    Column(
                      children: [
                        for (final contact in savedContacts) ...[
                          _SavedContactTile(
                            contact: contact,
                            isBlocked:
                              blockedContacts.contains(contact.fingerprint),
                            isSelected: selectedContact?.fingerprint ==
                                contact.fingerprint,
                            onManage: () {
                              ref
                                  .read(selectedContactFingerprintProvider.notifier)
                                  .state = contact.fingerprint;
                            },
                            onOpenChat: () =>
                                _openContactInChat(contact.fingerprint),
                            onConnect: () =>
                                _startConnectFlow(contact.fingerprint),
                            onToggleBlocked: () async {
                              final isBlocked = ref
                                .read(blockedContactsProvider)
                                .contains(contact.fingerprint);
                              if (isBlocked) {
                              await ref
                                .read(blockedContactsProvider.notifier)
                                .unblockContact(contact.fingerprint);
                              _showSnack('Unblocked ${contact.displayName}.');
                              } else {
                              await ref
                                .read(blockedContactsProvider.notifier)
                                .blockContact(contact.fingerprint);
                              final peerSession =
                                ref.read(peerSessionControllerProvider);
                              if (peerSession.remoteFingerprint ==
                                  contact.fingerprint ||
                                peerSession.expectedRemoteFingerprint ==
                                  contact.fingerprint) {
                                await ref
                                  .read(peerSessionControllerProvider.notifier)
                                  .resetSession();
                              }
                              _showSnack('Blocked ${contact.displayName}.');
                              }
                            },
                          ),
                          if (contact != savedContacts.last)
                            const Divider(height: 24),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactOrganizationCard extends ConsumerStatefulWidget {
  const _ContactOrganizationCard({required this.contact});

  final Contact contact;

  @override
  ConsumerState<_ContactOrganizationCard> createState() =>
      _ContactOrganizationCardState();
}

class _ContactOrganizationCardState
    extends ConsumerState<_ContactOrganizationCard> {
  static const Map<String, String> _labelColors = <String, String>{
    'Forest': '#4A7C59',
    'Amber': '#C98218',
    'Sky': '#2F6FED',
    'Rose': '#B94A72',
    'Slate': '#5C677D',
  };

  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedColorHex = '#4A7C59';
  bool _savingLabel = false;
  bool _savingNote = false;

  @override
  void dispose() {
    _labelController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactId = widget.contact.fingerprint;
    final allLabelsAsync = ref.watch(allConversationLabelsProvider);
    final selectedLabelsAsync = ref.watch(conversationLabelsProvider(contactId));
    final notesAsync = ref.watch(contactNotesProvider(contactId));
    final muteStateAsync = ref.watch(conversationMuteStateProvider(contactId));
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Organization',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text('Manage labels, private notes, and notification state for this contact.'),
          const SizedBox(height: 16),
          Text('Labels', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          allLabelsAsync.when(
            data: (allLabels) {
              return selectedLabelsAsync.when(
                data: (selectedLabels) {
                  final selectedIds = selectedLabels
                      .map((label) => label.id)
                      .toSet();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (allLabels.isEmpty)
                        const Text('No labels created yet.')
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final label in allLabels)
                              FilterChip(
                                selected: selectedIds.contains(label.id),
                                label: Text(label.name),
                                onSelected: (_) => unawaited(
                                  _toggleLabel(
                                    label: label,
                                    isSelected: selectedIds.contains(label.id),
                                  ),
                                ),
                                selectedColor: _colorFromHex(label.colorHex)
                                    .withValues(alpha: 0.22),
                                side: BorderSide(
                                  color: _colorFromHex(label.colorHex),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _labelController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'New label',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          DropdownButton<String>(
                            value: _selectedColorHex,
                            items: _labelColors.entries
                                .map(
                                  (entry) => DropdownMenuItem<String>(
                                    value: entry.value,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: _colorFromHex(entry.value),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(entry.key),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _selectedColorHex = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonalIcon(
                          onPressed: _savingLabel ? null : _createAndAssignLabel,
                          icon: _savingLabel
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add),
                          label: const Text('Create label'),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('Could not load selected labels: $error'),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Could not load labels: $error'),
          ),
          const SizedBox(height: 16),
          Text('Private notes', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          notesAsync.when(
            data: (notes) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notes.isEmpty)
                    const Text('No private notes for this contact yet.')
                  else
                    for (final note in notes)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(note.content),
                        subtitle: Text('Updated ${note.updatedAt}'),
                        trailing: IconButton(
                          tooltip: 'Delete note',
                          onPressed: () => unawaited(_deleteNote(note.id)),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                  TextField(
                    controller: _noteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Add private note',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      onPressed: _savingNote ? null : _addNote,
                      icon: _savingNote
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.note_add_outlined),
                      label: const Text('Save note'),
                    ),
                  ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Could not load notes: $error'),
          ),
          const SizedBox(height: 16),
          Text('Notifications', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          muteStateAsync.when(
            data: (settings) {
              final now = DateTime.now();
              final isSnoozed = settings.isSnoozedAt(now);
              final statusText = settings.muted
                  ? 'Muted until you manually unmute it.'
                  : isSnoozed
                      ? 'Snoozed until ${settings.snoozedUntil}. '
                      : 'Notifications are active for this contact.';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusText),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: settings.muted ? null : _muteContact,
                        icon: const Icon(Icons.notifications_off_outlined),
                        label: const Text('Mute'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _unmuteContact,
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: const Text('Unmute'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _snoozeContact(const Duration(hours: 1)),
                        icon: const Icon(Icons.snooze_outlined),
                        label: const Text('Snooze 1h'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _snoozeContact(const Duration(hours: 8)),
                        icon: const Icon(Icons.bedtime_outlined),
                        label: const Text('Snooze 8h'),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Could not load mute settings: $error'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLabel({
    required ConversationLabel label,
    required bool isSelected,
  }) async {
    final service = await ref.read(labelServiceProvider.future);
    final contactId = widget.contact.fingerprint;
    if (isSelected) {
      await service.removeLabelFromConversation(contactId, label.id);
    } else {
      await service.addLabelToConversation(contactId, label.id);
    }
    ref.invalidate(conversationLabelsProvider(contactId));
  }

  Future<void> _createAndAssignLabel() async {
    final name = _labelController.text.trim();
    if (name.isEmpty) {
      return;
    }

    setState(() {
      _savingLabel = true;
    });

    try {
      final service = await ref.read(labelServiceProvider.future);
      final label = await service.createLabel(name, _selectedColorHex);
      await service.addLabelToConversation(widget.contact.fingerprint, label.id);
      _labelController.clear();
      ref.invalidate(allConversationLabelsProvider);
      ref.invalidate(conversationLabelsProvider(widget.contact.fingerprint));
    } finally {
      if (mounted) {
        setState(() {
          _savingLabel = false;
        });
      }
    }
  }

  Future<void> _addNote() async {
    final noteText = _noteController.text.trim();
    if (noteText.isEmpty) {
      return;
    }

    setState(() {
      _savingNote = true;
    });

    try {
      final service = await ref.read(contactNotesServiceProvider.future);
      await service.addNote(widget.contact.fingerprint, noteText);
      _noteController.clear();
      ref.invalidate(contactNotesProvider(widget.contact.fingerprint));
    } finally {
      if (mounted) {
        setState(() {
          _savingNote = false;
        });
      }
    }
  }

  Future<void> _deleteNote(String noteId) async {
    final service = await ref.read(contactNotesServiceProvider.future);
    await service.deleteNote(noteId);
    ref.invalidate(contactNotesProvider(widget.contact.fingerprint));
  }

  Future<void> _muteContact() async {
    final service = await ref.read(conversationMuteServiceProvider.future);
    await service.mute(widget.contact.fingerprint);
    ref.invalidate(conversationMuteStateProvider(widget.contact.fingerprint));
  }

  Future<void> _unmuteContact() async {
    final service = await ref.read(conversationMuteServiceProvider.future);
    await service.unmute(widget.contact.fingerprint);
    ref.invalidate(conversationMuteStateProvider(widget.contact.fingerprint));
  }

  Future<void> _snoozeContact(Duration duration) async {
    final service = await ref.read(conversationMuteServiceProvider.future);
    await service.snoozeUntil(
      widget.contact.fingerprint,
      DateTime.now().add(duration),
    );
    ref.invalidate(conversationMuteStateProvider(widget.contact.fingerprint));
  }

  Color _colorFromHex(String hex) {
    final normalized = hex.replaceFirst('#', '');
    final buffer = StringBuffer();
    if (normalized.length == 6) {
      buffer.write('ff');
    }
    buffer.write(normalized);
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class _SavedContactTile extends StatelessWidget {
  const _SavedContactTile({
    required this.contact,
    required this.isBlocked,
    required this.isSelected,
    required this.onManage,
    required this.onOpenChat,
    required this.onConnect,
    required this.onToggleBlocked,
  });

  final Contact contact;
  final bool isBlocked;
  final bool isSelected;
  final VoidCallback onManage;
  final VoidCallback onOpenChat;
  final VoidCallback onConnect;
  final VoidCallback onToggleBlocked;

  @override
  Widget build(BuildContext context) {
    final isTrusted = contact.trustLevel == ContactTrustLevel.verified;
    final canConnect =
        !isBlocked && isTrusted && contact.lastKnownAddress != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                contact.displayName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (isTrusted) const Chip(label: Text('Trusted')),
            if (isBlocked) const Chip(label: Text('Blocked')),
            if (isSelected) const Chip(label: Text('Selected')),
          ],
        ),
        const SizedBox(height: 4),
        Text(contact.fingerprint),
        if (contact.lastKnownAddress != null) ...[
          const SizedBox(height: 4),
          Text(contact.lastKnownAddress!),
        ],
        if (contact.lastSeenAt != null) ...[
          const SizedBox(height: 4),
          Text('Seen ${contact.lastSeenAt}'),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (contact.isLanDiscovered)
              const Chip(label: Text('LAN discovered')),
            if (!isTrusted) const Chip(label: Text('Scan QR first')),
            FilledButton.tonalIcon(
              onPressed: onManage,
              icon: const Icon(Icons.label_outline),
              label: const Text('Manage'),
            ),
            FilledButton.tonalIcon(
              onPressed: onOpenChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Open In Chat'),
            ),
            FilledButton.icon(
              onPressed: canConnect ? onConnect : null,
              icon: const Icon(Icons.wifi_tethering_outlined),
              label: Text(
                isBlocked
                    ? 'Blocked'
                    : canConnect
                        ? 'Connect'
                        : 'Needs QR',
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onToggleBlocked,
              icon: Icon(isBlocked ? Icons.lock_open : Icons.block),
              label: Text(isBlocked ? 'Unblock' : 'Block'),
            ),
          ],
        ),
      ],
    );
  }
}
