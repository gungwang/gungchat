import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../../commands/slash_command_registry.dart';
import '../../core/accessibility/a11y_helper.dart';
import '../../core/encryption/key_manager.dart';
import '../../core/networking/network_monitor.dart';
import '../../core/networking/webrtc_manager.dart';
import '../../core/text/spoiler_renderer.dart';
import '../../media/media_gallery_screen.dart';
import '../../models/contact.dart';
import '../../models/message.dart';
import '../contacts/contact_exchange_service.dart';
import '../contacts/discovery_service.dart';
import '../../templates/quick_reply_service.dart';
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
  Message? _editingMessage;
  Timer? _highlightClearTimer;
  String? _highlightedMessageId;
  bool _burnAfterRead = true;
  bool _sending = false;
  int _attachmentSequence = 0;

  @override
  void dispose() {
    unawaited(ref.read(voiceMessageServiceProvider).cancelRecording());
    unawaited(ref.read(voiceMessageServiceProvider).stopPlayback());
    _highlightClearTimer?.cancel();
    _composerController.dispose();
    _signalController.dispose();
    super.dispose();
  }

  Future<void> _copyText(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      _showSnack('$label copied');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _setComposerText(String value) {
    _composerController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  String? _quickReplyLookupPrefix({bool allowWhileEditing = false}) {
    if (!allowWhileEditing && _editingMessage != null) {
      return null;
    }

    final currentText = _composerController.text.trim();
    if (!QuickReplyService.looksLikeLookup(currentText)) {
      return null;
    }
    if (const SlashCommandRegistry().execute(currentText) != null) {
      return null;
    }

    return QuickReplyService.lookupPrefix(currentText);
  }

  Future<bool> _expandQuickReplyIfNeeded() async {
    final lookup = _quickReplyLookupPrefix(allowWhileEditing: true);
    if (lookup == null || lookup.isEmpty) {
      return false;
    }

    final service = await ref.read(quickReplyServiceProvider.future);
    final replacement = await service.useTemplate(lookup);
    if (replacement == null) {
      return false;
    }

    _setComposerText(replacement);
    ref.invalidate(allQuickRepliesProvider);
    if (mounted) {
      A11yHelper.announce('Quick reply inserted', context);
    }
    return true;
  }

  Future<void> _applyQuickReply(QuickReply template) async {
    final service = await ref.read(quickReplyServiceProvider.future);
    final replacement = await service.useTemplate(template.shortCode);
    if (replacement == null) {
      return;
    }

    _setComposerText(replacement);
    ref.invalidate(allQuickRepliesProvider);
    if (mounted) {
      ref.read(chatComposerFocusNodeProvider).requestFocus();
      A11yHelper.announce('Quick reply inserted', context);
    }
  }

  String _nextAttachmentId() {
    _attachmentSequence += 1;
    return '${DateTime.now().microsecondsSinceEpoch}-$_attachmentSequence';
  }

  AttachmentType _attachmentTypeForFile(PlatformFile file) {
    final mimeType = file.path == null ? null : lookupMimeType(file.path!);
    if (mimeType != null) {
      if (mimeType.startsWith('image/')) {
        return AttachmentType.image;
      }
      if (mimeType.startsWith('video/')) {
        return AttachmentType.video;
      }
      if (mimeType.startsWith('audio/')) {
        return AttachmentType.audio;
      }
    }

    final extension = file.extension?.toLowerCase();
    if (extension != null) {
      if (const {'png', 'jpg', 'jpeg', 'gif', 'webp', 'heic'}.contains(extension)) {
        return AttachmentType.image;
      }
      if (const {'mp4', 'mov', 'mkv', 'webm'}.contains(extension)) {
        return AttachmentType.video;
      }
      if (const {'aac', 'm4a', 'mp3', 'ogg', 'wav'}.contains(extension)) {
        return AttachmentType.audio;
      }
    }

    return AttachmentType.document;
  }

  MessageType _messageTypeForAttachments(List<Attachment> attachments) {
    if (attachments.length != 1) {
      return MessageType.multiAttachment;
    }

    switch (attachments.first.type) {
      case AttachmentType.image:
        return MessageType.image;
      case AttachmentType.video:
        return MessageType.video;
      case AttachmentType.location:
        return MessageType.location;
      case AttachmentType.contactCard:
        return MessageType.contactCard;
      case AttachmentType.audio:
      case AttachmentType.document:
        return MessageType.multiAttachment;
    }
  }

  Future<void> _sendAttachments(
    List<Attachment> attachments, {
    required Message? replyingToMessage,
  }) async {
    if (attachments.isEmpty || _sending) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final sent = await ref.read(peerSessionControllerProvider.notifier).sendAttachments(
            messageType: _messageTypeForAttachments(attachments),
            attachments: attachments,
            burnAfterRead: _burnAfterRead,
            replyToMessageId: replyingToMessage?.id,
            replyToBody: replyingToMessage?.previewText,
          );
      if (sent) {
        _clearReplyTarget();
        if (mounted) {
          A11yHelper.announce('Attachment sent', context);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _pickFilesAndSend({required Message? replyingToMessage}) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) {
      return;
    }

    final attachments = result.files
        .where((file) => file.path != null && file.path!.trim().isNotEmpty)
        .map(
          (file) => Attachment(
            id: _nextAttachmentId(),
            type: _attachmentTypeForFile(file),
            displayName: file.name,
            filePath: file.path,
            mimeType: file.path == null ? null : lookupMimeType(file.path!),
            sizeBytes: file.size,
          ),
        )
        .toList(growable: false);
    if (attachments.isEmpty) {
      _showSnack('The selected files are not accessible from this device.');
      return;
    }

    await _sendAttachments(
      attachments,
      replyingToMessage: replyingToMessage,
    );
  }

  Future<void> _shareCurrentLocation({required Message? replyingToMessage}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('Enable location services before sharing your location.');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showSnack('Location permission is required to share your location.');
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    await _sendAttachments(
      [
        Attachment(
          id: _nextAttachmentId(),
          type: AttachmentType.location,
          displayName: 'Current location',
          metadata: <String, Object?>{
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracyMeters': position.accuracy,
          },
        ),
      ],
      replyingToMessage: replyingToMessage,
    );
  }

  Future<Contact?> _pickContactCardTarget() async {
    final savedContacts = ref.read(contactBookProvider);
    if (savedContacts.isEmpty) {
      _showSnack('Save or import a contact before sharing a contact card.');
      return null;
    }

    return showModalBottomSheet<Contact>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('Share contact card')),
              for (final contact in savedContacts)
                ListTile(
                  leading: const Icon(Icons.contact_page_outlined),
                  title: Text(contact.displayName),
                  subtitle: Text(contact.fingerprint),
                  onTap: () => Navigator.of(sheetContext).pop(contact),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareContactCard({required Message? replyingToMessage}) async {
    final contact = await _pickContactCardTarget();
    if (contact == null) {
      return;
    }

    final lastKnownAddress = contact.lastKnownAddress;
    final addressParts = lastKnownAddress?.split(':') ?? const <String>[];
    final addresses = addressParts.isEmpty ? const <String>[] : [addressParts.first];
    final port = addressParts.length < 2
        ? DiscoveryService.discoveryPort
        : int.tryParse(addressParts.last) ?? DiscoveryService.discoveryPort;
    final card = ContactCard(
      displayName: contact.displayName,
      fingerprint: contact.fingerprint,
      addresses: addresses,
      port: port,
      createdAt: contact.lastSeenAt,
    );
    final payload = ref.read(contactExchangeServiceProvider).encodeContactCard(card);

    await _sendAttachments(
      [
        Attachment(
          id: _nextAttachmentId(),
          type: AttachmentType.contactCard,
          displayName: '${contact.displayName} contact card',
          metadata: <String, Object?>{
            'displayName': contact.displayName,
            'fingerprint': contact.fingerprint,
            'payload': payload,
          },
        ),
      ],
      replyingToMessage: replyingToMessage,
    );
  }

  Future<void> _openMediaGallery({
    required String conversationId,
    required String title,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MediaGalleryScreen(
          conversationId: conversationId,
          title: title,
        ),
      ),
    );
  }

  void _startReply(Message message) {
    setState(() {
      _editingMessage = null;
      _replyingToMessage = message;
    });
  }

  void _startEdit(Message message) {
    if (message.isDeleted) {
      return;
    }

    setState(() {
      _replyingToMessage = null;
      _editingMessage = message;
      _composerController.text = message.body;
      _composerController.selection = TextSelection.fromPosition(
        TextPosition(offset: _composerController.text.length),
      );
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

  void _clearEditTarget({bool clearComposer = false}) {
    if (_editingMessage == null) {
      return;
    }

    setState(() {
      _editingMessage = null;
      if (clearComposer) {
        _composerController.clear();
      }
    });
  }

  String _replyPreviewText(String body) {
    final compact = SpoilerRenderer.previewText(body);
    if (compact.length <= 96) {
      return compact;
    }
    return '${compact.substring(0, 96)}...';
  }

  String _replyPreviewForMessage(Message message) {
    return _replyPreviewText(message.previewText);
  }

  void _toggleReaction(Message message, String emoji) {
    unawaited(
      ref.read(peerSessionControllerProvider.notifier).toggleReaction(
            message: message,
            emoji: emoji,
          ),
    );
  }

  void _toggleStar(Message message) {
    unawaited(() async {
      final messageService = await ref.read(messageServiceProvider.future);
      await messageService.toggleStar(message.id);
      ref.invalidate(conversationMessagesProvider(message.conversationId));
    }());
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

    if (selectedContact != null &&
        ref.read(blockedContactsProvider).contains(selectedContact.fingerprint)) {
      _showSnack(
        '${selectedContact.displayName} is blocked. Unblock this contact before sending peer messages.',
      );
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
              replyToBody: replyingToMessage?.previewText,
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
          replyToBody: replyingToMessage?.previewText,
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

  Future<void> _submitComposer(
    DeviceIdentity identity,
    Contact? selectedContact, {
    Message? replyingToMessage,
    Message? editingMessage,
  }) async {
    final peerSession = ref.read(peerSessionControllerProvider);
    final activeConversationId = peerSession.conversationId ??
        (selectedContact == null
            ? bootstrapConversationId
            : conversationIdForFingerprint(selectedContact.fingerprint));

    if (editingMessage == null) {
      await _expandQuickReplyIfNeeded();
    }

    if (editingMessage == null) {
      final handled = await _executeSlashCommandIfNeeded(
        conversationId: activeConversationId,
        selectedContact: selectedContact,
      );
      if (handled) {
        return;
      }
    }

    if (editingMessage != null) {
      final body = _composerController.text.trim();
      if (body.isEmpty || _sending) {
        return;
      }

      setState(() {
        _sending = true;
      });

      try {
        final edited = await ref
            .read(peerSessionControllerProvider.notifier)
            .editMessage(
              message: editingMessage,
              body: body,
            );
        if (edited) {
          _composerController.clear();
          _clearEditTarget();
        }
      } finally {
        if (mounted) {
          setState(() {
            _sending = false;
          });
        }
      }
      return;
    }

    await _sendMessage(
      identity,
      selectedContact,
      replyingToMessage: replyingToMessage,
    );
  }

  Future<bool> _executeSlashCommandIfNeeded({
    required String conversationId,
    required Contact? selectedContact,
  }) async {
    final result = const SlashCommandRegistry().execute(_composerController.text);
    if (result == null) {
      return false;
    }

    switch (result.action) {
      case SlashCommandAction.clear:
        await _clearConversationHistory(conversationId: conversationId);
        break;
      case SlashCommandAction.export:
        await _exportConversation(
          conversationId: conversationId,
          selectedContact: selectedContact,
        );
        break;
      case SlashCommandAction.status:
        final nextStatusText = result.statusText ?? '';
        await ref.read(customStatusTextProvider.notifier).setText(nextStatusText);
        await ref
            .read(peerSessionControllerProvider.notifier)
            .syncCustomStatusText(ref.read(customStatusTextProvider));
        if (mounted) {
          _showSnack(
            nextStatusText.trim().isEmpty
                ? 'Custom status cleared.'
                : 'Custom status updated.',
          );
        }
        break;
      case SlashCommandAction.destroy:
        await _destroyLocalData(activeConversationId: conversationId);
        break;
      case SlashCommandAction.showHelp:
        await _showSlashHelp(
          result.message ?? const SlashCommandRegistry().helpText,
        );
        break;
      case SlashCommandAction.showMessage:
        if (mounted && result.message != null) {
          _showSnack(result.message!);
        }
        break;
    }

    _composerController.clear();
    await ref.read(peerSessionControllerProvider.notifier).clearLocalTyping(
          notifyPeer: false,
        );
    return true;
  }

  Future<void> _showSlashHelp(String helpText) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Slash commands'),
          content: SingleChildScrollView(child: Text(helpText)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportConversation({
    required String conversationId,
    required Contact? selectedContact,
  }) async {
    final messageService = await ref.read(messageServiceProvider.future);
    final messages = await messageService.listMessages(conversationId);
    if (messages.isEmpty) {
      if (mounted) {
        _showSnack('No messages are available to export.');
      }
      return;
    }

    final label = selectedContact?.displayName ?? 'bootstrap';
    final exportFile = await ref.read(chatExportServiceProvider).exportConversation(
          conversationId: conversationId,
          conversationLabel: label,
          messages: messages,
        );
    await ref.read(chatExportServiceProvider).shareExport(exportFile);
    if (mounted) {
      _showSnack('Chat export prepared for sharing.');
    }
  }

  Future<void> _clearConversationHistory({
    required String conversationId,
  }) async {
    final confirmed = await _confirmAction(
      title: 'Clear conversation?',
      content:
          'This removes the current conversation from local storage on this device.',
      confirmLabel: 'Clear',
    );
    if (!confirmed) {
      return;
    }

    final messageService = await ref.read(messageServiceProvider.future);
    await messageService.clearConversation(conversationId);
    ref.invalidate(conversationMessagesProvider(conversationId));
    _highlightClearTimer?.cancel();
    if (_replyingToMessage?.conversationId == conversationId) {
      _clearReplyTarget();
    }
    if (_editingMessage?.conversationId == conversationId) {
      _clearEditTarget(clearComposer: true);
    }
    if (mounted) {
      setState(() {
        _highlightedMessageId = null;
      });
      _showSnack('Conversation cleared locally.');
    }
  }

  Future<void> _destroyLocalData({
    required String activeConversationId,
  }) async {
    final confirmed = await _confirmAction(
      title: 'Wipe local data?',
      content:
          'This removes local messages, saved contacts, preferences, blocked peers, and identity keys from this device.',
      confirmLabel: 'Wipe',
    );
    if (!confirmed) {
      return;
    }

    await ref.read(peerSessionControllerProvider.notifier).resetSession();
    await ref.read(voiceMessageServiceProvider).cancelRecording();
    await ref.read(voiceMessageServiceProvider).stopPlayback();

    final messageService = await ref.read(messageServiceProvider.future);
    await messageService.wipeAllLocalData();
    await ref.read(keyManagerProvider).clearIdentity();
    await ref.read(secureStorageProvider).deleteAll();
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    ref.read(appLockServiceProvider).clearSession();

    ref.read(selectedContactFingerprintProvider.notifier).state = null;
    ref.read(pendingPeerInputProvider.notifier).state = null;
    ref.read(pendingPeerConnectIntentProvider.notifier).state = null;

    ref.invalidate(deviceIdentityProvider);
    ref.invalidate(contactBookProvider);
    ref.invalidate(blockedContactsProvider);
    ref.invalidate(readReceiptsEnabledProvider);
    ref.invalidate(localPresenceStatusProvider);
    ref.invalidate(linkPreviewsEnabledProvider);
    ref.invalidate(customStatusTextProvider);
    ref.invalidate(appLockSettingsProvider);
    ref.invalidate(conversationMessagesProvider(activeConversationId));
    ref.invalidate(conversationMessagesProvider(bootstrapConversationId));

    _highlightClearTimer?.cancel();
    if (mounted) {
      setState(() {
        _replyingToMessage = null;
        _editingMessage = null;
        _highlightedMessageId = null;
      });
      _composerController.clear();
      _signalController.clear();
      _showSnack('Local data wiped. A new identity will be generated when needed.');
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String content,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _deleteMessage(
    Message message,
    MessageDeleteMode mode,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            mode == MessageDeleteMode.hardDelete
                ? 'Erase message permanently?'
                : 'Delete message for everyone?',
          ),
          content: Text(
            mode == MessageDeleteMode.hardDelete
                ? 'This removes the message record instead of showing a deleted placeholder.'
                : 'This replaces the message with a deleted placeholder in the conversation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                mode == MessageDeleteMode.hardDelete ? 'Erase' : 'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final deleted = await ref.read(peerSessionControllerProvider.notifier).deleteMessage(
          message: message,
          mode: mode,
        );
    if (deleted && _editingMessage?.id == message.id) {
      _clearEditTarget(clearComposer: true);
    }
  }

  Future<void> _toggleVoiceRecording({
    required bool canSendSecure,
    required Message? replyingToMessage,
  }) async {
    final voiceMessageService = ref.read(voiceMessageServiceProvider);

    if (voiceMessageService.isRecording) {
      final clip = await voiceMessageService.stopRecording();
      if (clip == null) {
        return;
      }

      setState(() {
        _sending = true;
      });
      try {
        final sent = await ref
            .read(peerSessionControllerProvider.notifier)
            .sendVoiceMessage(
              clip: clip,
              burnAfterRead: _burnAfterRead,
              replyToMessageId: replyingToMessage?.id,
              replyToBody: replyingToMessage?.previewText,
            );
        if (sent) {
          _clearReplyTarget();
        }
      } finally {
        if (mounted) {
          setState(() {
            _sending = false;
          });
        }
      }
      return;
    }

    if (!canSendSecure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Open the secure channel before recording voice messages.',
            ),
          ),
        );
      }
      return;
    }

    final started = await voiceMessageService.startRecording();
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not access the microphone. Check app permissions and device microphone settings.',
          ),
        ),
      );
    }
  }

  Future<void> _toggleVoicePlayback(Message message) async {
    final filePath = message.audioFilePath;
    if (filePath == null) {
      return;
    }

    await ref.read(voiceMessageServiceProvider).togglePlayback(
          messageId: message.id,
          filePath: filePath,
        );
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
    final localUserId = identityAsync.asData?.value.fingerprint;
    final voiceMessageService = ref.watch(voiceMessageServiceProvider);
    final networkAsync = ref.watch(networkStatusProvider);
    final peerSession = ref.watch(peerSessionControllerProvider);
    final mediaCall = ref.watch(mediaCallControllerProvider);
    final selectedContact = ref.watch(selectedContactProvider);
    final blockedContacts = ref.watch(blockedContactsProvider);
    final readReceiptsEnabled = ref.watch(readReceiptsEnabledProvider);
    final customStatusText = ref.watch(customStatusTextProvider);
    final composerFocusNode = ref.watch(chatComposerFocusNodeProvider);

    final isSelectedContactBlocked = selectedContact != null &&
      blockedContacts.contains(selectedContact.fingerprint);
    final isActivePeerBlocked = peerSession.remoteFingerprint != null &&
      blockedContacts.contains(peerSession.remoteFingerprint!);
    final isConversationBlocked =
      isSelectedContactBlocked || isActivePeerBlocked;

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
    final editingMessage = _editingMessage?.conversationId == activeConversationId
      ? _editingMessage
      : null;

    final messagesAsync = ref.watch(
      conversationMessagesProvider(activeConversationId),
    );
    final canSendSecure = peerSession.isTransportReady;
    final canSaveLocal =
        selectedContact == null && !peerSession.isSessionActive;
    final isRecordingVoice = voiceMessageService.isRecording;
    final composerEnabled = !isRecordingVoice;
    final canStartVideoCall =
      selectedContact != null &&
      !isSelectedContactBlocked &&
      selectedContact.lastKnownAddress != null &&
      mediaCall.isIdle;
    final videoCallTooltip = selectedContact == null
      ? 'Select a contact to start a video call'
      : isSelectedContactBlocked
        ? 'Blocked contacts cannot be called'
        : selectedContact.lastKnownAddress == null
          ? 'This contact needs a LAN address before you can call them'
          : mediaCall.isIdle
            ? 'Start video call'
            : 'A video call is already in progress';
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
    final invitationDraft = selectedContact == null || isSelectedContactBlocked
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
    final quickReplyLookupPrefix = _quickReplyLookupPrefix();
    final quickReplyMatchesAsync = quickReplyLookupPrefix == null
      ? null
      : ref.watch(quickReplyMatchesProvider(quickReplyLookupPrefix));
    final conversationTitle = selectedContact?.displayName ?? 'Bootstrap';
    final sessionSummary = canSendSecure
        ? 'Secure channel open'
        : selectedContact == null
            ? 'Choose a contact from Contacts'
            : isSelectedContactBlocked
                ? '${selectedContact.displayName} is blocked'
                : 'Ready to connect';

    Future<void> showSessionDetails() async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) {
          return FractionallySizedBox(
            heightFactor: 0.92,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Connection Details',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    _StateChip(state: peerSession),
                  ],
                ),
                const SizedBox(height: 16),
                _IdentityCard(identityAsync: identityAsync),
                const SizedBox(height: 12),
                _NetworkCard(networkAsync: networkAsync),
                const SizedBox(height: 12),
                _PeerSessionCard(
                  sessionState: peerSession,
                  selectedContact: selectedContact,
                  isTargetBlocked: isSelectedContactBlocked,
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
                    await ref.read(voiceMessageServiceProvider).cancelRecording();
                    await ref.read(voiceMessageServiceProvider).stopPlayback();
                    if (mounted) {
                      _signalController.clear();
                      _highlightClearTimer?.cancel();
                      setState(() {
                        _editingMessage = null;
                        _replyingToMessage = null;
                        _highlightedMessageId = null;
                      });
                    }
                  },
                  onConnect: selectedContact == null || isSelectedContactBlocked
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
              ],
            ),
          );
        },
      );
    }

    return SafeArea(
      child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedContact?.displayName ?? 'GungChat',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sessionSummary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StateChip(state: peerSession),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: videoCallTooltip,
                      onPressed: canStartVideoCall
                          ? () async {
                              try {
                                await ref
                                    .read(mediaCallControllerProvider.notifier)
                                    .startOutgoingCall(selectedContact);
                              } catch (error) {
                                _showSnack('Video call could not start: $error');
                              }
                            }
                          : null,
                      icon: const Icon(Icons.videocam_rounded),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Connection details',
                      onPressed: showSessionDetails,
                      icon: const Icon(Icons.tune_outlined),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    margin: EdgeInsets.zero,
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
                            _buildMessage(
                              message,
                              messages,
                              localUserId: localUserId,
                              canToggleReactions:
                                  peerSession.isTransportReady &&
                                      localUserId != null &&
                                      message.type != MessageType.system,
                                canManageMessages:
                                  peerSession.isTransportReady &&
                                    message.isOutgoing &&
                                    message.type != MessageType.system,
                            ),
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
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Card(
                  margin: EdgeInsets.zero,
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
                    if (peerSession.remoteStatusText != null &&
                        peerSession.remoteStatusText!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Peer custom status: ${peerSession.remoteStatusText!}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (customStatusText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Your custom status: $customStatusText',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (isConversationBlocked) ...[
                      const SizedBox(height: 8),
                      Text(
                        'This contact is blocked. Unblock them in Contacts before continuing peer messaging.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
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
                                      _replyPreviewForMessage(replyingToMessage),
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
                    if (editingMessage != null) ...[
                      const SizedBox(height: 12),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.colorScheme.secondaryContainer,
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
                                      'Editing your message',
                                      style: theme.textTheme.labelLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _replyPreviewText(editingMessage.body),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Cancel edit',
                                onPressed: () => _clearEditTarget(
                                  clearComposer: true,
                                ),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (isRecordingVoice) ...[
                      const SizedBox(height: 12),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.colorScheme.errorContainer,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.mic),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Recording voice message... tap Stop & Send when ready. Up to 2 minutes.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      focusNode: composerFocusNode,
                      controller: _composerController,
                      maxLines: 3,
                      minLines: 1,
                      enabled: composerEnabled,
                      onChanged: (value) {
                        setState(() {});
                        if (canSendSecure) {
                          ref
                              .read(peerSessionControllerProvider.notifier)
                              .updateComposerActivity(value);
                        }
                      },
                      textInputAction: TextInputAction.send,
                      onSubmitted: identityAsync.asData == null ||
                              _sending ||
                              !composerEnabled
                          ? null
                          : (_) => _submitComposer(
                                identityAsync.requireValue,
                                selectedContact,
                            replyingToMessage: replyingToMessage,
                            editingMessage: editingMessage,
                              ),
                      decoration: InputDecoration(
                        labelText: editingMessage != null
                          ? 'Edit secure message'
                          : canSendSecure
                            ? 'Secure peer message'
                            : canSaveLocal
                                ? 'Bootstrap message'
                                : 'Peer message',
                        hintText: editingMessage != null
                          ? 'Update your encrypted message for the active peer session...'
                          : canSendSecure
                            ? 'Type an encrypted message for the active peer session...'
                            : canSaveLocal
                                ? 'Type a local encrypted message draft...'
                                : isConversationBlocked
                                    ? 'This contact is blocked. Slash commands still run locally.'
                                    : 'Type /help for local commands, or complete the signal exchange to enable sending.',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (quickReplyMatchesAsync != null) ...[
                      const SizedBox(height: 8),
                      quickReplyMatchesAsync.when(
                        data: (templates) {
                          if (templates.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final template in templates)
                                ActionChip(
                                  label: Text('/${template.shortCode}'),
                                  avatar: const Icon(Icons.flash_on_outlined, size: 18),
                                  onPressed: () => unawaited(_applyQuickReply(template)),
                                ),
                            ],
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                    if (peerSession.isRemoteTyping) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_typingPeerLabel(peerSession, selectedContact)} is typing...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        PopupMenuButton<_ChatAttachmentAction>(
                          tooltip: 'More actions',
                          enabled: !_sending && !isRecordingVoice,
                          icon: const Icon(Icons.add_circle_outline),
                          onSelected: (action) {
                            switch (action) {
                              case _ChatAttachmentAction.gallery:
                                _openMediaGallery(
                                  conversationId: activeConversationId,
                                  title: conversationTitle,
                                );
                              case _ChatAttachmentAction.files:
                                if (canSendSecure && !isConversationBlocked) {
                                  _pickFilesAndSend(
                                    replyingToMessage: replyingToMessage,
                                  );
                                }
                              case _ChatAttachmentAction.location:
                                if (canSendSecure && !isConversationBlocked) {
                                  _shareCurrentLocation(
                                    replyingToMessage: replyingToMessage,
                                  );
                                }
                              case _ChatAttachmentAction.contact:
                                if (canSendSecure && !isConversationBlocked) {
                                  _shareContactCard(
                                    replyingToMessage: replyingToMessage,
                                  );
                                }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: _ChatAttachmentAction.gallery,
                              child: ListTile(
                                leading: Icon(Icons.photo_library_outlined),
                                title: Text('Gallery'),
                              ),
                            ),
                            PopupMenuItem(
                              value: _ChatAttachmentAction.files,
                              enabled: canSendSecure && !isConversationBlocked,
                              child: const ListTile(
                                leading: Icon(Icons.attach_file),
                                title: Text('Files'),
                              ),
                            ),
                            PopupMenuItem(
                              value: _ChatAttachmentAction.location,
                              enabled: canSendSecure && !isConversationBlocked,
                              child: const ListTile(
                                leading: Icon(Icons.place_outlined),
                                title: Text('Location'),
                              ),
                            ),
                            PopupMenuItem(
                              value: _ChatAttachmentAction.contact,
                              enabled: canSendSecure && !isConversationBlocked,
                              child: const ListTile(
                                leading: Icon(Icons.contact_page_outlined),
                                title: Text('Contact'),
                              ),
                            ),
                          ],
                        ),
                        if (canSendSecure) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: isRecordingVoice
                                ? 'Stop and send voice'
                                : 'Record voice',
                            onPressed: identityAsync.asData == null ||
                                    _sending ||
                                    editingMessage != null ||
                                    isConversationBlocked
                                ? null
                                : () => _toggleVoiceRecording(
                                      canSendSecure: canSendSecure,
                                      replyingToMessage: replyingToMessage,
                                    ),
                            icon: Icon(
                              isRecordingVoice
                                  ? Icons.stop_circle_outlined
                                  : Icons.mic_none,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: identityAsync.asData == null ||
                                    _sending ||
                                    isRecordingVoice
                                ? null
                                : () => _submitComposer(
                                      identityAsync.requireValue,
                                      selectedContact,
                                      replyingToMessage: replyingToMessage,
                                      editingMessage: editingMessage,
                                    ),
                            icon: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    editingMessage != null
                                        ? Icons.check
                                        : Icons.send,
                                  ),
                            label: Text(
                              editingMessage != null
                                  ? 'Save Message Edit'
                                  : canSendSecure
                                      ? 'Send Secure Message'
                                      : canSaveLocal
                                          ? 'Save Local Message'
                                          : 'Wait For Secure Channel',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Burn after read',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        Switch.adaptive(
                          value: _burnAfterRead,
                          onChanged: editingMessage != null || isRecordingVoice
                              ? null
                              : (value) {
                                  setState(() {
                                    _burnAfterRead = value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildMessage(
    Message message,
    List<Message> messages, {
    required String? localUserId,
    required bool canToggleReactions,
    required bool canManageMessages,
  }) {
    final voiceMessageService = ref.watch(voiceMessageServiceProvider);
    return MessageBubble(
      key: _messageKeyFor(message.id),
      message: message,
      isHighlighted: _highlightedMessageId == message.id,
      currentUserId: localUserId,
      onPlayAudio: message.hasAudio ? () => _toggleVoicePlayback(message) : null,
      isPlayingAudio: voiceMessageService.playingMessageId == message.id,
      onReply: message.type == MessageType.system || message.isDeleted
          ? null
          : () => _startReply(message),
      onToggleStar: message.type == MessageType.system || message.isDeleted
          ? null
          : () => _toggleStar(message),
        onEdit: canManageMessages &&
            !message.isDeleted &&
            message.type == MessageType.text
          ? () => _startEdit(message)
          : null,
      onDelete: canManageMessages
          ? (mode) => unawaited(_deleteMessage(message, mode))
          : null,
      onToggleReaction: canToggleReactions
          ? (emoji) => _toggleReaction(message, emoji)
          : null,
      onQuotedMessageTap: message.replyToMessageId == null
          ? null
          : () => _jumpToQuotedMessage(
                message: message,
                messages: messages,
              ),
    );
  }
}

enum _ChatAttachmentAction {
  gallery,
  files,
  location,
  contact,
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
    this.isTargetBlocked = false,
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
  final bool isTargetBlocked;
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
                        if (isTargetBlocked)
                          const Chip(label: Text('Blocked contact')),
                        if (showConnectAction)
                          FilledButton.icon(
                            onPressed: isTargetBlocked ? null : onConnect,
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
                  onPressed: isTargetBlocked ? null : onStartOffer,
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
      if (isTargetBlocked) {
        return 'Selected ${selectedContact.displayName}, but this contact is blocked.';
      }
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
