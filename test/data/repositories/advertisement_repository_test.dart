import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/data/models/advertisement.dart';
import 'package:musamimuk/data/repositories/advertisement_repository.dart';

void main() {
  setUp(AdvertisementRepository.debugResetCache);

  group('Advertisement.parseListFromResponseBody', () {
    test('parses nested data.advertisements (not top-level data list)', () {
      final body = <String, dynamic>{
        'success': true,
        'data': {
          'placement': 'home_banner',
          'platform': 'android',
          'advertisements': [
            {
              'id': 1,
              'title': 'advertise01',
              'placement': 'home_banner',
              'media_type': 'image',
              'media_url':
                  'https://srv1813447.hstgr.cloud/storage/advertisements/image/example.png',
              'link_url': null,
              'status': 'active',
              'is_active': true,
            },
          ],
        },
      };

      final ads = Advertisement.parseListFromResponseBody(body);
      expect(ads, hasLength(1));
      expect(ads.single.id, 1);
      expect(ads.single.title, 'advertise01');
      expect(ads.single.placement, 'home_banner');
      expect(ads.single.mediaType, 'image');
      expect(
        ads.single.mediaUrl,
        'https://srv1813447.hstgr.cloud/storage/advertisements/image/example.png',
      );
      expect(ads.single.linkUrl, isNull);
    });

    test('returns empty when advertisements list is empty', () {
      final ads = Advertisement.parseListFromResponseBody({
        'success': true,
        'data': {'placement': 'home_banner', 'advertisements': <dynamic>[]},
      });
      expect(ads, isEmpty);
    });

    test('skips rows with null/empty media_url', () {
      final ads = Advertisement.parseListFromResponseBody({
        'success': true,
        'data': {
          'advertisements': [
            {
              'id': 1,
              'title': 'No media',
              'placement': 'home_banner',
              'media_type': 'image',
              'media_url': null,
            },
            {
              'id': 2,
              'title': 'Empty media',
              'placement': 'home_banner',
              'media_type': 'image',
              'media_url': '   ',
            },
            {
              'id': 3,
              'title': 'Ok',
              'placement': 'home_banner',
              'media_type': 'image',
              'media_url': 'https://example.test/a.png',
            },
          ],
        },
      });
      expect(ads.map((a) => a.id), [3]);
    });

    test('parses multiple advertisements', () {
      final ads = Advertisement.parseListFromResponseBody({
        'success': true,
        'data': {
          'advertisements': [
            {
              'id': 1,
              'title': 'A',
              'placement': 'home_banner',
              'media_type': 'image',
              'media_url': 'https://example.test/a.png',
              'link_url': 'https://example.test/a',
              'advertiser_name': 'Brand A',
              'description': 'Desc A',
            },
            {
              'id': 2,
              'title': 'B',
              'placement': 'home_banner',
              'media_type': 'image',
              'media_url': 'https://example.test/b.png',
              'video_url': null,
            },
          ],
        },
      });
      expect(ads, hasLength(2));
      expect(ads.first.advertiserName, 'Brand A');
      expect(ads.first.description, 'Desc A');
      expect(ads.first.linkUrl, 'https://example.test/a');
      expect(ads.last.title, 'B');
    });

    test('does not treat top-level data array as advertisements', () {
      final ads = Advertisement.parseListFromResponseBody({
        'success': true,
        'data': [
          {
            'id': 9,
            'title': 'Wrong shape',
            'placement': 'home_banner',
            'media_type': 'image',
            'media_url': 'https://example.test/x.png',
          },
        ],
      });
      expect(ads, isEmpty);
    });
  });

  group('AdvertisementRepository.fetchAds', () {
    test('loads one image banner from nested payload', () async {
      final repo = AdvertisementRepository(
        dio: _dioReturning({
          'success': true,
          'data': {
            'placement': 'home_banner',
            'platform': 'android',
            'advertisements': [
              {
                'id': 1,
                'title': 'advertise01',
                'placement': 'home_banner',
                'media_type': 'image',
                'media_url': 'https://example.test/ad.png',
                'link_url': null,
              },
            ],
          },
        }),
      );

      final result = await repo.fetchAds(
        placement: 'home_banner',
        platform: 'android',
        limit: 5,
      );

      expect(result, isA<AdvertisementSuccess<List<Advertisement>>>());
      final ads = (result as AdvertisementSuccess<List<Advertisement>>).data;
      expect(ads, hasLength(1));
      expect(ads.single.mediaUrl, 'https://example.test/ad.png');
    });

    test(
      'empty advertisements is success with empty list and not cached',
      () async {
        final repo = AdvertisementRepository(
          dio: _dioReturning({
            'success': true,
            'data': {'placement': 'home_banner', 'advertisements': <dynamic>[]},
          }),
        );

        final result = await repo.fetchAds(
          placement: 'home_banner',
          platform: 'android',
          limit: 5,
        );
        expect(result, isA<AdvertisementSuccess<List<Advertisement>>>());
        expect(
          (result as AdvertisementSuccess<List<Advertisement>>).data,
          isEmpty,
        );
        expect(
          AdvertisementRepository.peekCachedAds(
            placement: 'home_banner',
            platform: 'android',
            limit: 5,
          ),
          isNull,
        );
      },
    );

    test('failed request returns AdvertisementFailure', () async {
      final repo = AdvertisementRepository(dio: _dioRejecting(500));
      final result = await repo.fetchAds(
        placement: 'home_banner',
        platform: 'android',
        limit: 5,
      );
      expect(result, isA<AdvertisementFailure<List<Advertisement>>>());
    });

    test('forceRefresh bypasses non-empty cache', () async {
      var calls = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            calls++;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'advertisements': [
                      {
                        'id': calls,
                        'title': 'Ad $calls',
                        'placement': 'home_banner',
                        'media_type': 'image',
                        'media_url': 'https://example.test/$calls.png',
                      },
                    ],
                  },
                },
              ),
            );
          },
        ),
      );

      final repo = AdvertisementRepository(dio: dio);
      final first = await repo.fetchAds(
        placement: 'home_banner',
        platform: 'android',
        limit: 5,
      );
      final cached = await repo.fetchAds(
        placement: 'home_banner',
        platform: 'android',
        limit: 5,
      );
      final refreshed = await repo.fetchAds(
        placement: 'home_banner',
        platform: 'android',
        limit: 5,
        forceRefresh: true,
      );

      expect(calls, 2);
      expect(
        (first as AdvertisementSuccess<List<Advertisement>>).data.single.id,
        1,
      );
      expect(
        (cached as AdvertisementSuccess<List<Advertisement>>).data.single.id,
        1,
      );
      expect(
        (refreshed as AdvertisementSuccess<List<Advertisement>>).data.single.id,
        2,
      );
    });
  });
}

Dio _dioReturning(Map<String, dynamic> body) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: body,
          ),
        );
      },
    ),
  );
  return dio;
}

Dio _dioRejecting(int status) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: status,
              data: {'success': false, 'message': 'server error'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );
      },
    ),
  );
  return dio;
}
