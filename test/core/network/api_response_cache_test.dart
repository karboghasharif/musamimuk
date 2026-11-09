import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/core/network/api_cache_interceptor.dart';
import 'package:musamimuk/core/network/api_response_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ApiResponseCache', () {
    test('read returns null when empty', () async {
      final cache = ApiResponseCache.instance;
      await cache.clear();
      expect(await cache.read('missing'), isNull);
    });

    test('write then read returns payload until TTL expires', () async {
      final cache = ApiResponseCache.instance;
      await cache.clear();
      await cache.write(
        'category/list?',
        {'status': 'success', 'dbData': <Object>[]},
        ttl: const Duration(minutes: 5),
      );

      final hit = await cache.read('category/list?');
      expect(hit?['status'], 'success');
      expect(hit?['dbData'], isA<List>());
    });

    test('clearUserScoped drops only |u: keys', () async {
      final cache = ApiResponseCache.instance;
      await cache.clear();
      await cache.write(
        'shape/list?|anon',
        {'ok': true},
        ttl: const Duration(minutes: 5),
      );
      await cache.write(
        'shape/list?|u:abc',
        {'ok': true},
        ttl: const Duration(minutes: 5),
      );

      await cache.clearUserScoped();

      expect(await cache.read('shape/list?|anon'), isNotNull);
      expect(await cache.read('shape/list?|u:abc'), isNull);
    });
  });

  group('debugApiCacheKeyForTest', () {
    test('scopes anon vs token', () {
      expect(
        debugApiCacheKeyForTest(path: 'category/list'),
        'category/list?|anon',
      );
      expect(
        debugApiCacheKeyForTest(path: '/fonts', query: {'page': 1}, token: 't'),
        startsWith('fonts?page=1|u:'),
      );
    });
  });
}
