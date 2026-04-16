import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class EncryptedPayload {
  const EncryptedPayload({
    required this.nonce,
    required this.cipherText,
    required this.mac,
  });

  final Uint8List nonce;
  final Uint8List cipherText;
  final Uint8List mac;

  Map<String, String> toJson() {
    return {
      'nonce': base64Encode(nonce),
      'cipherText': base64Encode(cipherText),
      'mac': base64Encode(mac),
    };
  }

  String encodeTransportString() => jsonEncode(toJson());

  factory EncryptedPayload.fromJson(Map<String, dynamic> json) {
    return EncryptedPayload(
      nonce: base64Decode(json['nonce'] as String),
      cipherText: base64Decode(json['cipherText'] as String),
      mac: base64Decode(json['mac'] as String),
    );
  }

  factory EncryptedPayload.decodeTransportString(String value) {
    return EncryptedPayload.fromJson(
      jsonDecode(value) as Map<String, dynamic>,
    );
  }
}

class CryptoService {
  CryptoService({
    X25519? keyExchange,
    Cipher? cipher,
    Random? random,
  })  : _keyExchange = keyExchange ?? X25519(),
        _cipher = cipher ?? Chacha20.poly1305Aead(),
        _random = random ?? Random.secure();

  final X25519 _keyExchange;
  final Cipher _cipher;
  final Random _random;

  Future<SimpleKeyPairData> generateIdentityKeyPair() async {
    final keyPair = await _keyExchange.newKeyPair();
    return await keyPair.extract();
  }

  Future<SecretKey> deriveSharedSecret({
    required Uint8List localPrivateKey,
    required Uint8List localPublicKey,
    required Uint8List remotePublicKey,
  }) {
    final localKeyPair = SimpleKeyPairData(
      localPrivateKey,
      publicKey: SimplePublicKey(localPublicKey, type: KeyPairType.x25519),
      type: KeyPairType.x25519,
    );

    return _keyExchange.sharedSecretKey(
      keyPair: localKeyPair,
      remotePublicKey: SimplePublicKey(
        remotePublicKey,
        type: KeyPairType.x25519,
      ),
    );
  }

  Future<EncryptedPayload> encryptString({
    required String plaintext,
    required SecretKey secretKey,
  }) async {
    final secretBox = await _cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: _randomBytes(_cipher.nonceLength),
    );

    return EncryptedPayload(
      nonce: Uint8List.fromList(secretBox.nonce),
      cipherText: Uint8List.fromList(secretBox.cipherText),
      mac: Uint8List.fromList(secretBox.mac.bytes),
    );
  }

  Future<String?> decryptString({
    required EncryptedPayload payload,
    required SecretKey secretKey,
  }) async {
    try {
      final bytes = await _cipher.decrypt(
        SecretBox(
          payload.cipherText,
          nonce: payload.nonce,
          mac: Mac(payload.mac),
        ),
        secretKey: secretKey,
      );

      return utf8.decode(bytes);
    } on SecretBoxAuthenticationError {
      return null;
    }
  }

  List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }
}
