import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/encryption/key_manager.dart';
import '../../core/networking/network_monitor.dart';
import '../../models/message.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _composerController = TextEditingController();
  bool _burnAfterRead = true;
  bool _sending = false;

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(DeviceIdentity identity) async {
    final text = _composerController.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final messageService = await ref.read(messageServiceProvider.future);
      await messageService.createLocalMessage(
        conversationId: bootstrapConversationId,
        senderId: identity.fingerprint,
        body: text,
        burnAfterRead: _burnAfterRead,
      );
      _composerController.clear();
      ref.invalidate(conversationMessagesProvider(bootstrapConversationId));
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
    final messagesAsync = ref.watch(
      conversationMessagesProvider(bootstrapConversationId),
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
              'Phase 1 is focused on identity, storage, encryption, and transport scaffolding.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _IdentityCard(identityAsync: identityAsync),
            const SizedBox(height: 12),
            _NetworkCard(networkAsync: networkAsync),
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
                            'No messages yet. Send a local bootstrap message to validate persistence and ephemeral defaults.',
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
                    loading: () => const Center(child: CircularProgressIndicator()),
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
                  children: [
                    TextField(
                      controller: _composerController,
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        labelText: 'Bootstrap message',
                        hintText: 'Type a local encrypted message draft...',
                        border: OutlineInputBorder(),
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
                      subtitle: const Text(
                        'Initial TTL is handled locally until peer session sync is added.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: identityAsync.asData == null || _sending
                            ? null
                            : () => _sendMessage(identityAsync.requireValue),
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: const Text('Save Local Message'),
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
                Text('Device identity', style: Theme.of(context).textTheme.titleMedium),
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
          error: (error, stackTrace) => Text('Identity bootstrap failed: $error'),
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
                Text('Network policy', style: Theme.of(context).textTheme.titleMedium),
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
