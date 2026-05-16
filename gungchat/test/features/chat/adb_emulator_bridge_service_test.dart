import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/features/chat/adb_emulator_bridge_service.dart';

void main() {
  test('bridges emulator guest targets through adb forward only', () async {
    final commands = <String>[];
    final service = AdbEmulatorBridgeService(
      enabled: true,
      forwardPort: 45455,
      signalPort: 45454,
      environment: const <String, String>{
        'ANDROID_SDK_ROOT': 'C:\\Android\\Sdk',
      },
      adbExecutable: 'adb.exe',
      runProcess: (executable, arguments) async {
        commands.add('$executable ${arguments.join(' ')}');
        if (arguments.length == 1 && arguments.first == 'devices') {
          return ProcessResult(
            0,
            0,
            'List of devices attached\nemulator-5554\tdevice\n',
            '',
          );
        }

        return ProcessResult(0, 0, '', '');
      },
    );

    final resolvedTarget = await service.resolveTargetAddress('10.0.2.15:45454');

    expect(resolvedTarget, '127.0.0.1:45455');
    expect(commands, contains('adb.exe devices'));
    expect(commands.where((command) => command.contains(' reverse ')), isEmpty);
    expect(
      commands,
      contains('adb.exe -s emulator-5554 forward tcp:45455 tcp:45454'),
    );
  });

  test('leaves non-emulator targets untouched', () async {
    final service = AdbEmulatorBridgeService(
      enabled: true,
      runProcess: (executable, arguments) async {
        fail('adb should not run for non-emulator targets');
      },
    );

    final resolvedTarget = await service.resolveTargetAddress('192.168.1.24:45454');

    expect(resolvedTarget, '192.168.1.24:45454');
  });
}
