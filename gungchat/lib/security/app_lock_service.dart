import 'package:local_auth/local_auth.dart';

import '../features/settings/app_lock_preferences.dart';

abstract class AppLockAuthGateway {
  Future<bool> authenticate({required String reason});
}

class LocalAppLockAuthGateway implements AppLockAuthGateway {
  LocalAppLockAuthGateway({LocalAuthentication? localAuthentication})
      : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

class AppLockService {
  AppLockService({
    AppLockAuthGateway? gateway,
    DateTime Function()? now,
  })  : _gateway = gateway ?? LocalAppLockAuthGateway(),
        _now = now ?? DateTime.now;

  final AppLockAuthGateway _gateway;
  final DateTime Function() _now;

  DateTime? _lastUnlockedAt;

  Future<bool> ensureUnlocked({
    required AppLockSettings settings,
    bool force = false,
  }) async {
    if (!settings.enabled) {
      _lastUnlockedAt = null;
      return true;
    }

    final lastUnlockedAt = _lastUnlockedAt;
    if (!force &&
        lastUnlockedAt != null &&
        _now().difference(lastUnlockedAt).inSeconds < settings.timeoutSeconds) {
      return true;
    }

    final success = await _gateway.authenticate(reason: 'Unlock GungChat');
    if (success) {
      _lastUnlockedAt = _now();
    }
    return success;
  }

  void clearSession() {
    _lastUnlockedAt = null;
  }
}