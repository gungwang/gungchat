import 'dart:async';
import 'dart:io';

typedef RunProcess = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

class AdbEmulatorBridgeService {
  AdbEmulatorBridgeService({
    RunProcess? runProcess,
    Map<String, String>? environment,
    this.adbExecutable,
    this.forwardPort = 45455,
    this.signalPort = 45454,
    bool? enabled,
  }) : _runProcess = runProcess ?? Process.run,
       _environment = environment ?? Platform.environment,
       _enabled = enabled ?? Platform.isWindows;

  static const String emulatorSerialEnvVar = 'GUNGCHAT_EMULATOR_SERIAL';

  final RunProcess _runProcess;
  final Map<String, String> _environment;
  final bool _enabled;
  final String? adbExecutable;
  final int forwardPort;
  final int signalPort;

  Future<String>? _bridgeFuture;

  Future<String> resolveTargetAddress(String targetAddress) async {
    final parsedAddress = _parseTargetAddress(targetAddress);
    if (!_enabled || !_isEmulatorGuestAddress(parsedAddress.host)) {
      return targetAddress;
    }

    return _ensureBridge();
  }

  Future<String> _ensureBridge() {
    final bridgeFuture = _bridgeFuture;
    if (bridgeFuture != null) {
      return bridgeFuture;
    }

    final nextBridge = _createBridge();
    _bridgeFuture = nextBridge;
    return nextBridge;
  }

  Future<String> _createBridge() async {
    final adbPath = _resolveAdbExecutable();
    final emulatorSerial = await _resolveEmulatorSerial(adbPath);

    await _runChecked(
      adbPath,
      <String>[
        '-s',
        emulatorSerial,
        'forward',
        'tcp:$forwardPort',
        'tcp:$signalPort',
      ],
    );

    return '127.0.0.1:$forwardPort';
  }

  String _resolveAdbExecutable() {
    final configuredExecutable = adbExecutable?.trim();
    if (configuredExecutable != null && configuredExecutable.isNotEmpty) {
      return configuredExecutable;
    }

    final sdkRoots = <String?>[
      _environment['ANDROID_SDK_ROOT'],
      _environment['ANDROID_HOME'],
      _environment['LOCALAPPDATA'] == null
          ? null
          : '${_environment['LOCALAPPDATA']}\\Android\\Sdk',
    ];

    for (final sdkRoot in sdkRoots) {
      if (sdkRoot == null || sdkRoot.isEmpty) {
        continue;
      }

      final candidate = '$sdkRoot\\platform-tools\\adb.exe';
      if (File(candidate).existsSync()) {
        return candidate;
      }
    }

    return 'adb';
  }

  Future<String> _resolveEmulatorSerial(String adbPath) async {
    final preferredSerial = _environment[emulatorSerialEnvVar]?.trim();
    if (preferredSerial != null && preferredSerial.isNotEmpty) {
      return preferredSerial;
    }

    final result = await _runChecked(adbPath, const <String>['devices']);
    final lines = result.stdout.toString().split(RegExp(r'\r?\n'));
    for (final line in lines) {
      final match = RegExp(r'^(emulator-\d+)\s+device$').firstMatch(
        line.trim(),
      );
      if (match != null) {
        return match.group(1)!;
      }
    }

    throw StateError(
      'No running Android emulator was found for ADB port forwarding.',
    );
  }

  Future<ProcessResult> _runChecked(
    String executable,
    List<String> arguments,
  ) async {
    final result = await _runProcess(executable, arguments);
    if (result.exitCode == 0) {
      return result;
    }

    throw ProcessException(
      executable,
      arguments,
      result.stderr.toString().trim(),
      result.exitCode,
    );
  }

  bool _isEmulatorGuestAddress(String host) {
    return host.startsWith('10.0.2.');
  }

  _TargetAddress _parseTargetAddress(String targetAddress) {
    final trimmed = targetAddress.trim();
    final separatorIndex = trimmed.lastIndexOf(':');
    if (separatorIndex <= 0 || separatorIndex == trimmed.length - 1) {
      return _TargetAddress(host: trimmed, port: signalPort);
    }

    final host = trimmed.substring(0, separatorIndex).trim();
    final port = int.tryParse(trimmed.substring(separatorIndex + 1).trim());
    if (host.isEmpty || port == null) {
      throw FormatException('Invalid target address: $targetAddress');
    }

    return _TargetAddress(host: host, port: port);
  }
}

class _TargetAddress {
  const _TargetAddress({
    required this.host,
    required this.port,
  });

  final String host;
  final int port;
}
