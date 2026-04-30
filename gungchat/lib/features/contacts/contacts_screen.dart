import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _importController = TextEditingController();

  bool _discovering = false;
  List<DiscoveryCandidate> _nearbyPeers = const [];

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
    _importController.dispose();
    super.dispose();
  }

  Future<void> _refreshLanPeers() async {
    if (_discovering) {
      return;
    }

    setState(() {
      _discovering = true;
    });

    try {
      final identity = await ref.read(deviceIdentityProvider.future);
      final peers = await ref.read(discoveryServiceProvider).discoverLanPeers(
            identity: identity,
            displayName: _resolvedDisplayName(identity),
          );
      if (mounted) {
        setState(() {
          _nearbyPeers = peers;
        });
      }
    } catch (error) {
      if (mounted) {
        _showSnack('LAN discovery failed: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _discovering = false;
        });
      }
    }
  }

  Future<void> _scanContactPayload() async {
    if (!_supportsQrScanning) {
      _showSnack('QR scanning is not available on Windows. Paste the contact payload instead.');
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

    _importController.text = scannedValue;
    await _importContactPayload(connect: true);
  }

  Future<void> _importContactPayload({
    bool openInChat = false,
    bool connect = false,
  }) async {
    final payload = _importController.text.trim();
    if (payload.isEmpty) {
      _showSnack('Paste a contact payload before importing it.');
      return;
    }

    try {
      final contactCard =
          ref.read(contactExchangeServiceProvider).decodeContactCard(payload);
      final contact =
          ref.read(contactExchangeServiceProvider).contactFromCard(contactCard);
      ref.read(contactBookProvider.notifier).addOrUpdate(contact);
      _importController.clear();
      if (connect && contact.lastKnownAddress != null) {
        _startConnectFlow(contact.fingerprint);
      } else if (openInChat || connect) {
        _openContactInChat(contact.fingerprint);
      }
      if (connect && contact.lastKnownAddress != null) {
        _showSnack(
          'Contact imported. Starting a LAN connection to ${contactCard.displayName}.',
        );
      } else if (connect) {
        _showSnack(
          'Contact imported, but no LAN address was included. Open the chat and use manual signaling.',
        );
      } else {
        _showSnack('Contact imported: ${contactCard.displayName}');
      }
    } catch (error) {
      _showSnack('Contact import failed: $error');
    }
  }

  Future<void> _saveDiscoveredPeer(
    DiscoveryCandidate candidate, {
    bool openInChat = false,
    bool connect = false,
  }) async {
    final contact = _contactFromDiscoveryCandidate(candidate);

    ref.read(contactBookProvider.notifier).addOrUpdate(contact);
    if (connect) {
      _startConnectFlow(contact.fingerprint);
    } else if (openInChat) {
      _openContactInChat(contact.fingerprint);
    }
    _showSnack('Saved ${candidate.displayName}');
  }

  Contact _contactFromDiscoveryCandidate(DiscoveryCandidate candidate) {
    final exchangeService = ref.read(contactExchangeServiceProvider);

    if (candidate.contactPayload != null) {
      final contactCard =
          exchangeService.decodeContactCard(candidate.contactPayload!);
      return exchangeService.contactFromCard(contactCard).copyWith(
            lastKnownAddress: '${candidate.host}:${candidate.port}',
            lastSeenAt: DateTime.now(),
            isLanDiscovered: true,
          );
    }

    return Contact(
      id: candidate.fingerprint ?? '${candidate.host}:${candidate.port}',
      displayName: candidate.displayName,
      fingerprint: candidate.fingerprint ?? 'unknown',
      lastKnownAddress: '${candidate.host}:${candidate.port}',
      lastSeenAt: DateTime.now(),
      isLanDiscovered: true,
    );
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

  Future<void> _copyText(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      _showSnack('$label copied');
    }
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
            'Nearby LAN discovery and QR contact exchange can hand off directly into the secure chat flow.',
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
                    'Shareable Identity',
                    style: theme.textTheme.titleMedium,
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
                              SelectableText(
                                payload,
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () =>
                                          _copyText('Contact payload', payload),
                                      icon: const Icon(Icons.copy_all_outlined),
                                      label: const Text('Copy QR Payload'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton.tonalIcon(
                                      onPressed: () => _copyText(
                                        'Fingerprint',
                                        card.fingerprint,
                                      ),
                                      icon: const Icon(Icons.badge_outlined),
                                      label: const Text('Copy Fingerprint'),
                                    ),
                                  ),
                                ],
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Import Contact',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      if (_supportsQrScanning)
                        IconButton(
                          tooltip: 'Scan contact QR',
                          onPressed: _scanContactPayload,
                          icon: const Icon(Icons.qr_code_scanner),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _importController,
                    maxLines: 4,
                    minLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Paste contact payload',
                      hintText: 'gungchat-contact:...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _importContactPayload,
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('Import Contact'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () =>
                              _importContactPayload(connect: true),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Import & Connect'),
                        ),
                      ),
                    ],
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Nearby Peers',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh LAN discovery',
                        onPressed: _discovering ? null : _refreshLanPeers,
                        icon: _discovering
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _discovering
                        ? 'Broadcasting a LAN probe and listening for nearby GungChat peers...'
                        : 'Tap refresh while both peers have Discovery open on the same network.',
                  ),
                  const SizedBox(height: 12),
                  if (_nearbyPeers.isEmpty)
                    const Text(
                      'No nearby peers discovered in this session yet.',
                    )
                  else
                    Column(
                      children: [
                        for (final peer in _nearbyPeers) ...[
                          _DiscoveryPeerTile(
                            candidate: peer,
                            onSave: () => _saveDiscoveredPeer(peer),
                            onOpenInChat: () =>
                                _saveDiscoveredPeer(peer, openInChat: true),
                            onConnect: () =>
                                _saveDiscoveredPeer(peer, connect: true),
                            onCopyUri: () => _copyText(
                              'Manual URI',
                              ref
                                  .read(discoveryServiceProvider)
                                  .buildManualConnectionUri(
                                    host: peer.host,
                                    port: peer.port,
                                    fingerprint: peer.fingerprint,
                                  )
                                  .toString(),
                            ),
                            onCopyPayload: peer.contactPayload == null
                                ? null
                                : () => _copyText(
                                      'Contact payload',
                                      peer.contactPayload!,
                                    ),
                          ),
                          if (peer != _nearbyPeers.last)
                            const Divider(height: 24),
                        ],
                      ],
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
                      'Imported or saved LAN contacts will appear here.',
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

class _DiscoveryPeerTile extends StatelessWidget {
  const _DiscoveryPeerTile({
    required this.candidate,
    required this.onSave,
    required this.onOpenInChat,
    required this.onConnect,
    required this.onCopyUri,
    this.onCopyPayload,
  });

  final DiscoveryCandidate candidate;
  final VoidCallback onSave;
  final VoidCallback onOpenInChat;
  final VoidCallback onConnect;
  final VoidCallback onCopyUri;
  final VoidCallback? onCopyPayload;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(candidate.displayName,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text('${candidate.host}:${candidate.port}'),
        if (candidate.fingerprint != null) ...[
          const SizedBox(height: 4),
          Text(candidate.fingerprint!),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: onCopyUri,
              icon: const Icon(Icons.link_outlined),
              label: const Text('Copy URI'),
            ),
            if (onCopyPayload != null)
              FilledButton.tonalIcon(
                onPressed: onCopyPayload,
                icon: const Icon(Icons.qr_code_2_outlined),
                label: const Text('Copy Payload'),
              ),
            FilledButton.tonalIcon(
              onPressed: onSave,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Save'),
            ),
            FilledButton.icon(
              onPressed: onOpenInChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Open In Chat'),
            ),
            FilledButton.icon(
              onPressed: onConnect,
              icon: const Icon(Icons.wifi_tethering_outlined),
              label: const Text('Connect'),
            ),
          ],
        ),
      ],
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
              onPressed: isBlocked ? null : onConnect,
              icon: const Icon(Icons.wifi_tethering_outlined),
              label: Text(isBlocked ? 'Blocked' : 'Connect'),
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
