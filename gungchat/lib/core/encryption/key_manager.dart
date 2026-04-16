import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_storage.dart';
import 'crypto_service.dart';

@immutable
class DeviceIdentity {
  const DeviceIdentity({
    required this.publicKey,
    required this.privateKey,
    required this.fingerprint,
  });

  final Uint8List publicKey;
  final Uint8List privateKey;
  final String fingerprint;

  SimpleKeyPairData toKeyPairData() {
    return SimpleKeyPairData(
      privateKey,
      publicKey: SimplePublicKey(publicKey, type: KeyPairType.x25519),
      type: KeyPairType.x25519,
    );
  }
}

class KeyManager {
  KeyManager(this._secureStorage, this._cryptoService);

  static const _publicKeyStorageKey = 'identity.public_key';
  static const _privateKeyStorageKey = 'identity.private_key';

  final AppSecureStorage _secureStorage;
  final CryptoService _cryptoService;

  Future<DeviceIdentity> getOrCreateIdentity() async {
    final publicKeyValue = await _secureStorage.read(_publicKeyStorageKey);
    final privateKeyValue = await _secureStorage.read(_privateKeyStorageKey);

    if (publicKeyValue != null && privateKeyValue != null) {
      return _buildIdentity(
        publicKey: base64Decode(publicKeyValue),
        privateKey: base64Decode(privateKeyValue),
      );
    }

    final keyPair = await _cryptoService.generateIdentityKeyPair();
    final publicKey = Uint8List.fromList(keyPair.publicKey.bytes);
    final privateKey = Uint8List.fromList(keyPair.bytes);

    await _secureStorage.write(_publicKeyStorageKey, base64Encode(publicKey));
    await _secureStorage.write(
      _privateKeyStorageKey,
      base64Encode(privateKey),
    );

    return _buildIdentity(publicKey: publicKey, privateKey: privateKey);
  }

  Future<void> clearIdentity() async {
    await _secureStorage.delete(_publicKeyStorageKey);
    await _secureStorage.delete(_privateKeyStorageKey);
  }

  Future<DeviceIdentity> _buildIdentity({
    required Uint8List publicKey,
    required Uint8List privateKey,
  }) async {
    final digest = await Sha256().hash(publicKey);
    final fingerprint = digest.bytes
        .take(8)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(':');

    return DeviceIdentity(
      publicKey: publicKey,
      privateKey: privateKey,
      fingerprint: fingerprint,
    );
  }
}