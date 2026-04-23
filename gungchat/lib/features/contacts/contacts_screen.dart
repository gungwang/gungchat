import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/providers.dart';
import '../../core/encryption/key_manager.dart';
import '../../models/contact.dart';
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
    final scannedValue = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const ContactQrScannerScreen(),
      ),
    );

    if (!mounted || scannedValue == null || scannedValue.isEmpty) {
      return;
    }

    _importController.text = scannedValue;
    await _importContactPayload(openInChat: true);
  }

  Future<void> _importContactPayload({bool openInChat = false}) async {
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
      if (openInChat) {
        _openContactInChat(contact.fingerprint);
      }
      _showSnack('Contact imported: ${contactCard.displayName}');
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
    final value = _displayNameController.text.trim();
    if (value.isNotEmpty) {
      return value;
    }

    return 'GungChat ${identity.fingerprint.split(':').take(2).join()}';
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
    final selectedContact = ref.watch(selectedContactProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Discovery', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'Nearby LAN discovery, QR contact exchange, and direct handoff into chat are now wired together.',
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
                                        eyeShape: QrEyeShape.square,
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
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
                              _importContactPayload(openInChat: true),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Import To Chat'),
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
                            isSelected: selectedContact?.fingerprint ==
                                contact.fingerprint,
                            onOpenChat: () =>
                                _openContactInChat(contact.fingerprint),
                            onConnect: () =>
                                _startConnectFlow(contact.fingerprint),
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

class _SavedContactTile extends StatelessWidget {
  const _SavedContactTile({
    required this.contact,
    required this.isSelected,
    required this.onOpenChat,
    required this.onConnect,
  });

  final Contact contact;
  final bool isSelected;
  final VoidCallback onOpenChat;
  final VoidCallback onConnect;

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
              onPressed: onOpenChat,
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
