import 'dart:convert';

import '../../models/contact.dart';

enum PeerInvitationKind {
  invite,
  reply,
}

class ParsedPeerInvitation {
  const ParsedPeerInvitation({
    required this.kind,
    required this.displayName,
    required this.expectedFingerprint,
    required this.savedAddress,
    required this.manualUriText,
    required this.sessionId,
    required this.offerSignal,
    required this.answerSignal,
    required this.iceSignals,
  });

  final PeerInvitationKind kind;
  final String? displayName;
  final String? expectedFingerprint;
  final String? savedAddress;
  final String? manualUriText;
  final String? sessionId;
  final String? offerSignal;
  final String? answerSignal;
  final List<String> iceSignals;

  Uri? get manualUri {
    final value = manualUriText;
    if (value == null || value.isEmpty) {
      return null;
    }

    return Uri.tryParse(value);
  }

  String? get resolvedAddress {
    if (savedAddress != null && savedAddress!.isNotEmpty) {
      return savedAddress;
    }

    final uri = manualUri;
    if (uri == null || uri.host.isEmpty || !uri.hasPort) {
      return null;
    }

    return '${uri.host}:${uri.port}';
  }

  List<String> get signalsInApplyOrder {
    return [
      if (offerSignal != null) offerSignal!,
      if (answerSignal != null) answerSignal!,
      ...iceSignals,
    ];
  }

  Contact? toContact() {
    final displayName = this.displayName;
    final fingerprint = expectedFingerprint;
    if (displayName == null || displayName.isEmpty) {
      return null;
    }
    if (fingerprint == null || fingerprint.isEmpty) {
      return null;
    }

    return Contact(
      id: fingerprint,
      displayName: displayName,
      fingerprint: fingerprint,
      lastKnownAddress: resolvedAddress,
    );
  }
}

class PeerInvitationParser {
  const PeerInvitationParser();

  ParsedPeerInvitation parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Invitation text is empty.');
    }

    final lines = const LineSplitter()
        .convert(trimmed)
        .map((line) => line.trim())
        .toList(growable: false);
    final firstLine = lines.first;

    final kind = switch (firstLine) {
      'GungChat connection invite' => PeerInvitationKind.invite,
      'GungChat connection reply' => PeerInvitationKind.reply,
      _ => throw const FormatException(
          'This text is not a GungChat invitation or reply.',
        ),
    };

    String? displayName;
    String? expectedFingerprint;
    String? savedAddress;
    String? manualUriText;
    String? sessionId;
    final offerLines = <String>[];
    final answerLines = <String>[];
    final iceSignals = <String>[];
    var section = _PeerInvitationSection.metadata;

    for (final line in lines.skip(1)) {
      if (line.isEmpty) {
        continue;
      }

      final nextSection = _parseSection(line);
      if (nextSection != null) {
        section = nextSection;
        continue;
      }

      switch (section) {
        case _PeerInvitationSection.metadata:
          if (line.startsWith('Contact: ')) {
            displayName = line.substring('Contact: '.length).trim();
          } else if (line.startsWith('Expected fingerprint: ')) {
            expectedFingerprint =
                line.substring('Expected fingerprint: '.length).trim();
          } else if (line.startsWith('Saved address: ')) {
            savedAddress = line.substring('Saved address: '.length).trim();
          } else if (line.startsWith('Manual URI: ')) {
            manualUriText = line.substring('Manual URI: '.length).trim();
          } else if (line.startsWith('Session: ')) {
            sessionId = line.substring('Session: '.length).trim();
          }
        case _PeerInvitationSection.offer:
          offerLines.add(line);
        case _PeerInvitationSection.answer:
          answerLines.add(line);
        case _PeerInvitationSection.ice:
          iceSignals.add(line);
      }
    }

    final offerSignal = _normalizedSignal(offerLines);
    final answerSignal = _normalizedSignal(answerLines);

    return ParsedPeerInvitation(
      kind: kind,
      displayName: displayName,
      expectedFingerprint: expectedFingerprint,
      savedAddress: savedAddress,
      manualUriText: manualUriText,
      sessionId: sessionId,
      offerSignal: offerSignal,
      answerSignal: answerSignal,
      iceSignals: List<String>.unmodifiable(iceSignals),
    );
  }

  _PeerInvitationSection? _parseSection(String line) {
    return switch (line) {
      'OFFER:' => _PeerInvitationSection.offer,
      'ANSWER:' => _PeerInvitationSection.answer,
      'ICE PAYLOADS:' => _PeerInvitationSection.ice,
      _ => null,
    };
  }

  String? _normalizedSignal(List<String> lines) {
    if (lines.isEmpty) {
      return null;
    }

    final value = lines.join('\n').trim();
    return value.isEmpty ? null : value;
  }
}

enum _PeerInvitationSection {
  metadata,
  offer,
  answer,
  ice,
}