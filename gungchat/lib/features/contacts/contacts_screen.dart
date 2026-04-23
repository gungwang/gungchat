import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/encryption/key_manager.dart';
import '../../models/contact.dart';
import 'contact_exchange_service.dart';
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

  Future<void> _importContactPayload() async {
    final payload = _importController.text.trim();
    if (payload.isEmpty) {
      _showSnack('Paste a contact payload before importing it.');
      return;
    }

    try {
      final contactCard =
          ref.read(contactExchangeServiceProvider).decodeContactCard(payload);
      ref.read(contactBookProvider.notifier).addOrUpdate(
            ref
                .read(contactExchangeServiceProvider)
                .contactFromCard(contactCard),
          );
      _importController.clear();
      _showSnack('Contact imported: ${contactCard.displayName}');
    } catch (error) {
      _showSnack('Contact import failed: $error');
    }
  }

  Future<void> _saveDiscoveredPeer(DiscoveryCandidate candidate) async {
    final exchangeService = ref.read(contactExchangeServiceProvider);

    if (candidate.contactPayload != null) {
      final contactCard =
          exchangeService.decodeContactCard(candidate.contactPayload!);
      ref.read(contactBookProvider.notifier).addOrUpdate(
            exchangeService.contactFromCard(contactCard).copyWith(
                  lastKnownAddress: '${candidate.host}:${candidate.port}',
                  lastSeenAt: DateTime.now(),
                  isLanDiscovered: true,
                ),
          );
    } else {
      ref.read(contactBookProvider.notifier).addOrUpdate(
            Contact(
              id: candidate.fingerprint ??
                  '${candidate.host}:${candidate.port}',
              displayName: candidate.displayName,
              fingerprint: candidate.fingerprint ?? 'unknown',
              lastKnownAddress: '${candidate.host}:${candidate.port}',
              lastSeenAt: DateTime.now(),
              isLanDiscovered: true,
            ),
          );
    }

    _showSnack('Saved ${candidate.displayName}');
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
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Discovery', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'Nearby LAN discovery and contact-card exchange are now wired for the next peer-connection loop.',
          ),
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
                              const SizedBox(height: 12),
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
                  Text(
                    'Import Contact',
                    style: theme.textTheme.titleMedium,
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
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _importContactPayload,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Import Contact'),
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
                          _SavedContactTile(contact: contact),
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
    required this.onCopyUri,
    this.onCopyPayload,
  });

  final DiscoveryCandidate candidate;
  final VoidCallback onSave;
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
            FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Save Contact'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SavedContactTile extends StatelessWidget {
  const _SavedContactTile({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(contact.displayName,
            style: Theme.of(context).textTheme.titleSmall),
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
        if (contact.isLanDiscovered) ...[
          const SizedBox(height: 8),
          const Chip(label: Text('LAN discovered')),
        ],
      ],
    );
  }
}
