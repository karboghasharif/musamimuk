import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/data/models/editor_ai_api_models.dart';
import 'package:musamimuk/data/services/editor_ai/editor_ai_api_service.dart';

void main() {
  group('editor AI backend contracts', () {
    test(
      'OpenAI command sends allowlisted fields and parses content',
      () async {
        RequestOptions? captured;
        final service = EditorAiApiService(
          dio: _dioReturning({
            'choices': [
              {
                'message': {'content': '{"layers":[]}'},
              },
            ],
          }, onRequest: (request) => captured = request),
        );

        final response = await service.sendOpenAiEditor(
          const OpenAiEditorRequest(
            messages: [AiMessage(role: 'user', content: 'Add text')],
            responseFormat: {'type': 'text'},
          ),
        );

        expect(response.content, '{"layers":[]}');
        expect(captured?.path, 'ai/editor/openai');
        expect(
          (captured?.data as Map<String, dynamic>).keys,
          containsAll(<String>['messages', 'response_format']),
        );
        expect(
          (captured?.data as Map<String, dynamic>).keys,
          isNot(contains(anyOf('model', 'tools', 'api_key'))),
        );
      },
    );

    test('generated image preserves asset id URL and base64 body', () {
      final response = OpenAiImageResponse.fromJson({
        'data': [
          {
            'asset_id': 'asset-123',
            'url': 'https://example.test/generated/asset-123',
            'b64_json': 'AQID',
          },
        ],
      });

      final asset = response.assets.single;
      expect(asset.id, 'asset-123');
      expect(asset.url, 'https://example.test/generated/asset-123');
      expect(asset.base64Json, 'AQID');
      expect(asset.decodeBytes(), [1, 2, 3]);
    });

    test('image request contains only backend allowlisted fields', () async {
      RequestOptions? captured;
      final service = EditorAiApiService(
        dio: _dioReturning({
          'data': [
            {'asset_id': 'asset-1', 'b64_json': 'AQID'},
          ],
        }, onRequest: (request) => captured = request),
      );

      await service.generateOpenAiImage(
        OpenAiImageRequest(
          prompt: 'burger',
          size: '1024x1024',
          quality: 'medium',
          background: 'transparent',
        ),
      );

      expect(captured?.path, 'ai/editor/openai/images');
      expect((captured?.data as Map<String, dynamic>).keys.toSet(), {
        'prompt',
        'n',
        'size',
        'quality',
        'background',
      });
    });

    test('Gemini request and candidates parse correctly', () async {
      RequestOptions? captured;
      final service = EditorAiApiService(
        dio: _dioReturning({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': '{"blur":1}'},
                ],
              },
            },
          ],
        }, onRequest: (request) => captured = request),
      );

      final response = await service.sendGemini(
        const GeminiEditorRequest(
          contents: [
            {
              'role': 'user',
              'parts': [
                {'text': 'Blur the image'},
              ],
            },
          ],
          generationConfig: {
            'responseMimeType': 'application/json',
            'responseSchema': {
              'type': 'OBJECT',
              'properties': <String, dynamic>{},
              'required': <String>[],
            },
          },
        ),
      );

      expect(response.content, '{"blur":1}');
      expect(captured?.path, 'ai/editor/gemini');
      expect((captured?.data as Map<String, dynamic>).keys.toSet(), {
        'contents',
        'generationConfig',
      });
    });

    for (final status in [401, 422, 429, 502, 503, 504]) {
      test('$status maps to a safe user-facing AI error', () async {
        final service = EditorAiApiService(dio: _dioRejecting(status));

        await expectLater(
          service.sendOpenAiEditor(
            const OpenAiEditorRequest(
              messages: [AiMessage(role: 'user', content: 'test')],
            ),
          ),
          throwsA(
            isA<EditorAiApiException>()
                .having((error) => error.statusCode, 'statusCode', status)
                .having(
                  (error) => error.message,
                  'message',
                  isNot(contains('DioException')),
                ),
          ),
        );
      });
    }
  });
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
              data: {
                'message': status == 422 ? 'Prompt is required' : 'Unavailable',
              },
              headers: status == 429
                  ? Headers.fromMap({
                      'retry-after': ['10'],
                    })
                  : null,
            ),
          ),
        );
      },
    ),
  );
  return dio;
}
