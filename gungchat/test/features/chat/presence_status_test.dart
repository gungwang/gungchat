import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/features/chat/presence_status.dart';

void main() {
  group('resolveEffectivePresenceStatus', () {
    test('keeps online while the app is resumed', () {
      final status = resolveEffectivePresenceStatus(
        preferredStatus: PeerPresenceStatus.online,
        lifecycleState: AppLifecycleState.resumed,
      );

      expect(status, PeerPresenceStatus.online);
    });

    test('downgrades online to away outside the foreground', () {
      for (final lifecycleState in const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.detached,
      ]) {
        final status = resolveEffectivePresenceStatus(
          preferredStatus: PeerPresenceStatus.online,
          lifecycleState: lifecycleState,
        );

        expect(status, PeerPresenceStatus.away);
      }
    });

    test('preserves explicit away and hidden preferences', () {
      for (final preferredStatus in const [
        PeerPresenceStatus.away,
        PeerPresenceStatus.hidden,
      ]) {
        final status = resolveEffectivePresenceStatus(
          preferredStatus: preferredStatus,
          lifecycleState: AppLifecycleState.resumed,
        );

        expect(status, preferredStatus);
      }
    });
  });
}