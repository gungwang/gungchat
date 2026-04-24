import 'dart:io';

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

  Future<Message?> getMessage(String messageId) {
    return _messageDatabase.getMessage(messageId);
  }

  Future<Message> createLocalMessage({
    required String conversationId,
    required String senderId,
    required String body,
    MessageType type = MessageType.text,
    bool burnAfterRead = true,
    Duration? ttl,
    MessageDeliveryState deliveryState = MessageDeliveryState.local,
    String? replyToMessageId,
    String? replyToBody,
    String? audioFilePath,
    int? audioDurationMs,
    List<Attachment> attachments = const <Attachment>[],
  }) async {
    final message = Message(
      id: _uuid.v4(),
      conversationId: conversationId,
      senderId: senderId,
      body: body,
      type: type,
      deliveryState: deliveryState,
      createdAt: DateTime.now(),
      isOutgoing: true,
      burnAfterRead: burnAfterRead,
      expiresAt: _ephemeralManager.resolveExpiry(
        burnAfterRead: burnAfterRead,
        explicitTtl: ttl,
      ),
      replyToMessageId: replyToMessageId,
      replyToBody: replyToBody,
      audioFilePath: audioFilePath,
      audioDurationMs: audioDurationMs,
      attachments: attachments,
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

  Future<void> updateReactions(
    String messageId,
    Map<String, List<String>> reactions,
  ) {
    return _messageDatabase.updateReactions(messageId, reactions);
  }

  Future<void> updateMessageContent({
    required String messageId,
    required String body,
    required DateTime editedAt,
  }) {
    return _messageDatabase.updateMessageContent(
      messageId: messageId,
      body: body,
      editedAt: editedAt,
    );
  }

  Future<void> markMessageDeleted({
    required String messageId,
    required DateTime deletedAt,
    required MessageDeleteMode mode,
  }) async {
    final existingMessage = await _messageDatabase.getMessage(messageId);
    await _messageDatabase.markMessageDeleted(
      messageId: messageId,
      deletedAt: deletedAt,
      mode: mode,
    );
    await _deleteStoredFiles(existingMessage);
  }

  Future<void> deleteMessage(String messageId) async {
    final existingMessage = await _messageDatabase.getMessage(messageId);
    await _messageDatabase.deleteMessage(messageId);
    await _deleteStoredFiles(existingMessage);
  }

  Future<void> clearConversation(String conversationId) async {
    final storedFilePaths = await _messageDatabase.listStoredFilePaths(
      conversationId: conversationId,
    );
    await _messageDatabase.deleteConversation(conversationId);
    await _deleteFiles(storedFilePaths);
  }

  Future<void> wipeAllLocalData() async {
    final storedFilePaths = await _messageDatabase.listStoredFilePaths();
    await _messageDatabase.clearAllData();
    await _deleteFiles(storedFilePaths);
  }

  Future<void> toggleStar(String messageId) {
    return _messageDatabase.toggleStar(messageId);
  }

  Future<List<Message>> listStarredMessages() {
    return _messageDatabase.listStarredMessages();
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

  Future<void> _deleteAudioFileIfPresent(String? filePath) async {
    if (filePath == null || filePath.trim().isEmpty) {
      return;
    }

    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> _deleteAudioFiles(Iterable<String> filePaths) async {
    for (final filePath in filePaths) {
      await _deleteAudioFileIfPresent(filePath);
    }
  }

  Future<void> _deleteStoredFiles(Message? message) async {
    if (message == null) {
      return;
    }

    final filePaths = <String>{
      if (message.audioFilePath != null && message.audioFilePath!.trim().isNotEmpty)
        message.audioFilePath!,
      for (final attachment in message.attachments)
        if (attachment.hasFilePath) attachment.filePath!,
    };
    await _deleteFiles(filePaths);
  }

  Future<void> _deleteFiles(Iterable<String> filePaths) async {
    await _deleteAudioFiles(filePaths);
  }
}
