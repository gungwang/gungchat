import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/features/chat/link_preview_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LinkPreviewService', () {
    test('extracts the first http or https URL from a message body', () {
      expect(
        LinkPreviewService.extractFirstUrl(
          'See https://example.com/hello and then http://second.example',
        ),
        'https://example.com/hello',
      );
      expect(
        LinkPreviewService.extractFirstUrl('No links here.'),
        isNull,
      );
    });

    test('fetches preview metadata and reuses cached results', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount += 1;
        return http.Response(
          '''
          <html>
            <head>
              <title>Fallback Title</title>
              <meta property="og:title" content="Example Title" />
              <meta property="og:description" content="Example Description" />
            </head>
          </html>
          ''',
          200,
          headers: const <String, String>{'content-type': 'text/html'},
          request: request,
        );
      });

      final service = LinkPreviewService(client: client);
      final preview = await service.fetchPreview('https://example.com');

      expect(preview, isNotNull);
      expect(preview!.title, 'Example Title');
      expect(preview.description, 'Example Description');
      expect(requestCount, 1);

      final cachedService = LinkPreviewService(client: client);
      final cachedPreview = await cachedService.fetchPreview('https://example.com');

      expect(cachedPreview, isNotNull);
      expect(cachedPreview!.title, 'Example Title');
      expect(requestCount, 1);
    });
  });
}