import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/core/encryption/key_manager.dart';
import 'package:gungchat/features/chat/lan_signaling_service.dart';
import 'package:gungchat/features/contacts/contact_exchange_service.dart';

class _FakeContactExchangeService extends ContactExchangeService {
  const _FakeContactExchangeService(this._port);

  final int _port;

  @override
  Future<ContactCard> buildLocalContactCard({
    required DeviceIdentity identity,
    required String displayName,
    int port = 45454,
  }) async {
    return ContactCard(
      displayName: displayName,
      fingerprint: identity.fingerprint,
      addresses: const <String>['127.0.0.1'],
      port: _port,
      createdAt: DateTime(2026, 4, 30, 9, 15),
    );
  }
}

void main() {
  test('sends and receives a LAN signal packet', () async {
    const listenPort = 45547;
    final service = LanSignalingService(
      contactExchangeService: const _FakeContactExchangeService(listenPort),
      listenPort: listenPort,
    );
    addTearDown(service.dispose);

    await service.ensureListening();

    final receivedSignal = expectLater(
      service.signals,
      emits(
        isA<LanReceivedSignal>()
            .having((signal) => signal.signal, 'signal', 'offer-payload')
            .having(
              (signal) => signal.senderContactPayload,
              'senderContactPayload',
              startsWith('gungchat-contact:'),
            ),
      ),
    );

    await service.sendSignal(
      encodedSignal: 'offer-payload',
      targetAddress: '127.0.0.1:$listenPort',
      identity: DeviceIdentity(
        publicKey: Uint8List(32),
        privateKey: Uint8List(32),
        fingerprint: 'aa:bb:cc:dd',
      ),
      displayName: 'Windows Peer',
    );

    await receivedSignal;
  });

  test('routes outbound signals through a resolved bridge address', () async {
    const listenPort = 45548;
    final service = LanSignalingService(
      contactExchangeService: const _FakeContactExchangeService(listenPort),
      listenPort: listenPort,
      resolveTargetAddress: (_) async => '127.0.0.1:$listenPort',
    );
    addTearDown(service.dispose);

    await service.ensureListening();

    final receivedSignal = expectLater(
      service.signals,
      emits(
        isA<LanReceivedSignal>().having(
          (signal) => signal.signal,
          'signal',
          'bridged-offer',
        ),
      ),
    );

    await service.sendSignal(
      encodedSignal: 'bridged-offer',
      targetAddress: '10.0.2.15:45454',
      identity: DeviceIdentity(
        publicKey: Uint8List(32),
        privateKey: Uint8List(32),
        fingerprint: '11:22:33:44',
      ),
      displayName: 'Android Emulator',
    );

    await receivedSignal;
  });
}