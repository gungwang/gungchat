import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/encryption/key_manager.dart';
import '../../core/networking/network_monitor.dart';
import '../../core/networking/webrtc_manager.dart';
import '../../models/contact.dart';
import '../../models/message.dart';
import '../contacts/discovery_service.dart';
import 'peer_session_controller.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _composerController = TextEditingController();
  final TextEditingController _signalController = TextEditingController();
  bool _burnAfterRead = true;
  bool _sending = false;

  @override
  void dispose() {
    _composerController.dispose();
    _signalController.dispose();
    super.dispose();
  }

  Future<void> _copyText(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label copied')),
      );
    }
  }

  Future<void> _sendMessage(
      DeviceIdentity identity, Contact? selectedContact) async {
    final text = _composerController.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }

    final peerSession = ref.read(peerSessionControllerProvider);

    if (peerSession.isSessionActive && !peerSession.isTransportReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Finish the signal exchange before sending peer messages.'),
        ),
      );
      return;
    }

    if (selectedContact != null && !peerSession.isTransportReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Open or answer a session with ${selectedContact.displayName} before sending.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      if (peerSession.isTransportReady) {
        final sent = await ref
            .read(peerSessionControllerProvider.notifier)
            .sendMessage(body: text, burnAfterRead: _burnAfterRead);
        if (sent) {
          _composerController.clear();
        }
      } else {
        final messageService = await ref.read(messageServiceProvider.future);
        await messageService.createLocalMessage(
          conversationId: bootstrapConversationId,
          senderId: identity.fingerprint,
          body: text,
          burnAfterRead: _burnAfterRead,
        );
        _composerController.clear();
        ref.invalidate(conversationMessagesProvider(bootstrapConversationId));
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final identityAsync = ref.watch(deviceIdentityProvider);
    final networkAsync = ref.watch(networkStatusProvider);
    final peerSession = ref.watch(peerSessionControllerProvider);
    final savedContacts = ref.watch(contactBookProvider);
    final selectedContact = ref.watch(selectedContactProvider);

    final selectedConversationId = selectedContact == null
        ? null
        : conversationIdForFingerprint(selectedContact.fingerprint);
    final activeConversationId = peerSession.conversationId ??
        selectedConversationId ??
        bootstrapConversationId;

    final messagesAsync = ref.watch(
      conversationMessagesProvider(activeConversationId),
    );
    final canSendSecure = peerSession.isTransportReady;
    final canSaveLocal =
        selectedContact == null && !peerSession.isSessionActive;
    final composerEnabled = canSendSecure || canSaveLocal;
    final selectedUri = selectedContact?.lastKnownAddress == null
        ? null
        : ref.read(discoveryServiceProvider).buildManualConnectionUri(
              host: selectedContact!.lastKnownAddress!.split(':').first,
              port: int.tryParse(
                    selectedContact.lastKnownAddress!.split(':').last,
                  ) ??
                  DiscoveryService.discoveryPort,
              fingerprint: selectedContact.fingerprint,
            );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GungChat Bootstrap', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Manual signaling is now tied into saved contacts and QR/LAN exchange.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _IdentityCard(identityAsync: identityAsync),
            const SizedBox(height: 12),
            _NetworkCard(networkAsync: networkAsync),
            const SizedBox(height: 12),
            _ContactTargetCard(
              contacts: savedContacts,
              selectedContact: selectedContact,
              selectedUri: selectedUri?.toString(),
              onSelectContact: (fingerprint) {
                ref.read(selectedContactFingerprintProvider.notifier).state =
                    fingerprint;
              },
              onClearSelection: () {
                ref.read(selectedContactFingerprintProvider.notifier).state =
                    null;
              },
              onCopyUri: selectedUri == null
                  ? null
                  : () => _copyText('Manual URI', selectedUri.toString()),
            ),
            const SizedBox(height: 12),
            _PeerSessionCard(
              sessionState: peerSession,
              selectedContact: selectedContact,
              signalController: _signalController,
              onStartOffer: () async {
                await ref
                    .read(peerSessionControllerProvider.notifier)
                    .startOffer();
              },
              onApplySignal: () async {
                final signal = _signalController.text.trim();
                if (signal.isEmpty) {
                  return;
                }
                await ref
                    .read(peerSessionControllerProvider.notifier)
                    .applyRemoteSignal(signal);
                if (mounted &&
                    ref.read(peerSessionControllerProvider).lastError == null) {
                  _signalController.clear();
                }
              },
              onReset: () async {
                await ref
                    .read(peerSessionControllerProvider.notifier)
                    .resetSession();
                if (mounted) {
                  _signalController.clear();
                }
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: messagesAsync.when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            selectedContact == null &&
                                    peerSession.conversationId == null
                                ? 'No messages yet. Save a local bootstrap message or select a peer contact.'
                                : 'No messages yet for this peer. Finish signaling to start the secure conversation.',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _buildMessage(message);
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) {
                      return Center(child: Text('Message load failed: $error'));
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canSendSecure
                          ? 'Conversation: ${peerSession.remoteFingerprint ?? activeConversationId}'
                          : selectedContact != null
                              ? 'Conversation: ${selectedContact.displayName}'
                              : canSaveLocal
                                  ? 'Conversation: local bootstrap cache'
                                  : 'Conversation: waiting for secure channel',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _composerController,
                      maxLines: 3,
                      minLines: 1,
                      enabled: composerEnabled,
                      textInputAction: TextInputAction.send,
                      onSubmitted: identityAsync.asData == null ||
                              _sending ||
                              !composerEnabled
                          ? null
                          : (_) => _sendMessage(
                                identityAsync.requireValue,
                                selectedContact,
                              ),
                      decoration: InputDecoration(
                        labelText: canSendSecure
                            ? 'Secure peer message'
                            : canSaveLocal
                                ? 'Bootstrap message'
                                : 'Peer message',
                        hintText: canSendSecure
                            ? 'Type an encrypted message for the active peer session...'
                            : canSaveLocal
                                ? 'Type a local encrypted message draft...'
                                : 'Select a peer and complete the signal exchange to enable sending.',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _burnAfterRead,
                      onChanged: (value) {
                        setState(() {
                          _burnAfterRead = value;
                        });
                      },
                      title: const Text('Burn after read by default'),
                      subtitle: Text(
                        canSendSecure
                            ? 'Expiry metadata is sent with each encrypted peer message.'
                            : 'Initial TTL is handled locally until peer session sync is added.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: identityAsync.asData == null ||
                                _sending ||
                                !composerEnabled
                            ? null
                            : () => _sendMessage(
                                  identityAsync.requireValue,
                                  selectedContact,
                                ),
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          canSendSecure
                              ? 'Send Secure Message'
                              : canSaveLocal
                                  ? 'Save Local Message'
                                  : 'Wait For Secure Channel',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Message message) {
    return MessageBubble(message: message);
  }
}

class _ContactTargetCard extends StatelessWidget {
  const _ContactTargetCard({
    required this.contacts,
    required this.selectedContact,
    required this.onSelectContact,
    required this.onClearSelection,
    this.selectedUri,
    this.onCopyUri,
  });

  final List<Contact> contacts;
  final Contact? selectedContact;
  final ValueChanged<String> onSelectContact;
  final VoidCallback onClearSelection;
  final String? selectedUri;
  final VoidCallback? onCopyUri;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat Target', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (contacts.isEmpty)
              const Text(
                'No saved contacts yet. Import or discover a peer from the Contacts tab.',
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final contact in contacts)
                    ChoiceChip(
                      label: Text(contact.displayName),
                      selected:
                          selectedContact?.fingerprint == contact.fingerprint,
                      onSelected: (_) => onSelectContact(contact.fingerprint),
                    ),
                ],
              ),
            if (selectedContact != null) ...[
              const SizedBox(height: 12),
              Text(selectedContact!.fingerprint),
              if (selectedContact!.lastKnownAddress != null) ...[
                const SizedBox(height: 4),
                Text(selectedContact!.lastKnownAddress!),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onCopyUri != null && selectedUri != null)
                    FilledButton.tonalIcon(
                      onPressed: onCopyUri,
                      icon: const Icon(Icons.link_outlined),
                      label: const Text('Copy URI'),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: onClearSelection,
                    icon: const Icon(Icons.clear_outlined),
                    label: const Text('Clear'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PeerSessionCard extends StatelessWidget {
  const _PeerSessionCard({
    required this.sessionState,
    required this.signalController,
    required this.onStartOffer,
    required this.onApplySignal,
    required this.onReset,
    this.selectedContact,
  });

  final PeerSessionState sessionState;
  final Contact? selectedContact;
  final TextEditingController signalController;
  final Future<void> Function() onStartOffer;
  final Future<void> Function() onApplySignal;
  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ExpansionTile(
        initiallyExpanded:
            sessionState.isSessionActive || selectedContact != null,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text('Manual Peer Session'),
        subtitle: Text(_subtitleForState(sessionState, selectedContact)),
        trailing: _StateChip(state: sessionState),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (selectedContact != null)
                  Chip(label: Text('Target ${selectedContact!.displayName}')),
                if (sessionState.role != null)
                  Chip(
                    label: Text(
                      sessionState.role == PeerSessionRole.initiator
                          ? 'Offering'
                          : 'Answering',
                    ),
                  ),
                if (sessionState.remoteFingerprint != null)
                  Chip(label: Text(sessionState.remoteFingerprint!)),
                if (sessionState.pendingRemoteIceCount > 0)
                  Chip(
                    label: Text(
                      'Queued ICE ${sessionState.pendingRemoteIceCount}',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: signalController,
            maxLines: 5,
            minLines: 3,
            decoration: const InputDecoration(
              labelText: 'Paste remote offer, answer, or ICE payload',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onStartOffer,
                  icon: const Icon(Icons.outbox_outlined),
                  label: const Text('Start Offer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed:
                      sessionState.isApplyingSignal ? null : onApplySignal,
                  icon: sessionState.isApplyingSignal
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                  label: const Text('Apply Signal'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Reset session',
                onPressed: sessionState.isSessionActive ? onReset : null,
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          ),
          if (sessionState.lastError != null) ...[
            const SizedBox(height: 12),
            Text(
              sessionState.lastError!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (sessionState.lastEvent != null) ...[
            const SizedBox(height: 8),
            Text(
              sessionState.lastEvent!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (sessionState.sessionId != null) ...[
            const SizedBox(height: 12),
            Text(
              'Session ${sessionState.sessionId}',
              style: theme.textTheme.labelLarge,
            ),
          ],
          if (sessionState.localSignals.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Signals to share',
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sessionState.localSignals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final signal = sessionState.localSignals[index];
                  return _SignalTile(signal: signal);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _subtitleForState(
    PeerSessionState sessionState,
    Contact? selectedContact,
  ) {
    if (sessionState.isTransportReady) {
      return 'Secure channel open';
    }
    if (sessionState.isSessionActive) {
      return 'Exchange offer, answer, and ICE payloads';
    }
    if (selectedContact != null) {
      return 'Selected ${selectedContact.displayName}. Start an offer or answer their signal.';
    }
    return 'Select a contact or paste a remote offer to answer manually';
  }
}

class _SignalTile extends StatelessWidget {
  const _SignalTile({required this.signal});

  final ShareableSignal signal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(signal.label, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    signal.encoded,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Copy signal',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: signal.encoded));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${signal.label} copied')),
                  );
                }
              },
              icon: const Icon(Icons.copy_all_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});

  final PeerSessionState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, backgroundColor) = switch (state.connectionState) {
      WebRtcSessionState.open => ('Open', colorScheme.primaryContainer),
      WebRtcSessionState.connecting => (
          'Connecting',
          colorScheme.secondaryContainer,
        ),
      WebRtcSessionState.failed => ('Failed', colorScheme.errorContainer),
      WebRtcSessionState.disconnected => (
          'Offline',
          colorScheme.surfaceContainerHighest,
        ),
      WebRtcSessionState.closed => (
          'Closed',
          colorScheme.surfaceContainerHighest,
        ),
      WebRtcSessionState.idle => ('Idle', colorScheme.surfaceContainerHighest),
    };

    return Chip(
      label: Text(label),
      backgroundColor: backgroundColor,
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.identityAsync});

  final AsyncValue<DeviceIdentity> identityAsync;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: identityAsync.when(
          data: (identity) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device identity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Fingerprint: ${identity.fingerprint}'),
                const SizedBox(height: 4),
                const Text(
                  'X25519 key material is generated once and persisted in secure storage.',
                ),
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) =>
              Text('Identity bootstrap failed: $error'),
        ),
      ),
    );
  }
}

class _NetworkCard extends StatelessWidget {
  const _NetworkCard({required this.networkAsync});

  final AsyncValue<NetworkSnapshot> networkAsync;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: networkAsync.when(
          data: (snapshot) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Network policy',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(snapshot.summary),
                const SizedBox(height: 4),
                Text(
                  snapshot.prefersLan
                      ? 'LAN routing is available and should be preferred for P2P sessions.'
                      : 'Manual IP and TURN fallback can be layered on top of this monitor next.',
                ),
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => Text('Network monitor failed: $error'),
        ),
      ),
    );
  }
}
