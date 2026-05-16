import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/chat/chat_export_service.dart';
import '../features/chat/adb_emulator_bridge_service.dart';
import '../features/chat/attachment_message_service.dart';
import '../core/encryption/crypto_service.dart';
import '../core/encryption/key_manager.dart';
import '../core/networking/ice_manager.dart';
import '../core/networking/network_monitor.dart';
import '../core/networking/signaling_service.dart';
import '../core/networking/webrtc_manager.dart';
import '../core/storage/message_db.dart';
import '../core/storage/secure_storage.dart';
import '../features/chat/ephemeral_manager.dart';
import '../features/chat/pending_peer_input.dart';
import '../features/chat/peer_connect_intent.dart';
import '../features/chat/peer_deep_link_service.dart';
import '../features/chat/peer_invitation_builder.dart';
import '../features/chat/peer_invitation_parser.dart';
import '../features/chat/reaction_service.dart';
import '../features/chat/custom_status_service.dart';
import '../features/chat/lan_signaling_service.dart';
import '../features/chat/message_service.dart';
import '../features/chat/presence_status.dart';
import '../features/chat/peer_session_controller.dart';
import '../features/chat/voice_message_service.dart';
import '../features/chat/link_preview_service.dart';
import '../features/chat/media_call_controller.dart';
import '../features/contacts/contact_book_controller.dart';
import '../features/contacts/contact_book_storage.dart';
import '../features/contacts/contact_exchange_service.dart';
import '../features/contacts/discovery_service.dart';
import '../media/media_gallery_service.dart';
import '../organization/contact_notes_service.dart';
import '../organization/conversation_mute_service.dart';
import '../organization/label_service.dart';
import '../preferences/keyboard_shortcut_service.dart';
import '../preferences/notification_prefs_service.dart';
import '../preferences/theme_service.dart';
import '../features/settings/app_lock_preferences.dart';
import '../features/settings/custom_status_preferences.dart';
import '../features/settings/presence_preferences.dart';
import '../features/settings/read_receipt_preferences.dart';
import '../features/settings/link_preview_preferences.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../security/app_lock_service.dart';
import '../security/contact_block_service.dart';
import '../templates/quick_reply_service.dart';

const bootstrapConversationId = 'bootstrap';

final navigationIndexProvider = StateProvider<int>((ref) => 0);
final chatComposerFocusNodeProvider = Provider<FocusNode>((ref) {
  final focusNode = FocusNode(debugLabel: 'chat-composer');
  ref.onDispose(focusNode.dispose);
  return focusNode;
});
final selectedContactFingerprintProvider =
    StateProvider<String?>((ref) => null);
final pendingPeerInputProvider =
  StateProvider<PendingPeerInput?>((ref) => null);
final pendingPeerConnectIntentProvider =
  StateProvider<PeerConnectIntent?>((ref) => null);
