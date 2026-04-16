import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/encryption/crypto_service.dart';
import '../core/encryption/key_manager.dart';
import '../core/networking/ice_manager.dart';
import '../core/networking/network_monitor.dart';
import '../core/networking/webrtc_manager.dart';
import '../core/storage/message_db.dart';
import '../core/storage/secure_storage.dart';
import '../features/chat/ephemeral_manager.dart';
import '../features/chat/message_service.dart';
import '../models/message.dart';

const bootstrapConversationId = 'bootstrap';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final secureStorageProvider = Provider<AppSecureStorage>((ref) {
  return AppSecureStorage();
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

final messageServiceProvider = FutureProvider<MessageService>((ref) async {
  final database = await ref.watch(messageDatabaseProvider.future);
  return MessageService(
    messageDatabase: database,
    cryptoService: ref.watch(cryptoServiceProvider),
    ephemeralManager: ref.watch(ephemeralManagerProvider),
  );
});

final conversationMessagesProvider =
    FutureProvider.family<List<Message>, String>((ref, conversationId) async {
  final messageService = await ref.watch(messageServiceProvider.future);
  return messageService.listMessages(conversationId);
});
