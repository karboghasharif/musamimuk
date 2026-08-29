import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/data/models/editor_ai_api_models.dart';
import 'package:musamimuk/data/services/editor_ai/editor_ai_api_service.dart';
import 'package:musamimuk/data/services/editor_ai/editor_ai_text_writing.dart';
import 'package:musamimuk/data/services/editor_ai/editor_ai_text_writing_service.dart';
import 'package:dio/dio.dart';

void main() {
  group('AI text writing helpers', () {
    test('resolve uses selection when valid and non-empty', () {
      const value = TextEditingValue(
        text: 'Hello world',
        selection: TextSelection(baseOffset: 0, extentOffset: 5),
      );
      final source = resolveAiTextWriteSource(value);
      expect(source.text, 'Hello');
      expect(source.isPartialSelection, isTrue);
    });

    test('resolve falls back to full text', () {
      const value = TextEditingValue(
        text: 'Hello world',
        selection: TextSelection.collapsed(offset: 3),
      );
      final source = resolveAiTextWriteSource(value);
      expect(source.text, 'Hello world');
      expect(source.isPartialSelection, isFalse);
    });

    test('apply preserves selection over replaced span', () {
      const current = TextEditingValue(
        text: 'Hello world',
        selection: TextSelection(baseOffset: 0, extentOffset: 5),
      );
      final next = applyAiTextWriteResult(
        current: current,
        result: 'Hi',
        start: 0,
        end: 5,
        isPartialSelection: true,
      );
      expect(next.text, 'Hi world');
      expect(next.selection.start, 0);
      expect(next.selection.end, 2);
    });

    test('sanitize strips fences and wrapping quotes', () {
      expect(sanitizeAiPlainText('```\nHello\n```'), 'Hello');
      expect(sanitizeAiPlainText('"Hello"'), 'Hello');
    });

    test('arabic script detection', () {
      expect(looksPrimarilyArabicScript('مرحبا بكم'), isTrue);
      expect(looksPrimarilyArabicScript('Hello there'), isFalse);
    });

    test('system prompt forbids JSON canvas instructions', () {
      final prompt = editorAiTextWritingSystemPrompt(
        EditorAiTextWritingAction.rewrite,
      );
      expect(prompt.toLowerCase(), contains('plain text only'));
      expect(prompt.toLowerCase(), isNot(contains('addhistory')));
      expect(prompt.toLowerCase(), isNot(contains('"layers"')));
    });
  });

  group('EditorAiTextWritingService', () {
    test('OpenAI write returns sanitized plain text', () async {
      RequestOptions? captured;
      final service = EditorAiTextWritingService(
        apiService: EditorAiApiService(
          dio: _dioReturning({
            'choices': [
              {
                'message': {'content': '```\nRevised copy\n```'},
              },
            ],
          }, onRequest: (request) => captured = request),
        ),
      );

      final result = await service.write(
        action: EditorAiTextWritingAction.rewrite,
        sourceText: 'old copy',
      );

      expect(result, 'Revised copy');
      expect(captured?.path, 'ai/editor/openai');
      final data = captured?.data as Map<String, dynamic>;
      expect(data.keys, isNot(contains(anyOf('model', 'api_key', 'tools'))));
      final messages = data['messages'] as List;
      final system = (messages.first as Map)['content'] as String;
      expect(system.toLowerCase(), contains('plain text only'));
    });

    test('rejects empty source for non-generate actions', () async {
      final service = EditorAiTextWritingService(
        apiService: EditorAiApiService(dio: _dioReturning({})),
      );
      expect(
        () => service.write(
          action: EditorAiTextWritingAction.shorten,
          sourceText: '   ',
        ),
        throwsA(
          isA<EditorAiApiException>().having(
            (e) => e.message,
            'message',
            'empty_text',
          ),
        ),
      );
    });

    test('rejects empty generate prompt', () async {
      final service = EditorAiTextWritingService(
        apiService: EditorAiApiService(dio: _dioReturning({})),
      );
      expect(
        () => service.write(
          action: EditorAiTextWritingAction.generate,
          sourceText: '',
          generatePrompt: '  ',
        ),
        throwsA(
          isA<EditorAiApiException>().having(
            (e) => e.message,
            'message',
            'empty_prompt',
          ),
        ),
      );
    });
  });
}

Dio _dioReturning(
  Map<String, dynamic> body, {
  void Function(RequestOptions request)? onRequest,
}) {
  return Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          onRequest?.call(options);
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: body,
              statusCode: 200,
            ),
          );
        },
      ),
    );
}
