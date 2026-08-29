import 'package:flutter/widgets.dart';

import '../../../core/config/editor_ai_config.dart';
import 'editor_ai_gemini_provider.dart';
import 'editor_ai_message_base.dart';
import 'editor_ai_openai_provider.dart';

/// Creates the concrete AI provider for the editor command bar.
class EditorAiProviderFactory {
  EditorAiProviderFactory._();

  static EditorAiMessageBase? create({
    required BuildContext context,
    required EditorAiProviderKind provider,
  }) {
    switch (provider) {
      case EditorAiProviderKind.openAi:
        return EditorAiOpenAiProvider(context: context);
      case EditorAiProviderKind.gemini:
        return EditorAiGeminiProvider(context: context);
    }
  }

  static EditorAiProviderKind defaultProvider() => EditorAiProviderKind.openAi;
}