final readReceiptPreferencesStorageProvider =
    Provider<ReadReceiptPreferencesStorage>((ref) {
  return const ReadReceiptPreferencesStorage();
});
final presencePreferencesStorageProvider =
    Provider<PresencePreferencesStorage>((ref) {
  return const PresencePreferencesStorage();
});
final linkPreviewPreferencesStorageProvider =
    Provider<LinkPreviewPreferencesStorage>((ref) {
  return const LinkPreviewPreferencesStorage();
});
final customStatusPreferencesStorageProvider =
    Provider<CustomStatusPreferencesStorage>((ref) {
  return const CustomStatusPreferencesStorage();
});
final appLockPreferencesStorageProvider =
    Provider<AppLockPreferencesStorage>((ref) {
  return const AppLockPreferencesStorage();
});
final themePreferencesStorageProvider = Provider<ThemePreferencesStorage>((ref) {
  return const ThemePreferencesStorage();
});
final notificationPreferencesStorageProvider =
    Provider<NotificationPreferencesStorage>((ref) {
  return const NotificationPreferencesStorage();
});
final readReceiptsEnabledProvider =
    StateNotifierProvider<ReadReceiptsPreferenceController, bool>((ref) {
  return ReadReceiptsPreferenceController(
    storage: ref.watch(readReceiptPreferencesStorageProvider),
  );
});
final localPresenceStatusProvider =
    StateNotifierProvider<PresencePreferenceController, PeerPresenceStatus>(
        (ref) {
  return PresencePreferenceController(
    storage: ref.watch(presencePreferencesStorageProvider),
  );
});
final linkPreviewsEnabledProvider =
    StateNotifierProvider<LinkPreviewPreferenceController, bool>((ref) {
  return LinkPreviewPreferenceController(
    storage: ref.watch(linkPreviewPreferencesStorageProvider),
  );
});
final customStatusServiceProvider = Provider<CustomStatusService>((ref) {
  return const CustomStatusService();
});
final customStatusTextProvider =
    StateNotifierProvider<CustomStatusPreferenceController, String>((ref) {
  return CustomStatusPreferenceController(
    storage: ref.watch(customStatusPreferencesStorageProvider),
    statusService: ref.watch(customStatusServiceProvider),
  );
});
final appLockSettingsProvider =
    StateNotifierProvider<AppLockSettingsController, AppLockSettings>((ref) {
  return AppLockSettingsController(
    storage: ref.watch(appLockPreferencesStorageProvider),
  );
});
final appThemeModeProvider =
    StateNotifierProvider<ThemePreferencesController, AppThemeMode>((ref) {
  return ThemePreferencesController(
    storage: ref.watch(themePreferencesStorageProvider),
  );
});
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(appThemeModeProvider).flutterThemeMode;
});
final notificationPreferencesProvider = StateNotifierProvider<
    NotificationPreferencesController,
    Map<NotificationPreferenceKey, bool>>((ref) {
  return NotificationPreferencesController(
    storage: ref.watch(notificationPreferencesStorageProvider),
  );
});
final appLifecycleStateProvider =
    StateProvider<AppLifecycleState>((ref) => AppLifecycleState.resumed);
final effectivePresenceStatusProvider = Provider<PeerPresenceStatus>((ref) {
  return resolveEffectivePresenceStatus(
    preferredStatus: ref.watch(localPresenceStatusProvider),
    lifecycleState: ref.watch(appLifecycleStateProvider),
  );
});

final secureStorageProvider = Provider<AppSecureStorage>((ref) {
  return AppSecureStorage();
});

final appLinksProvider = Provider<AppLinks>((ref) {
  return AppLinks();
});

final cryptoServiceProvider = Provider<CryptoService>((ref) {
  return CryptoService();
});

final keyManagerProvider = Provider<KeyManager>((ref) {
  return KeyManager(
    ref.watch(secureStorageProvider),
    ref.watch(cryptoServiceProvider),
  );
});

final deviceIdentityProvider = FutureProvider<DeviceIdentity>((ref) async {
  return ref.watch(keyManagerProvider).getOrCreateIdentity();
});

final iceManagerProvider = Provider<IceManager>((ref) {
  return const IceManager();
});

final webRtcManagerProvider = Provider<WebRtcManager>((ref) {
  final manager = WebRtcManager(iceManager: ref.watch(iceManagerProvider));
  ref.onDispose(() {
    manager.close();
  });
  return manager;
});

final manualSignalingServiceProvider = Provider<ManualSignalingService>((ref) {
  return const ManualSignalingService();
});

final networkMonitorProvider = Provider<NetworkMonitor>((ref) {
  return NetworkMonitor();
});

final networkStatusProvider = StreamProvider<NetworkSnapshot>((ref) {
  return ref.watch(networkMonitorProvider).watch();
});

final messageDatabaseProvider = FutureProvider<MessageDatabase>((ref) async {
  final database = MessageDatabase();
  await database.open();
  ref.onDispose(() {
    database.close();
  });
  return database;
});

final ephemeralManagerProvider = Provider<EphemeralManager>((ref) {
  return const EphemeralManager();
});

final reactionServiceProvider = Provider<ReactionService>((ref) {
  return const ReactionService();
});

final messageServiceProvider = FutureProvider<MessageService>((ref) async {
  final database = await ref.watch(messageDatabaseProvider.future);
  return MessageService(
    messageDatabase: database,
    cryptoService: ref.watch(cryptoServiceProvider),
    ephemeralManager: ref.watch(ephemeralManagerProvider),
  );
});

