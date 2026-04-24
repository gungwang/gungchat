import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/features/settings/app_lock_preferences.dart';
import 'package:gungchat/security/app_lock_service.dart';

class _FakeAppLockAuthGateway implements AppLockAuthGateway {
  _FakeAppLockAuthGateway({this.nextResult = true});

  bool nextResult;
  int calls = 0;

  @override
  Future<bool> authenticate({required String reason}) async {
    calls += 1;
    return nextResult;
  }
}

void main() {
  test('skips authentication when app lock is disabled', () async {
    final gateway = _FakeAppLockAuthGateway(nextResult: true);
    final service = AppLockService(
      gateway: gateway,
      now: () => DateTime.utc(2026, 4, 24, 12, 0),
    );

    final unlocked = await service.ensureUnlocked(
      settings: const AppLockSettings(enabled: false),
    );

    expect(unlocked, isTrue);
    expect(gateway.calls, 0);
  });

  test('reuses recent unlock inside the timeout window', () async {
    var clock = DateTime.utc(2026, 4, 24, 12, 0);
    final gateway = _FakeAppLockAuthGateway();
    final service = AppLockService(
      gateway: gateway,
      now: () => clock,
    );

    final settings = const AppLockSettings(enabled: true, timeoutSeconds: 60);
    expect(await service.ensureUnlocked(settings: settings, force: true), isTrue);
    clock = clock.add(const Duration(seconds: 30));
    expect(await service.ensureUnlocked(settings: settings), isTrue);
    expect(gateway.calls, 1);
  });
}