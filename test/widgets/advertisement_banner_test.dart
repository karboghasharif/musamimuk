import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/core/utils/size_utils.dart';
import 'package:musamimuk/data/repositories/advertisement_repository.dart';
import 'package:musamimuk/widgets/advertisement_banner.dart';

final Uint8List _kTinyPng = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ),
);

void main() {
  setUp(AdvertisementRepository.debugResetCache);
  tearDown(() {
    HttpOverrides.global = null;
    AdvertisementRepository.debugResetCache();
  });

  Future<void> pumpBanner(
    WidgetTester tester, {
    required AdvertisementRepository repository,
    int autoAdvanceSeconds = 0,
  }) async {
    await tester.pumpWidget(
      Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            home: Scaffold(
              body: AdvertisementBanner(
                placement: 'home_banner',
                limit: 5,
                repository: repository,
                autoAdvanceSeconds: autoAdvanceSeconds,
              ),
            ),
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('shows one image banner', (tester) async {
    HttpOverrides.global = _PngHttpOverrides();
    await pumpBanner(
      tester,
      repository: AdvertisementRepository(
        dio: _adsDio(_oneAdBody(mediaUrl: 'https://example.test/ad.png')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('hides when advertisements list is empty', (tester) async {
    await pumpBanner(
      tester,
      repository: AdvertisementRepository(
        dio: _adsDio({
          'success': true,
          'data': {'placement': 'home_banner', 'advertisements': <dynamic>[]},
        }),
      ),
    );
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('hides when request fails', (tester) async {
    await pumpBanner(
      tester,
      repository: AdvertisementRepository(dio: _adsDioError(500)),
    );
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('hides when network image fails', (tester) async {
    HttpOverrides.global = _PngHttpOverrides();
    await pumpBanner(
      tester,
      repository: AdvertisementRepository(
        dio: _adsDio(_oneAdBody(mediaUrl: 'https://example.test/broken.png')),
      ),
    );
    expect(find.byType(PageView), findsOneWidget);

    final state = tester.state<AdvertisementBannerState>(
      find.byType(AdvertisementBanner),
    );
    state.debugMarkImageFailed(1);
    await tester.pump();
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('shows indicators for multiple advertisements', (tester) async {
    HttpOverrides.global = _PngHttpOverrides();
    await pumpBanner(
      tester,
      repository: AdvertisementRepository(
        dio: _adsDio({
          'success': true,
          'data': {
            'advertisements': [
              {
                'id': 1,
                'title': 'A',
                'placement': 'home_banner',
                'media_type': 'image',
                'media_url': 'https://example.test/a.png',
              },
              {
                'id': 2,
                'title': 'B',
                'placement': 'home_banner',
                'media_type': 'image',
                'media_url': 'https://example.test/b.png',
              },
            ],
          },
        }),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNWidgets(2));
  });
}

Map<String, dynamic> _oneAdBody({required String mediaUrl}) => {
  'success': true,
  'data': {
    'placement': 'home_banner',
    'advertisements': [
      {
        'id': 1,
        'title': 'advertise01',
        'placement': 'home_banner',
        'media_type': 'image',
        'media_url': mediaUrl,
      },
    ],
  },
};

Dio _adsDio(Map<String, dynamic> body) {
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

Dio _adsDioError(int status) {
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
              data: {'success': false},
            ),
            type: DioExceptionType.badResponse,
          ),
        );
      },
    ),
  );
  return dio;
}

class _PngHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _ScriptedHttpClient(succeed: true);
}

class _ScriptedHttpClient extends Fake implements HttpClient {
  _ScriptedHttpClient({required this.succeed});

  final bool succeed;
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _ScriptedRequest(succeed: succeed);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _ScriptedRequest(succeed: succeed);

  @override
  void close({bool force = false}) {}
}

class _ScriptedRequest extends Fake implements HttpClientRequest {
  _ScriptedRequest({required this.succeed});

  final bool succeed;
  final _headers = _ScriptedHeaders();

  @override
  HttpHeaders get headers => _headers;

  @override
  Future<HttpClientResponse> close() async =>
      _ScriptedResponse(succeed: succeed);
}

class _ScriptedResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _ScriptedResponse({required this.succeed});

  final bool succeed;

  @override
  int get statusCode => succeed ? 200 : 404;

  @override
  int get contentLength => succeed ? _kTinyPng.length : 0;

  @override
  HttpHeaders get headers => _ScriptedHeaders();

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  List<Cookie> get cookies => const [];

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => succeed ? 'OK' : 'Not Found';

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  Future<Socket> detachSocket() => throw UnimplementedError();

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) => throw UnimplementedError();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final data = succeed ? _kTinyPng : Uint8List(0);
    return Stream<List<int>>.value(data).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _ScriptedHeaders extends Fake implements HttpHeaders {
  final Map<String, List<String>> _values = {};

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _values.putIfAbsent(name.toLowerCase(), () => <String>[]).add('$value');
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name.toLowerCase()] = <String>['$value'];
  }

  @override
  List<String>? operator [](String name) => _values[name.toLowerCase()];

  @override
  String? value(String name) {
    final list = this[name];
    if (list == null || list.isEmpty) return null;
    return list.join(',');
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _values.forEach(action);
  }
}
