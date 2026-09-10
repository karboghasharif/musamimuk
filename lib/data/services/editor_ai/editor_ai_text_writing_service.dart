import '../../../core/config/editor_ai_config.dart';
import '../../models/editor_ai_api_models.dart';
import 'editor_ai_api_service.dart';
import 'editor_ai_text_writing.dart';

/// Plain-text writing assistance via the Musamimuk AI backend proxy.
///
/// Intentionally separate from canvas JSON editor commands.
class EditorAiTextWritingService {
  EditorAiTextWritingService({
    EditorAiApiService? apiService,
    EditorAiProviderKind provider = EditorAiProviderKind.openAi,
  }) : _apiService = apiService ?? EditorAiApiService(),
       _provider = provider;

  final EditorAiApiService _apiService;
  final EditorAiProviderKind _provider;

  /// Returns sanitized plain text, or throws [EditorAiApiException].
  Future<String> write({
    required EditorAiTextWritingAction action,
    required String sourceText,
    String? generatePrompt,
  }) async {
    if (action == EditorAiTextWritingAction.generate) {
      final prompt = generatePrompt?.trim() ?? '';
      if (prompt.isEmpty) {
        throw const EditorAiApiException(
          message: 'empty_prompt',
          statusCode: 422,
        );
      }
    } else if (sourceText.trim().isEmpty) {
      throw const EditorAiApiException(message: 'empty_text', statusCode: 422);
    }

    final system = editorAiTextWritingSystemPrompt(action);
    final user = editorAiTextWritingUserPrompt(
      action: action,
      sourceText: sourceText,
      generatePrompt: generatePrompt,
    );

    final raw = switch (_provider) {
      EditorAiProviderKind.openAi => await _requestOpenAi(system, user),
      EditorAiProviderKind.gemini => await _requestGemini(system, user),
      EditorAiProviderKind.grok => await _requestGrok(system, user),
    };

    final cleaned = sanitizeAiPlainText(raw);
    if (cleaned.isEmpty) {
      throw const EditorAiApiException(
        message: 'empty_response',
        statusCode: 502,
        retryable: true,
      );
    }
    return cleaned;
  }

  Future<String> _requestOpenAi(String system, String user) async {
    final response = await _apiService.sendOpenAiEditor(
      OpenAiEditorRequest(
        messages: [
          AiMessage(role: 'system', content: system),
          AiMessage(role: 'user', content: user),
        ],
        responseFormat: const {'type': 'text'},
      ),
    );
    return response.content;
  }

  Future<String> _requestGrok(String system, String user) async {
    final response = await _apiService.sendGrokEditor(
      OpenAiEditorRequest(
        messages: [
          AiMessage(role: 'system', content: system),
          AiMessage(role: 'user', content: user),
        ],
        responseFormat: const {'type': 'text'},
      ),
    );
    return response.content;
  }

  Future<String> _requestGemini(String system, String user) async {
    final response = await _apiService.sendGemini(
      GeminiEditorRequest(
        contents: [
          {
            'role': 'user',
            'parts': [
              {'text': '$system\n\n$user'},
            ],
          },
        ],
        generationConfig: const {
          'responseMimeType': 'text/plain',
          'temperature': 0.4,
        },
      ),
    );
    return response.content;
  }
}
