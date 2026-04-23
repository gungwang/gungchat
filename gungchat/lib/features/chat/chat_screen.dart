import 'dart:async';

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
import 'pending_peer_input.dart';
import 'peer_connect_intent.dart';
import 'peer_invitation_builder.dart';
import 'peer_invitation_parser.dart';
import 'peer_session_controller.dart';
import 'presence_status.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _composerController = TextEditingController();
  final TextEditingController _signalController = TextEditingController();
  final Set<String> _markingReadMessageIds = <String>{};
  final Map<String, GlobalKey> _messageKeys = <String, GlobalKey>{};
  Message? _replyingToMessage;
  Timer? _highlightClearTimer;
  String? _highlightedMessageId;
  bool _burnAfterRead = true;
  bool _sending = false;

  @override
  void dispose() {
    _highlightClearTimer?.cancel();
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

  void _startReply(Message message) {
    setState(() {
      _replyingToMessage = message;
    });
  }

  GlobalKey _messageKeyFor(String messageId) {
    return _messageKeys.putIfAbsent(messageId, GlobalKey.new);
  }

  void _highlightMessage(String messageId) {
    _highlightClearTimer?.cancel();
    setState(() {
      _highlightedMessageId = messageId;
    });
    _highlightClearTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || _highlightedMessageId != messageId) {
        return;
      }
      setState(() {
        _highlightedMessageId = null;
      });
    });
  }

  Future<void> _jumpToQuotedMessage({
    required Message message,
    required List<Message> messages,
  }) async {
    final targetMessageId = message.replyToMessageId;
    if (targetMessageId == null) {
      return;
    }

    final existsInConversation = messages.any(
      (candidate) => candidate.id == targetMessageId,
    );
    if (!existsInConversation) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The original message is no longer available.'),
          ),
        );
      }
      return;
    }

    final targetContext = _messageKeyFor(targetMessageId).currentContext;
    if (targetContext == null) {
      return;
    }

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );

    if (!mounted) {
      return;
    }
    _highlightMessage(targetMessageId);
  }

  void _clearReplyTarget() {
    if (_replyingToMessage == null) {
      return;
    }

    setState(() {
      _replyingToMessage = null;
    });
  }

  String _replyPreviewText(String body) {
    final compact = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 96) {
      return compact;
    }
    return '${compact.substring(0, 96)}...';
  }

  Future<void> _copyInvitationDraft(
    PeerInvitationDraft draft,
    Contact? selectedContact,
  ) async {
    await _copyText(draft.copyActionLabel, draft.clipboardText);
    ref.read(peerSessionControllerProvider.notifier).recordHistory(
          title: draft.kind == PeerInvitationDraftKind.reply
              ? 'Reply copied'
              : 'Invite copied',
          detail: selectedContact == null
              ? 'Clipboard bundle is ready to send.'
              : 'Clipboard bundle is ready for ${selectedContact.displayName}.',
          direction: PeerSessionHistoryDirection.outgoing,
          action: PeerSessionHistoryAction(
            kind: PeerSessionHistoryActionKind.copy,
            label: draft.kind == PeerInvitationDraftKind.reply
                ? 'Copy Reply Again'
                : 'Copy Invite Again',
            payload: draft.clipboardText,
          ),
        );
  }

  Future<void> _copyInvitationLink(
    Uri invitationLink,
    PeerInvitationDraft draft,
  ) async {
    await _copyText('Deep link', invitationLink.toString());
    ref.read(peerSessionControllerProvider.notifier).recordHistory(
          title: draft.kind == PeerInvitationDraftKind.reply
              ? 'Reply link copied'
              : 'Invite link copied',
          detail: 'Ready to reopen in GungChat on the peer device.',
          direction: PeerSessionHistoryDirection.outgoing,
          action: PeerSessionHistoryAction(
            kind: PeerSessionHistoryActionKind.copy,
            label: 'Copy Link Again',
            payload: invitationLink.toString(),
          ),
        );
  }

  Future<void> _handleHistoryAction(PeerSessionHistoryAction action) async {
    switch (action.kind) {
      case PeerSessionHistoryActionKind.copy:
        await Clipboard.setData(ClipboardData(text: action.payload));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Timeline entry copied.')),
          );
        }
      case PeerSessionHistoryActionKind.apply:
        _signalController.text = action.payload;
        await _applyImportedTextValue(
          action.payload,
          selectedContact: ref.read(selectedContactProvider),
        );
    }
  }

  Future<void> _markVisibleMessagesRead({
    required String conversationId,
    required List<Message> messages,
    required bool sendReceipt,
  }) async {
    final unreadIncomingIds = messages
        .where(
          (message) =>
              !message.isOutgoing &&
              message.deliveryState == MessageDeliveryState.delivered &&
              !_markingReadMessageIds.contains(message.id),
        )
        .map((message) => message.id)
        .toList(growable: false);
    if (unreadIncomingIds.isEmpty) {
      return;
    }

    _markingReadMessageIds.addAll(unreadIncomingIds);
    try {
      await ref.read(peerSessionControllerProvider.notifier).markMessagesRead(
            conversationId: conversationId,
            messageIds: unreadIncomingIds,
            sendReceipt: sendReceipt,
          );
    } finally {
      _markingReadMessageIds.removeAll(unreadIncomingIds);
    }
  }

  Future<void> _sendMessage(
    DeviceIdentity identity,
    Contact? selectedContact, {
    Message? replyingToMessage,
  }) async {
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
            .sendMessage(
              body: text,
              burnAfterRead: _burnAfterRead,
              replyToMessageId: replyingToMessage?.id,
              replyToBody: replyingToMessage?.body,
            );
        if (sent) {
          _composerController.clear();
          _clearReplyTarget();
        }
      } else {
        final messageService = await ref.read(messageServiceProvider.future);
        await messageService.createLocalMessage(
          conversationId: bootstrapConversationId,
          senderId: identity.fingerprint,
          body: text,
          burnAfterRead: _burnAfterRead,
          replyToMessageId: replyingToMessage?.id,
          replyToBody: replyingToMessage?.body,
        );
        _composerController.clear();
        _clearReplyTarget();
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

  String _typingPeerLabel(
    PeerSessionState sessionState,
    Contact? selectedContact,
  ) {
    final remoteFingerprint = sessionState.remoteFingerprint;
    if (selectedContact != null &&
        (remoteFingerprint == null ||
            selectedContact.fingerprint == remoteFingerprint ||
            conversationIdForFingerprint(selectedContact.fingerprint) ==
                sessionState.conversationId)) {
      return selectedContact.displayName;
    }

    return remoteFingerprint ?? 'Peer';
  }

  Future<void> _consumeConnectIntent(PeerConnectIntent intent) async {
    ref.read(pendingPeerConnectIntentProvider.notifier).state = null;

    Contact? contact;
    for (final candidate in ref.read(contactBookProvider)) {
      if (candidate.fingerprint == intent.fingerprint) {
        contact = candidate;
        break;
      }
    }

    if (contact == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find that contact to start a connection.'),
          ),
        );
      }
      return;
    }

    ref.read(selectedContactFingerprintProvider.notifier).state =
        contact.fingerprint;

    if (intent.autoStartOffer) {
      await ref
          .read(peerSessionControllerProvider.notifier)
          .startOffer(targetContact: contact);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connect flow prepared for ${contact.displayName}. Copy the invite once the offer is ready.',
          ),
        ),
      );
    }
  }

  Future<void> _applyImportedText(Contact? selectedContact) async {
    await _applyImportedTextValue(
      _signalController.text.trim(),
      selectedContact: selectedContact,
    );
  }

  Future<void> _applyImportedTextValue(
    String rawValue, {
    required Contact? selectedContact,
    PeerInputSource? source,
  }) async {
    if (rawValue.isEmpty) {
      return;
    }

    final maybeUri = Uri.tryParse(rawValue);
    if (maybeUri != null) {
      final resolvedDeepLink =
          ref.read(peerDeepLinkServiceProvider).resolve(maybeUri);
      if (resolvedDeepLink != null) {
        await _applyImportedTextValue(
          resolvedDeepLink.rawInput,
          selectedContact: selectedContact,
          source: PeerInputSource.deepLink,
        );
        return;
      }
    }

    final parser = ref.read(peerInvitationParserProvider);
    ParsedPeerInvitation? parsedInvitation;

    try {
      parsedInvitation = parser.parse(rawValue);
    } on FormatException {
      parsedInvitation = null;
    }

    if (parsedInvitation == null) {
      await ref.read(peerSessionControllerProvider.notifier).applyRemoteSignal(
            rawValue,
            targetContact: selectedContact,
          );
      if (ref.read(peerSessionControllerProvider).lastError == null) {
        ref.read(peerSessionControllerProvider.notifier).recordHistory(
              title: 'Raw signal imported',
              detail: source == null
                  ? 'Applied from the chat input field.'
                  : 'Applied from ${_sourceLabel(source)}.',
              direction: PeerSessionHistoryDirection.incoming,
            );
      }
      if (mounted &&
          ref.read(peerSessionControllerProvider).lastError == null) {
        _signalController.clear();
      }
      return;
    }

    Contact? targetContact = selectedContact;
    final importedContact = parsedInvitation.toContact();
    if (importedContact != null) {
      ref.read(contactBookProvider.notifier).addOrUpdate(importedContact);
      ref.read(selectedContactFingerprintProvider.notifier).state =
          importedContact.fingerprint;
      targetContact = importedContact;
    }

    final controller = ref.read(peerSessionControllerProvider.notifier);
    switch (parsedInvitation.kind) {
      case PeerInvitationKind.invite:
        final offerSignal = parsedInvitation.offerSignal;
        if (offerSignal == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This invite does not contain an offer payload.'),
              ),
            );
          }
          return;
        }

        await controller.applyRemoteSignal(
          offerSignal,
          targetContact: targetContact,
        );
        for (final iceSignal in parsedInvitation.iceSignals) {
          await controller.applyRemoteSignal(
            iceSignal,
            targetContact: targetContact,
          );
        }

        if (ref.read(peerSessionControllerProvider).lastError == null) {
          controller.recordHistory(
            title: 'Invite imported',
            detail: source == null
                ? 'Offer bundle applied from the chat input field.'
                : 'Offer bundle applied from ${_sourceLabel(source)}.',
            direction: PeerSessionHistoryDirection.incoming,
          );
        }

        if (mounted &&
            ref.read(peerSessionControllerProvider).lastError == null) {
          _signalController.clear();
          final contactLabel = targetContact?.displayName ?? 'peer';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Invite imported for $contactLabel. Copy the reply bundle back to the sender.',
              ),
            ),
          );
        }
      case PeerInvitationKind.reply:
        final answerSignal = parsedInvitation.answerSignal;
        if (answerSignal == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This reply does not contain an answer payload.'),
              ),
            );
          }
          return;
        }

        await controller.applyRemoteSignal(
          answerSignal,
          targetContact: targetContact,
        );
        for (final iceSignal in parsedInvitation.iceSignals) {
          await controller.applyRemoteSignal(
            iceSignal,
            targetContact: targetContact,
          );
        }

        if (ref.read(peerSessionControllerProvider).lastError == null) {
          controller.recordHistory(
            title: 'Reply imported',
            detail: source == null
                ? 'Answer bundle applied from the chat input field.'
                : 'Answer bundle applied from ${_sourceLabel(source)}.',
            direction: PeerSessionHistoryDirection.incoming,
          );
        }

        if (mounted &&
            ref.read(peerSessionControllerProvider).lastError == null) {
          _signalController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Reply imported. The secure channel should finish connecting once ICE exchange completes.',
              ),
            ),
          );
        }
    }
  }

  Future<void> _consumePeerInput(PendingPeerInput input) async {
    ref.read(pendingPeerInputProvider.notifier).state = null;
    _signalController.text = input.rawValue;
    await _applyImportedTextValue(
      input.rawValue,
      selectedContact: ref.read(selectedContactProvider),
      source: input.source,
    );
  }

  String _sourceLabel(PeerInputSource source) {
    switch (source) {
      case PeerInputSource.deepLink:
        return 'deep link';
      case PeerInputSource.clipboard:
        return 'clipboard';
    }
  }

  Future<void> _pasteInviteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clipboard is empty or does not contain invite text.'),
          ),
        );
      }
      return;
    }

    ref.read(pendingPeerInputProvider.notifier).state = PendingPeerInput(
      rawValue: text,
      source: PeerInputSource.clipboard,
      receivedAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PendingPeerInput?>(pendingPeerInputProvider, (previous, next) {
      if (next == null) {
        return;
      }
      unawaited(_consumePeerInput(next));
    });

    ref.listen<PeerConnectIntent?>(pendingPeerConnectIntentProvider,
        (previous, next) {
      if (next == null) {
        return;
      }
      unawaited(_consumeConnectIntent(next));
    });

    final theme = Theme.of(context);
    final identityAsync = ref.watch(deviceIdentityProvider);
    final networkAsync = ref.watch(networkStatusProvider);
    final peerSession = ref.watch(peerSessionControllerProvider);
    final savedContacts = ref.watch(contactBookProvider);
    final selectedContact = ref.watch(selectedContactProvider);
    final readReceiptsEnabled = ref.watch(readReceiptsEnabledProvider);

    final selectedConversationId = selectedContact == null
        ? null
        : conversationIdForFingerprint(selectedContact.fingerprint);
    final activeConversationId = peerSession.conversationId ??
        selectedConversationId ??
        bootstrapConversationId;
    final replyingToMessage = _replyingToMessage?.conversationId ==
        activeConversationId
      ? _replyingToMessage
      : null;

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
    final invitationDraft = selectedContact == null
        ? null
        : ref.read(peerInvitationBuilderProvider).build(
              contact: selectedContact,
              sessionState: peerSession,
              manualUri: selectedUri?.toString(),
            );
    final invitationLink = invitationDraft == null ||
        !invitationDraft.hasReadyBundle
        ? null
        : ref
            .read(peerDeepLinkServiceProvider)
            .buildInputUri(invitationDraft.clipboardText);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GungChat Bootstrap', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Invite import, deep links, saved contacts, and manual signaling now feed the same peer session flow.',
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
                ref.read(pendingPeerConnectIntentProvider.notifier).state =
                    null;
                _highlightClearTimer?.cancel();
                setState(() {
                  _replyingToMessage = null;
                  _highlightedMessageId = null;
                });
              },
              onCopyUri: selectedUri == null
                  ? null
                  : () => _copyText('Manual URI', selectedUri.toString()),
              onConnect: selectedContact == null
                  ? null
                  : () {
                      ref
                          .read(pendingPeerConnectIntentProvider.notifier)
                          .state = PeerConnectIntent(
                        fingerprint: selectedContact.fingerprint,
                      );
                    },
            ),
            const SizedBox(height: 12),
            _PeerSessionCard(
              sessionState: peerSession,
              selectedContact: selectedContact,
              invitationDraft: invitationDraft,
              signalController: _signalController,
              onStartOffer: () async {
                await ref
                    .read(peerSessionControllerProvider.notifier)
                    .startOffer(targetContact: selectedContact);
              },
              onApplySignal: () async {
                await _applyImportedText(selectedContact);
              },
              onReset: () async {
                await ref
                    .read(peerSessionControllerProvider.notifier)
                    .resetSession();
                if (mounted) {
                  _signalController.clear();
                  _highlightClearTimer?.cancel();
                  setState(() {
                    _replyingToMessage = null;
                    _highlightedMessageId = null;
                  });
                }
              },
              onConnect: selectedContact == null
                  ? null
                  : () async {
                      ref
                          .read(pendingPeerConnectIntentProvider.notifier)
                          .state = PeerConnectIntent(
                        fingerprint: selectedContact.fingerprint,
                      );
                    },
              onCopyInvitation: invitationDraft == null ||
                      !invitationDraft.hasReadyBundle
                  ? null
                  : () => _copyInvitationDraft(
                        invitationDraft,
                        selectedContact,
                      ),
              onCopyLink: invitationLink == null || invitationDraft == null
                  ? null
                  : () => _copyInvitationLink(
                        invitationLink,
                        invitationDraft,
                      ),
              onPasteInvite: _pasteInviteFromClipboard,
              onHistoryAction: _handleHistoryAction,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: messagesAsync.when(
                    data: (messages) {
                      if (activeConversationId != bootstrapConversationId) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) {
                            return;
                          }
                          unawaited(
                            _markVisibleMessagesRead(
                              conversationId: activeConversationId,
                              messages: messages,
                              sendReceipt:
                                  readReceiptsEnabled && peerSession.isTransportReady,
                            ),
                          );
                        });
                      }

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

                      return ListView(
                        children: [
                          for (final message in messages)
                            _buildMessage(message, messages),
                        ],
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
                    if (peerSession.remotePresenceStatus != null &&
                        peerSession.remotePresenceStatus !=
                            PeerPresenceStatus.hidden) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Peer status: ${peerSession.remotePresenceStatus!.label}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (replyingToMessage != null) ...[
                      const SizedBox(height: 12),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      replyingToMessage.isOutgoing
                                          ? 'Replying to yourself'
                                          : 'Replying to peer',
                                      style: theme.textTheme.labelLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _replyPreviewText(replyingToMessage.body),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Cancel reply',
                                onPressed: _clearReplyTarget,
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _composerController,
                      maxLines: 3,
                      minLines: 1,
                      enabled: composerEnabled,
                      onChanged: canSendSecure
                          ? (value) {
                              ref
                                  .read(peerSessionControllerProvider.notifier)
                                  .updateComposerActivity(value);
                            }
                          : null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: identityAsync.asData == null ||
                              _sending ||
                              !composerEnabled
                          ? null
                          : (_) => _sendMessage(
                                identityAsync.requireValue,
                                selectedContact,
                              replyingToMessage: replyingToMessage,
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
                    if (peerSession.isRemoteTyping) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_typingPeerLabel(peerSession, selectedContact)} is typing...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
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
                                  replyingToMessage: replyingToMessage,
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

  Widget _buildMessage(Message message, List<Message> messages) {
    return MessageBubble(
      key: _messageKeyFor(message.id),
      message: message,
      isHighlighted: _highlightedMessageId == message.id,
      onReply: message.type == MessageType.system
          ? null
          : () => _startReply(message),
      onQuotedMessageTap: message.replyToMessageId == null
          ? null
          : () => _jumpToQuotedMessage(
                message: message,
                messages: messages,
              ),
    );
  }
}

class _ContactTargetCard extends StatelessWidget {
  const _ContactTargetCard({
    required this.contacts,
    required this.selectedContact,
    required this.onSelectContact,
    required this.onClearSelection,
    required this.onConnect,
    this.selectedUri,
    this.onCopyUri,
  });

  final List<Contact> contacts;
  final Contact? selectedContact;
  final ValueChanged<String> onSelectContact;
  final VoidCallback onClearSelection;
  final VoidCallback? onConnect;
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
                  FilledButton.icon(
                    onPressed: onConnect,
                    icon: const Icon(Icons.wifi_tethering_outlined),
                    label: const Text('Connect'),
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
    required this.onPasteInvite,
    required this.onHistoryAction,
    this.onConnect,
    this.onCopyInvitation,
    this.onCopyLink,
    this.invitationDraft,
    this.selectedContact,
  });

  final PeerSessionState sessionState;
  final Contact? selectedContact;
  final TextEditingController signalController;
  final Future<void> Function() onStartOffer;
  final Future<void> Function() onApplySignal;
  final Future<void> Function() onReset;
  final Future<void> Function() onPasteInvite;
  final Future<void> Function(PeerSessionHistoryAction action) onHistoryAction;
  final Future<void> Function()? onConnect;
  final VoidCallback? onCopyInvitation;
  final VoidCallback? onCopyLink;
  final PeerInvitationDraft? invitationDraft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showConnectAction = invitationDraft == null ||
        invitationDraft!.kind != PeerInvitationDraftKind.reply;

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
          if (selectedContact != null && invitationDraft != null) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitationDraft!.title,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(invitationDraft!.status),
                    const SizedBox(height: 10),
                    for (var index = 0;
                        index < invitationDraft!.steps.length;
                        index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${index + 1}. ${invitationDraft!.steps[index]}',
                        ),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (showConnectAction)
                          FilledButton.icon(
                            onPressed: onConnect,
                            icon: const Icon(Icons.wifi_tethering_outlined),
                            label: Text(
                              invitationDraft!.kind ==
                                      PeerInvitationDraftKind.connect
                                  ? 'Connect'
                                  : 'Refresh Offer',
                            ),
                          ),
                        if (onCopyInvitation != null)
                          FilledButton.tonalIcon(
                            onPressed: onCopyInvitation,
                            icon: const Icon(Icons.copy_all_outlined),
                            label: Text(invitationDraft!.copyActionLabel),
                          ),
                        if (onCopyLink != null)
                          FilledButton.tonalIcon(
                            onPressed: onCopyLink,
                            icon: const Icon(Icons.phonelink_outlined),
                            label: const Text('Copy Link'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (selectedContact != null)
                  Chip(label: Text('Target ${selectedContact!.displayName}')),
                if (sessionState.targetAddress != null)
                  Chip(label: Text(sessionState.targetAddress!)),
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
                if (sessionState.remotePresenceStatus != null)
                  Chip(
                    label: Text(
                      sessionState.remotePresenceStatus ==
                              PeerPresenceStatus.hidden
                          ? 'Presence hidden'
                          : sessionState.remotePresenceStatus!.label,
                    ),
                  ),
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
              labelText: 'Paste invite, reply, offer, answer, or ICE payload',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This field accepts full GungChat invite or reply text as well as raw signaling payloads.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onStartOffer,
                  icon: const Icon(Icons.outbox_outlined),
                  label: Text(
                    selectedContact == null ? 'Start Offer' : 'New Offer',
                  ),
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
                  label: const Text('Apply Input'),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: sessionState.isApplyingSignal ? null : onPasteInvite,
                icon: const Icon(Icons.content_paste_go_outlined),
                label: const Text('Paste Invite'),
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
          if (sessionState.expectedRemoteFingerprint != null &&
              sessionState.remoteFingerprint == null) ...[
            const SizedBox(height: 8),
            Text(
              'Expected fingerprint: ${sessionState.expectedRemoteFingerprint}',
              style: theme.textTheme.bodySmall,
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
                'Advanced signals',
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
          if (sessionState.history.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Handshake timeline',
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sessionState.history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = sessionState.history[index];
                  return _HistoryTile(
                    entry: entry,
                    onAction: onHistoryAction,
                  );
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
      if (sessionState.role == PeerSessionRole.responder) {
        return 'Invite imported. Copy the reply bundle or continue exchanging raw answer and ICE payloads.';
      }
      return 'Exchange offer, answer, and ICE payloads';
    }
    if (selectedContact != null) {
      return 'Selected ${selectedContact.displayName}. Connect to generate an offer and a ready-to-send invite.';
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.onAction,
  });

  final PeerSessionHistoryEntry entry;
  final Future<void> Function(PeerSessionHistoryAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = switch (entry.direction) {
      PeerSessionHistoryDirection.incoming => Icons.south_west,
      PeerSessionHistoryDirection.outgoing => Icons.north_east,
      PeerSessionHistoryDirection.system => Icons.timeline,
    };

    final time = entry.occurredAt.toLocal();
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        entry.detail == null
                            ? timeLabel
                            : '${entry.detail}\n$timeLabel',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (entry.action != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  await onAction(entry.action!);
                },
                icon: Icon(
                  entry.action!.kind == PeerSessionHistoryActionKind.copy
                      ? Icons.copy_all_outlined
                      : Icons.replay_outlined,
                  size: 18,
                ),
                label: Text(entry.action!.label),
              ),
            ],
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
