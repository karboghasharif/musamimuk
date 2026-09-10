import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/config/editor_ai_config.dart';
import '../../models/editor_ai_api_models.dart';
import 'editor_ai_api_service.dart';
import 'editor_ai_message_base.dart';

/// Grok (xAI) editor commands routed through the Musamimuk backend.
///
/// Chat / vision only — image generation stays on the OpenAI images path.
class EditorAiGrokProvider extends EditorAiMessageBase {
  EditorAiGrokProvider({
    required super.context,
    EditorAiApiService? apiService,
  }) : _apiService = apiService ?? EditorAiApiService();

  final EditorAiApiService _apiService;

  @override
  EditorAiProviderKind get provider => EditorAiProviderKind.grok;

  @override
  bool get isImageGenerationSupported => false;

  @override
  Future<bool> sendCommand(ProImageEditorState editor, String command) async {
    try {
      final response = await _apiService.sendGrokEditor(
        OpenAiEditorRequest(
          messages: [
            AiMessage(role: 'system', content: buildSystemMessage(editor)),
            AiMessage(role: 'user', content: command),
          ],
          responseFormat: const {'type': 'text'},
        ),
      );
      return handleAiResponse(editor, response.content);
    } on EditorAiApiException catch (error) {
      notifyUser(error.message, isError: true);
      return false;
    } catch (_) {
      notifyUser('AI request failed. Please try again.', isError: true);
      return false;
    }
  }

  @override
  Future<bool> sendDesignCompositionRequest(
    ProImageEditorState editor,
    String prompt,
  ) async {
    notifyUser(
      'Editable designs with generated photos currently require OpenAI.',
      isError: true,
    );
    return false;
  }

  @override
  Future<bool> sendImageGenerationRequest(
    ProImageEditorState editor,
    String prompt, {
    bool asBackground = false,
  }) async {
    notifyUser(
      'Image generation is currently available through OpenAI.',
      isError: true,
    );
    return false;
  }
}
