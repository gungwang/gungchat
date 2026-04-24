import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../features/chat/message_service.dart';
import '../features/chat/presence_status.dart';
import '../features/chat/peer_session_controller.dart';
import '../features/contacts/contact_book_controller.dart';
import '../features/contacts/contact_book_storage.dart';
import '../features/contacts/contact_exchange_service.dart';
import '../features/contacts/discovery_service.dart';
import '../features/settings/presence_preferences.dart';
import '../features/settings/read_receipt_preferences.dart';
import '../models/contact.dart';
import '../models/message.dart';

const bootstrapConversationId = 'bootstrap';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final navigationIndexProvider = StateProvider<int>((ref) => 0);
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

final peerSessionControllerProvider =
    StateNotifierProvider<PeerSessionController, PeerSessionState>((ref) {
  final controller = PeerSessionController(
    loadIdentity: () => ref.read(keyManagerProvider).getOrCreateIdentity(),
    loadMessageService: () => ref.read(messageServiceProvider.future),
    refreshConversation: (conversationId) {
      ref.invalidate(conversationMessagesProvider(conversationId));
    },
    reactionService: ref.watch(reactionServiceProvider),
    webRtcManager: ref.watch(webRtcManagerProvider),
    signalingService: ref.watch(manualSignalingServiceProvider),
    cryptoService: ref.watch(cryptoServiceProvider),
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

final contactExchangeServiceProvider = Provider<ContactExchangeService>((ref) {
  return const ContactExchangeService();
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