final voiceMessageServiceProvider = ChangeNotifierProvider<VoiceMessageService>(
  (ref) {
    final service = VoiceMessageService();
    ref.onDispose(service.dispose);
    return service;
  },
);
final attachmentMessageServiceProvider = Provider<AttachmentMessageService>((ref) {
  return const AttachmentMessageService();
});

final chatExportServiceProvider = Provider<ChatExportService>((ref) {
  return ChatExportService();
});
final quickReplyServiceProvider = FutureProvider<QuickReplyService>((ref) async {
  final database = await ref.watch(messageDatabaseProvider.future);
  return QuickReplyService(database);
});
final quickReplyMatchesProvider =
    FutureProvider.family<List<QuickReply>, String>((ref, prefix) async {
  final service = await ref.watch(quickReplyServiceProvider.future);
  return service.search(prefix);
});
final allQuickRepliesProvider = FutureProvider<List<QuickReply>>((ref) async {
  final service = await ref.watch(quickReplyServiceProvider.future);
  return service.getAllTemplates();
});
final labelServiceProvider = FutureProvider<LabelService>((ref) async {
  final database = await ref.watch(messageDatabaseProvider.future);
  return LabelService(database);
});
final allConversationLabelsProvider =
    FutureProvider<List<ConversationLabel>>((ref) async {
  final service = await ref.watch(labelServiceProvider.future);
  return service.getAllLabels();
});
final conversationLabelsProvider =
    FutureProvider.family<List<ConversationLabel>, String>((ref, contactId) async {
  final service = await ref.watch(labelServiceProvider.future);
  return service.getLabelsForConversation(contactId);
});
final contactNotesServiceProvider = FutureProvider<ContactNotesService>((ref) async {
  final database = await ref.watch(messageDatabaseProvider.future);
  return ContactNotesService(database);
});
final contactNotesProvider =
    FutureProvider.family<List<ContactNote>, String>((ref, contactId) async {
  final service = await ref.watch(contactNotesServiceProvider.future);
  return service.getNotesForContact(contactId);
});
final conversationMuteServiceProvider =
    FutureProvider<ConversationMuteService>((ref) async {
  final database = await ref.watch(messageDatabaseProvider.future);
  return ConversationMuteService(database);
});
final conversationMuteStateProvider = FutureProvider.family<
    ConversationNotificationSettings,
    String>((ref, contactId) async {
  final service = await ref.watch(conversationMuteServiceProvider.future);
  return service.getSettings(contactId);
});
final mediaGalleryServiceProvider = FutureProvider<MediaGalleryService>((ref) async {
  final database = await ref.watch(messageDatabaseProvider.future);
  return MediaGalleryService(database);
});
final conversationMediaProvider = FutureProvider.family<
    ConversationMediaSnapshot,
    String>((ref, conversationId) async {
  final service = await ref.watch(mediaGalleryServiceProvider.future);
  return service.getMediaByType(conversationId);
});
final keyboardShortcutServiceProvider = Provider<KeyboardShortcutService>((ref) {
  return const KeyboardShortcutService();
});

final linkPreviewServiceProvider = Provider<LinkPreviewService>((ref) {
  final service = LinkPreviewService();
  ref.onDispose(service.dispose);
  return service;
});

final linkPreviewProvider =
    FutureProvider.family<LinkPreview?, String>((ref, url) async {
  if (!ref.watch(linkPreviewsEnabledProvider)) {
    return null;
  }

  return ref.watch(linkPreviewServiceProvider).fetchPreview(url);
});

final contactBlockStorageProvider = Provider<ContactBlockStorage>((ref) {
  return ContactBlockStorage(ref.watch(secureStorageProvider));
});

final blockedContactsProvider =
    StateNotifierProvider<ContactBlockController, Set<String>>((ref) {
  return ContactBlockController(
    storage: ref.watch(contactBlockStorageProvider),
  );
});

final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService();
});

final contactExchangeServiceProvider = Provider<ContactExchangeService>((ref) {
  return const ContactExchangeService();
});

final adbEmulatorBridgeServiceProvider = Provider<AdbEmulatorBridgeService>((ref) {
  return AdbEmulatorBridgeService();
});

final lanSignalingServiceProvider = Provider<LanSignalingService>((ref) {
  final service = LanSignalingService(
    contactExchangeService: ref.watch(contactExchangeServiceProvider),
    resolveTargetAddress: ref.watch(adbEmulatorBridgeServiceProvider).resolveTargetAddress,
  );
  ref.onDispose(service.dispose);
  return service;
});

