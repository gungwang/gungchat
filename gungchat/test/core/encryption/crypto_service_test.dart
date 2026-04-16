import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/core/encryption/crypto_service.dart';

void main() {
  test('encrypts and decrypts across derived shared secrets', () async {
    final crypto = CryptoService();
    final alice = await crypto.generateIdentityKeyPair();
    final bob = await crypto.generateIdentityKeyPair();

    final aliceSharedSecret = await crypto.deriveSharedSecret(
      localPrivateKey: Uint8List.fromList(alice.bytes),
      localPublicKey: Uint8List.fromList(alice.publicKey.bytes),
      remotePublicKey: Uint8List.fromList(bob.publicKey.bytes),
    );

    final bobSharedSecret = await crypto.deriveSharedSecret(
      localPrivateKey: Uint8List.fromList(bob.bytes),
      localPublicKey: Uint8List.fromList(bob.publicKey.bytes),
      remotePublicKey: Uint8List.fromList(alice.publicKey.bytes),
    );

    final encrypted = await crypto.encryptString(
      plaintext: 'hello gungchat',
      secretKey: aliceSharedSecret,
    );

    final decrypted = await crypto.decryptString(
      payload: encrypted,
      secretKey: bobSharedSecret,
    );

    expect(decrypted, 'hello gungchat');
  });
}