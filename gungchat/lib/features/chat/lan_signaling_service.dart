import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../core/encryption/key_manager.dart';
import '../contacts/contact_exchange_service.dart';
import '../contacts/discovery_service.dart';

typedef ResolveTargetAddress = Future<String> Function(String targetAddress);

class LanReceivedSignal {
  const LanReceivedSignal({
    required this.signal,
    this.senderContactPayload,
  });

  final String signal;
  final String? senderContactPayload;
}

class LanSignalingService {
  LanSignalingService({
    ContactExchangeService? contactExchangeService,
    ResolveTargetAddress? resolveTargetAddress,
    this.listenPort = DiscoveryService.discoveryPort,
  }) : _contactExchangeService =
           contactExchangeService ?? const ContactExchangeService(),
       _resolveTargetAddress = resolveTargetAddress;

  final ContactExchangeService _contactExchangeService;
  final ResolveTargetAddress? _resolveTargetAddress;
  final int listenPort;

  final StreamController<LanReceivedSignal> _signalController =
      StreamController<LanReceivedSignal>.broadcast();

  ServerSocket? _server;
  StreamSubscription<Socket>? _serverSubscription;
  Future<void>? _startupFuture;

  Stream<LanReceivedSignal> get signals => _signalController.stream;

  Future<void> ensureListening() {
    final startupFuture = _startupFuture;
    if (startupFuture != null) {
      return startupFuture;
    }

    final nextStartup = _startListening();
    _startupFuture = nextStartup;
    return nextStartup;
  }

  Future<void> sendSignal({
    required String encodedSignal,
    required String targetAddress,
    required DeviceIdentity identity,
    String? displayName,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    await ensureListening();

    final resolvedTargetAddress = _resolveTargetAddress == null
        ? targetAddress
        : await _resolveTargetAddress(targetAddress);
    final target = _parseTargetAddress(resolvedTargetAddress);
    final contactCard = await _contactExchangeService.buildLocalContactCard(
      identity: identity,
      displayName: _contactExchangeService.resolveDisplayName(
        identity: identity,
        preferredDisplayName: displayName,
      ),
      port: listenPort,
    );
    final packet = _LanSignalPacket(
      signal: encodedSignal,
      senderContactPayload:
          _contactExchangeService.buildQrReadyPayload(contactCard),
    );
    final socket = await Socket.connect(
      target.host,
      target.port,
      timeout: timeout,
    );

    try {
      socket.write(jsonEncode(packet.toJson()));
      await socket.flush();
    } finally {
      await socket.close();
    }
  }

  void dispose() {
    unawaited(_serverSubscription?.cancel());
    unawaited(_server?.close());
    unawaited(_signalController.close());
    _serverSubscription = null;
    _server = null;
    _startupFuture = null;
  }

  Future<void> _startListening() async {
    try {
      if (_server != null) {
        return;
      }

      _server = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        listenPort,
        shared: true,
      );
      _serverSubscription = _server!.listen(
        _handleSocket,
        onError: _signalController.addError,
      );
    } catch (error) {
      _startupFuture = null;
      rethrow;
    }
  }

  void _handleSocket(Socket socket) {
    final bytes = BytesBuilder(copy: false);
    socket.listen(
      bytes.add,
      onDone: () {
        try {
          final rawPayload = utf8.decode(bytes.takeBytes()).trim();
          if (rawPayload.isEmpty) {
            return;
          }

          final packet = _LanSignalPacket.fromJson(
            jsonDecode(rawPayload) as Map<String, dynamic>,
          );
          _signalController.add(
            LanReceivedSignal(
              signal: packet.signal,
              senderContactPayload: packet.senderContactPayload,
            ),
          );
        } on FormatException {
          // Ignore malformed inbound packets and keep the listener running.
        } finally {
          socket.destroy();
        }
      },
      onError: (_) => socket.destroy(),
      cancelOnError: true,
    );
  }

  _LanRouteTarget _parseTargetAddress(String targetAddress) {
    final trimmed = targetAddress.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Target address is empty.');
    }

    final separatorIndex = trimmed.lastIndexOf(':');
    if (separatorIndex <= 0 || separatorIndex == trimmed.length - 1) {
      return _LanRouteTarget(host: trimmed, port: listenPort);
    }

    final host = trimmed.substring(0, separatorIndex).trim();
    final port = int.tryParse(trimmed.substring(separatorIndex + 1).trim());
    if (host.isEmpty || port == null) {
      throw FormatException('Invalid target address: $targetAddress');
    }

    return _LanRouteTarget(host: host, port: port);
  }
}

class _LanSignalPacket {
  const _LanSignalPacket({
    required this.signal,
    this.senderContactPayload,
  });

  final String signal;
  final String? senderContactPayload;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': 1,
      'signal': signal,
      'senderContactPayload': senderContactPayload,
    };
  }

  factory _LanSignalPacket.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported LAN signaling packet version.');
    }

    final signal = (json['signal'] as String?)?.trim();
    if (signal == null || signal.isEmpty) {
      throw const FormatException('LAN signaling packet is missing a signal.');
    }

    return _LanSignalPacket(
      signal: signal,
      senderContactPayload: json['senderContactPayload'] as String?,
    );
  }
}

class _LanRouteTarget {
  const _LanRouteTarget({
    required this.host,
    required this.port,
  });

  final String host;
  final int port;
}