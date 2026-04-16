class IceServerConfig {
  const IceServerConfig({
    required this.urls,
    this.username,
    this.credential,
  });

  final List<String> urls;
  final String? username;
  final String? credential;

  Map<String, dynamic> toMap() {
    return {
      'urls': urls,
      if (username != null) 'username': username,
      if (credential != null) 'credential': credential,
    };
  }
}

class IceManager {
  const IceManager({this.turnServers = const []});

  final List<IceServerConfig> turnServers;

  Map<String, dynamic> buildConfiguration() {
    return {
      'iceServers': [
        const IceServerConfig(urls: ['stun:stun.l.google.com:19302']).toMap(),
        const IceServerConfig(urls: ['stun:stun.cloudflare.com:3478']).toMap(),
        ...turnServers.map((server) => server.toMap()),
      ],
      'sdpSemantics': 'unified-plan',
    };
  }
}
