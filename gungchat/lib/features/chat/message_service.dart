import 'package:cryptography/cryptography.dart';
import 'package:uuid/uuid.dart';

import '../../core/encryption/crypto_service.dart';
import '../../core/storage/message_db.dart';
import '../../models/message.dart';
import 'ephemeral_manager.dart';

class MessageService {
  MessageService({
    required MessageDatabase messageDatabase,
    required CryptoService cryptoService,
    required EphemeralManager ephemeralManager,
    Uuid? uuid,
  })  : _messageDatabase = messageDatabase,
        _cryptoService = cryptoService,
        _ephemeralManager = ephemeralManager,
        _uuid = uuid ?? const Uuid();

  final MessageDatabase _messageDatabase;
  final CryptoService _cryptoService;
  final EphemeralManager _ephemeralManager;
  final Uuid _uuid;

  Future<List<Message>> listMessages(String conversationId) async {
    await _messageDatabase.purgeExpiredMessages();
    return _messageDatabase.listMessages(conversationId);
  }

  Future<Message> createLocalMessage({
    required String conversationId,
    required String senderId,
    required String body,
    bool burnAfterRead = true,
    Duration? ttl,
    MessageDeliveryState deliveryState = MessageDeliveryState.local,
  }) async {
    final message = Message(
      id: _uuid.v4(),
      conversationId: conversationId,
      senderId: senderId,
      body: body,
      type: MessageType.text,
      deliveryState: deliveryState,
      createdAt: DateTime.now(),
      isOutgoing: true,
      burnAfterRead: burnAfterRead,
      expiresAt: _ephemeralManager.resolveExpiry(
        burnAfterRead: burnAfterRead,
        explicitTtl: ttl,
      ),
    );

    await _messageDatabase.upsertMessage(message);
    return message;
  }

  Future<void> saveInboundMessage(Message message) {
    return _messageDatabase.upsertMessage(message.copyWith(isOutgoing: false));
  }

  Future<void> updateDeliveryState(
    String messageId,
    MessageDeliveryState deliveryState,
  ) {
    return _messageDatabase.updateDeliveryState(messageId, deliveryState);
  }

  Future<EncryptedPayload> encryptForTransport({
    required String body,
    required SecretKey sharedSecret,
  }) {
    return _cryptoService.encryptString(
        plaintext: body, secretKey: sharedSecret);
  }

  Future<String?> decryptFromTransport({
    required EncryptedPayload payload,
    required SecretKey sharedSecret,
  }) {
    return _cryptoService.decryptString(
        payload: payload, secretKey: sharedSecret);
  }
}
