import 'dart:convert';

class ResolvedPeerDeepLink {
  const ResolvedPeerDeepLink({
    required this.uri,
    required this.rawInput,
  });

  final Uri uri;
  final String rawInput;
}

class PeerDeepLinkService {
  const PeerDeepLinkService();

  Uri buildInputUri(String rawInput) {
    return Uri(
      scheme: 'gungchat',
      host: 'handoff',
      queryParameters: <String, String>{
        'input': base64Url.encode(utf8.encode(rawInput)),
      },
    );
  }

  ResolvedPeerDeepLink? resolve(Uri uri) {
    if (uri.scheme != 'gungchat') {
      return null;
    }

    final encodedInput = uri.queryParameters['input'];
    if (encodedInput == null || encodedInput.isEmpty) {
      return null;
    }

    try {
      final normalized = base64Url.normalize(encodedInput);
      final rawInput = utf8.decode(base64Url.decode(normalized)).trim();
      if (rawInput.trim().isEmpty) {
        return null;
      }

      return ResolvedPeerDeepLink(uri: uri, rawInput: rawInput);
    } on FormatException {
      return null;
    }
  }
}