import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/security/contact_block_service.dart';

class _FakeContactBlockStore implements ContactBlockStore {
  _FakeContactBlockStore([Set<String>? initial])
      : _blocked = <String>{...?(initial)};

  Set<String> _blocked;

  @override
  Future<Set<String>> loadBlockedFingerprints() async => _blocked;

  @override
  Future<void> saveBlockedFingerprints(Set<String> fingerprints) async {
    _blocked = <String>{...fingerprints};
  }
}

void main() {
  test('blocks and unblocks contacts through the controller', () async {
    final controller = ContactBlockController(
      storage: _FakeContactBlockStore(),
    );
    addTearDown(controller.dispose);

    await controller.blockContact('aa:bb:cc:dd');
    expect(controller.isBlocked('aa:bb:cc:dd'), isTrue);

    await controller.unblockContact('aa:bb:cc:dd');
    expect(controller.isBlocked('aa:bb:cc:dd'), isFalse);
  });
}