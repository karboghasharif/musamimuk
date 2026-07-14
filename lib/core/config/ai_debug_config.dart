import 'ai_debug_secrets.dart';

/// Debug-only AI credentials. Keys live in gitignored [AiDebugSecrets].
class AiDebugConfig {
  static String get groqApiKey => AiDebugSecrets.groqApiKey.trim();
  static String get geminiApiKey => AiDebugSecrets.geminiApiKey.trim();

  static bool get hasGroq => groqApiKey.isNotEmpty;
  static bool get hasGemini => geminiApiKey.isNotEmpty;
  static bool get isConfigured => hasGroq || hasGemini;
}
