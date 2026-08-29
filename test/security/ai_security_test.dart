import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/authenticated_image.dart';

void main() {
  test('Flutter sources contain no vendor endpoints or API key defines', () {
    final source = _readDartSources(Directory('lib'));
    const forbidden = [
      'api.openai.com',
      'generativelanguage.googleapis.com',
      'OPENAI_API_KEY',
      'GEMINI_API_KEY',
      'OPENAI_IMAGE_MODEL',
      'EDITOR_AI_PROXY_BASE',
      'X-goog-api-key',
    ];

    for (final marker in forbidden) {
      expect(source, isNot(contains(marker)), reason: marker);
    }
  });

  test('AI sources do not log prompts or base64 bodies', () {
    final source = _readDartSources(Directory('lib/data/services/editor_ai'));

    expect(source, isNot(contains('debugPrint(')));
    expect(source, isNot(contains('print(')));

    final apiClient = File(
      'lib/core/network/api_client.dart',
    ).readAsStringSync();
    expect(apiClient, contains("'prompt'"));
    expect(apiClient, contains("'messages'"));
    expect(apiClient, contains("'contents'"));
    expect(apiClient, contains("'b64_json'"));
    expect(apiClient, contains("'authorization'"));
  });

  test('generated asset image headers include only Musamimuk bearer token', () {
    expect(
      musamiAuthenticatedHeadersForUrl(
        '${baseUrl}ai/assets/asset-1',
        token: 'user-token',
      ),
      {'Authorization': 'Bearer user-token'},
    );
    expect(
      musamiAuthenticatedHeadersForUrl(
        'https://srv1813447.hstgr.cloud/storage/designs/demo.jpg',
        token: 'user-token',
      ),
      {'Authorization': 'Bearer user-token'},
    );
    expect(
      musamiAuthenticatedHeadersForUrl(
        'https://untrusted.example/asset.png',
        token: 'user-token',
      ),
      isEmpty,
    );
    expect(isTrustedMusamimukUri(Uri.parse(baseUrl)), isTrue);
    expect(
      isTrustedMusamimukUri(Uri.parse('https://untrusted.example/file')),
      isFalse,
    );
  });

  test('authentication token is persisted through secure storage', () {
    final prefs = File('lib/core/utils/pref_utils.dart').readAsStringSync();
    final secure = File(
      'lib/core/session/secure_token_storage.dart',
    ).readAsStringSync();

    expect(prefs, contains('SecureTokenStorage.instance.writeToken'));
    expect(prefs, isNot(contains("setString(_keyToken")));
    expect(secure, contains('FlutterSecureStorage'));
  });

  test(
    'legacy background-removal services contain no credentials or egress',
    () {
      final huggingFace = File(
        'lib/core/services/hugging_face_service.dart',
      ).readAsStringSync();
      final removeBg = File(
        'lib/core/services/remove_bg_service.dart',
      ).readAsStringSync();

      expect(huggingFace, isNot(contains('api-inference')));
      expect(huggingFace, isNot(matches(RegExp(r'hf_[A-Za-z0-9]{20,}'))));
      expect(removeBg, isNot(contains('privateKey')));
      expect(removeBg, isNot(matches(RegExp(r'static const String _apiKey'))));
    },
  );
}

String _readDartSources(Directory directory) {
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .map((file) => file.readAsStringSync())
      .join('\n');
}
