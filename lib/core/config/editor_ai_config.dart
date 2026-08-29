/// Musamimuk backend AI configuration for ProImageEditor commands.
class EditorAiConfig {
  EditorAiConfig._();

  static const bool isConfigured = true;
}

/// Supported LLM backends for editor text / image commands.
enum EditorAiProviderKind { openAi, gemini }

/// What the command bar sends on Submit.
enum EditorAiGenerationMode {
  /// Natural-language edit JSON applied via [ProImageEditorState.addHistory].
  text,

  /// Structured AI plan → separate native text/image/icon/shape layers.
  designComposition,

  /// OpenAI GPT Image → [WidgetLayer] sticker.
  sticker,

  /// OpenAI GPT Image → [ProImageEditorState.updateBackgroundImage].
  background,
}