final mediaCallControllerProvider =
    StateNotifierProvider<MediaCallController, MediaCallState>((ref) {
  final controller = MediaCallController(
    iceManager: ref.watch(iceManagerProvider),
    signalingService: ref.watch(manualSignalingServiceProvider),
    loadMessageService: () => ref.read(messageServiceProvider.future),
    loadLocalSenderId: () async {
      final identity = await ref.read(keyManagerProvider).getOrCreateIdentity();
      return identity.fingerprint;
    },
    refreshConversation: (conversationId) {
      ref.invalidate(conversationMessagesProvider(conversationId));
    },
    dispatchLocalSignal: ({
      required encodedSignal,
      required targetAddress,
    }) async {
      final identity = await ref.read(keyManagerProvider).getOrCreateIdentity();
      await ref.read(lanSignalingServiceProvider).sendSignal(
            encodedSignal: encodedSignal,
            targetAddress: targetAddress,
            identity: identity,
            displayName:
                ref.read(contactExchangeServiceProvider).defaultDisplayName(
                      identity,
                    ),
          );
    },
  );
  ref.onDispose(controller.dispose);
  return controller;
});

final peerSessionControllerProvider =
    StateNotifierProvider<PeerSessionController, PeerSessionState>((ref) {
  final controller = PeerSessionController(
    loadIdentity: () => ref.read(keyManagerProvider).getOrCreateIdentity(),
    loadMessageService: () => ref.read(messageServiceProvider.future),
    loadVoiceMessageService: () => ref.read(voiceMessageServiceProvider),
    loadAttachmentMessageService: () => ref.read(attachmentMessageServiceProvider),
    refreshConversation: (conversationId) {
      ref.invalidate(conversationMessagesProvider(conversationId));
    },
    reactionService: ref.watch(reactionServiceProvider),
    webRtcManager: ref.watch(webRtcManagerProvider),
    signalingService: ref.watch(manualSignalingServiceProvider),
    cryptoService: ref.watch(cryptoServiceProvider),
    dispatchLocalSignal: ({
      required encodedSignal,
      required targetAddress,
    }) async {
      final identity = await ref.read(keyManagerProvider).getOrCreateIdentity();
      await ref.read(lanSignalingServiceProvider).sendSignal(
            encodedSignal: encodedSignal,
            targetAddress: targetAddress,
            identity: identity,
            displayName:
                ref.read(contactExchangeServiceProvider).defaultDisplayName(
                      identity,
                    ),
          );
    },
    isBlockedFingerprint: (fingerprint) {
      return ref.read(blockedContactsProvider).contains(fingerprint);
    },
  );
  ref.onDispose(controller.dispose);
  return controller;
});

final peerInvitationBuilderProvider = Provider<PeerInvitationBuilder>((ref) {
  return const PeerInvitationBuilder();
});

final peerInvitationParserProvider = Provider<PeerInvitationParser>((ref) {
  return const PeerInvitationParser();
});

final peerDeepLinkServiceProvider = Provider<PeerDeepLinkService>((ref) {
  return const PeerDeepLinkService();
});

final contactBookStorageProvider = Provider<ContactBookStorage>((ref) {
  return const ContactBookStorage();
});

final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  return DiscoveryService(
    contactExchangeService: ref.watch(contactExchangeServiceProvider),
  );
});

final contactBookProvider =
    StateNotifierProvider<ContactBookController, List<Contact>>((ref) {
  return ContactBookController(
    storage: ref.watch(contactBookStorageProvider),
  );
});

final selectedContactProvider = Provider<Contact?>((ref) {
  final fingerprint = ref.watch(selectedContactFingerprintProvider);
  if (fingerprint == null) {
    return null;
  }

  for (final contact in ref.watch(contactBookProvider)) {
    if (contact.fingerprint == fingerprint) {
      return contact;
    }
  }
  return null;
});

final conversationMessagesProvider =
    FutureProvider.family<List<Message>, String>((ref, conversationId) async {
  final messageService = await ref.watch(messageServiceProvider.future);
  return messageService.listMessages(conversationId);
});
