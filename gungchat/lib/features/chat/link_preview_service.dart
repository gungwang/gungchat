import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LinkPreview {
  const LinkPreview({
    required this.url,
    required this.title,
    this.description,
    this.imageUrl,
  });

  final String url;
  final String title;
  final String? description;
  final String? imageUrl;

  Map<String, String?> toJson() {
    return <String, String?>{
      'url': url,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  factory LinkPreview.fromJson(Map<String, dynamic> json) {
    return LinkPreview(
      url: json['url'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class LinkPreviewService {
  LinkPreviewService({
    http.Client? client,
    Future<SharedPreferences> Function()? loadPreferences,
    this.timeout = const Duration(seconds: 5),
  })  : _client = client ?? http.Client(),
        _loadPreferences = loadPreferences ?? SharedPreferences.getInstance;

  static final RegExp _urlPattern = RegExp(
    r'(https?:\/\/[^\s<>{}"|\\^`\[\]]+)',
    caseSensitive: false,
  );

  static const String _cachePrefix = 'linkPreviewCache.';

  final http.Client _client;
  final Future<SharedPreferences> Function() _loadPreferences;
  final Duration timeout;
  final Map<String, LinkPreview?> _memoryCache = <String, LinkPreview?>{};

  static String? extractFirstUrl(String body) {
    final match = _urlPattern.firstMatch(body);
    if (match == null) {
      return null;
    }

    final candidate = match.group(0);
    if (candidate == null) {
      return null;
    }

    return candidate.replaceFirst(RegExp(r'[),.!?:;]+$'), '');
  }

  Future<LinkPreview?> fetchPreview(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }

    if (_memoryCache.containsKey(rawUrl)) {
      return _memoryCache[rawUrl];
    }

    final cachedPreview = await _loadCachedPreview(rawUrl);
    if (cachedPreview != null) {
      _memoryCache[rawUrl] = cachedPreview;
      return cachedPreview;
    }

    try {
      final response = await _client.get(
        uri,
        headers: const <String, String>{
          'User-Agent': 'GungChat/1.0',
        },
      ).timeout(timeout);

      if (response.statusCode != 200) {
        _memoryCache[rawUrl] = null;
        return null;
      }

      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('text/html') && !contentType.contains('application/xhtml+xml')) {
        _memoryCache[rawUrl] = null;
        return null;
      }

      final document = html_parser.parse(response.body);
      String? title = _readMetaContent(document, 'og:title') ??
          _readMetaContent(document, 'twitter:title') ??
          document.querySelector('title')?.text.trim();
      String? description = _readMetaContent(document, 'og:description') ??
          _readMetaContent(document, 'description') ??
          _readMetaContent(document, 'twitter:description');
      String? imageUrl = _readMetaContent(document, 'og:image') ??
          _readMetaContent(document, 'twitter:image');

      title = _normalizeValue(title);
      description = _normalizeValue(description);
      imageUrl = _normalizeValue(imageUrl);
      if (title == null) {
        _memoryCache[rawUrl] = null;
        return null;
      }

      final resolvedImageUrl = imageUrl == null
          ? null
          : response.request?.url.resolve(imageUrl).toString();

      final preview = LinkPreview(
        url: rawUrl,
        title: title,
        description: description,
        imageUrl: resolvedImageUrl,
      );
      _memoryCache[rawUrl] = preview;
      await _saveCachedPreview(preview);
      return preview;
    } catch (_) {
      _memoryCache[rawUrl] = null;
      return null;
    }
  }

  void dispose() {
    _client.close();
  }

  Future<LinkPreview?> _loadCachedPreview(String rawUrl) async {
    final preferences = await _loadPreferences();
    final encoded = preferences.getString(_cacheKey(rawUrl));
    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    try {
      return LinkPreview.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCachedPreview(LinkPreview preview) async {
    final preferences = await _loadPreferences();
    await preferences.setString(
      _cacheKey(preview.url),
      jsonEncode(preview.toJson()),
    );
  }

  String _cacheKey(String rawUrl) {
    return '$_cachePrefix${base64UrlEncode(utf8.encode(rawUrl))}';
  }

  static String? _readMetaContent(dynamic document, String property) {
    final normalizedProperty = property.toLowerCase();
    final metaTags = document.getElementsByTagName('meta');
    for (final tag in metaTags) {
      final key = (tag.attributes['property'] ?? tag.attributes['name'])
          ?.toLowerCase();
      if (key == normalizedProperty) {
        return tag.attributes['content'];
      }
    }
    return null;
  }

  static String? _normalizeValue(String? value) {
    final trimmed = value?.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}