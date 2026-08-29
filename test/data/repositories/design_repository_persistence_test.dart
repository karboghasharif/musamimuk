import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/data/models/design_persistence_models.dart';
import 'package:musamimuk/data/repositories/design_repository.dart';
import 'package:musamimuk/data/services/design_redesign_service.dart';

void main() {
  group('design persistence contracts', () {
    test('save sends file, exact design_data, and asset_ids[]', () async {
      RequestOptions? captured;
      final repository = DesignRepository(
        dio: _dioReturning({
          'status': true,
          'dbData': {
            'id': 123,
            'name': 'My Design',
            'file_url': 'https://example.test/design.png',
            'has_design_data': true,
          },
        }, onRequest: (request) => captured = request),
      );
      const history = '{"unknown":{"kept":true},"history":[]}';

      final result = await repository.saveDesign(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        categoryId: 7,
        title: 'My Design',
        tags: 'design',
        filename: 'design.png',
        designData: history,
        assetIds: const ['asset-a', 'asset-b'],
      );

      expect(result, isA<SaveDesignSuccess>());
      final form = captured?.data as FormData;
      expect(form.files.map((entry) => entry.key), contains('file'));
      expect(_field(form, 'design_data'), history);
      expect(
        form.fields
            .where((entry) => entry.key == 'asset_ids[]')
            .map((entry) => entry.value),
        ['asset-a', 'asset-b'],
      );
    });

    test('update omits unchanged fields', () async {
      RequestOptions? captured;
      final repository = DesignRepository(
        dio: _dioReturning({
          'status': true,
          'dbData': {'id': 9, 'name': 'Design', 'file_url': '/design.png'},
        }, onRequest: (request) => captured = request),
      );

      await repository.update(id: 9, designData: '{"history":[]}');

      final form = captured?.data as FormData;
      expect(form.fields.map((entry) => entry.key).toList(), ['design_data']);
      expect(form.files, isEmpty);
    });

    test('redesign preserves unknown history and generated assets', () async {
      final repository = DesignRepository(
        dio: _dioReturning({
          'status': true,
          'dbData': {
            'id': 123,
            'name': 'Design',
            'file_url': 'https://example.test/design.png',
            'visibility': 'public',
            'has_design_data': true,
            'design_data': {
              'version': 'future',
              'unknown_editor_field': {'kept': true},
            },
            'generated_assets': [
              {
                'id': 'asset-1',
                'url': 'https://example.test/assets/asset-1',
                'mime_type': 'image/png',
              },
            ],
          },
        }),
      );

      final result = await repository.loadForRedesign(123);

      final design = (result as DesignRedesignSuccess).design;
      expect(design.designDataJson, contains('"unknown_editor_field"'));
      expect(design.generatedAssets.single.id, 'asset-1');
    });

    test('missing history is represented safely as null', () {
      final design = RedesignDesign.fromJson({
        'id': 1,
        'name': 'Flat',
        'file_url': 'https://example.test/flat.png',
        'visibility': 'public',
        'has_design_data': false,
        'design_data': null,
      });

      expect(design.designDataJson, isNull);
      expect(design.hasDesignData, isFalse);
    });

    test('private redesign 404 is returned safely', () async {
      final repository = DesignRepository(dio: _dioRejecting(404));

      final result = await repository.loadForRedesign(55);

      expect(result, isA<DesignRedesignFailure>());
      expect((result as DesignRedesignFailure).statusCode, 404);
    });

    test('clone loads the new design ID, never the source ID', () async {
      final repository = _FakeCloneRepository();
      final service = DesignRedesignService(repository: repository);

      final result = await service.prepare(
        sourceDesignId: 123,
        cloneBeforeOpening: true,
      );

      expect(result, isA<PrepareRedesignSuccess>());
      expect(repository.clonedSourceId, 123);
      expect(repository.loadedDesignId, 456);
    });
  });
}

String? _field(FormData form, String key) {
  for (final entry in form.fields) {
    if (entry.key == key) return entry.value;
  }
  return null;
}

Dio _dioReturning(
  Map<String, dynamic> body, {
  void Function(RequestOptions request)? onRequest,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) {
        onRequest?.call(request);
        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: request,
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
      onRequest: (request, handler) {
        handler.reject(
          DioException(
            requestOptions: request,
            type: DioExceptionType.badResponse,
            response: Response<Map<String, dynamic>>(
              requestOptions: request,
              statusCode: status,
              data: const {'message': 'Design not found'},
            ),
          ),
        );
      },
    ),
  );
  return dio;
}

class _FakeCloneRepository extends DesignRepository {
  _FakeCloneRepository() : super(dio: Dio());

  int? clonedSourceId;
  int? loadedDesignId;

  @override
  Future<DesignCloneResult> clone(int id) async {
    clonedSourceId = id;
    return DesignCloneSuccess(
      const SavedDesign(
        id: 456,
        sourceDesignId: 123,
        name: 'Copy',
        fileUrl: '',
        visibility: 'private',
        hasDesignData: true,
      ),
    );
  }

  @override
  Future<DesignRedesignResult> loadForRedesign(int id) async {
    loadedDesignId = id;
    return DesignRedesignSuccess(
      RedesignDesign(
        id: id,
        name: 'Copy',
        fileUrl: 'https://example.test/copy.png',
        visibility: 'private',
        hasDesignData: true,
        designDataJson: '{"history":[]}',
        generatedAssets: const [],
      ),
    );
  }
}
