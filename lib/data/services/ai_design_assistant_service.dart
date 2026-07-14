import 'dart:convert';

import '../models/design_ai_suggestion.dart';
import 'ai_text_service.dart';

/// Canvas-level design assistant — suggests next actions from editor state.
class AiDesignAssistantService {
  AiDesignAssistantService({AiTextService? aiText})
      : _aiText = aiText ?? AiTextService();

  final AiTextService _aiText;

  Future<List<DesignAiSuggestion>> suggestDesignActions({
    required String presetName,
    required int width,
    required int height,
    required String bgDescription,
    required String textLayersSummary,
    required int imageLayerCount,
    required String? selectedLayerType,
    required String languageLabel,
  }) async {
    final selected = selectedLayerType?.trim().isNotEmpty == true
        ? selectedLayerType!.trim()
        : 'none';

    final prompt = '''
Analyze this Musamimuk design canvas and suggest 3 to 5 helpful next actions.

Preset: $presetName
Canvas: ${width}x$height px
Background: $bgDescription
Text layers: ${textLayersSummary.isEmpty ? 'none' : textLayersSummary}
Image/sticker layers: $imageLayerCount
Selected layer type: $selected
UI language: $languageLabel

Return ONLY a JSON array. Each item:
{"id":"unique_id","title":"Short title","detail":"One sentence why","action":"add_text|remove_background|pick_theme|edit_text|add_asset|set_background|compose_design"}

Rules:
- Prioritize empty designs with add_text, pick_theme, and compose_design.
- Suggest add_asset when user might want stickers, icons, or frames.
- Suggest remove_background only when imageLayerCount > 0.
- Suggest edit_text only when text layers exist.
- Titles in $languageLabel when possible.
- Culturally relevant for South Asian / Muslim design audiences.
''';

    try {
      final raw = await _aiText.completeRaw(
        system:
            'You are a design assistant for Musamimuk, a graphic design app. Output valid JSON only.',
        user: prompt,
        prefer: AiTextProvider.groq,
        jsonMode: true,
      );
      final parsed = _parseSuggestions(raw);
      if (parsed.isNotEmpty) return parsed;
    } on AiTextException {
      // Fall through to heuristic suggestions.
    } catch (_) {}

    return _heuristicSuggestions(
      textLayersSummary: textLayersSummary,
      imageLayerCount: imageLayerCount,
    );
  }

  List<DesignAiSuggestion> _parseSuggestions(String raw) {
    final trimmed = raw.trim();
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! List) return [];
      final out = <DesignAiSuggestion>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final action = DesignAiSuggestionAction.fromApiValue(
          item['action']?.toString() ?? '',
        );
        if (action == null) continue;
        final title = item['title']?.toString().trim() ?? '';
        if (title.isEmpty) continue;
        out.add(
          DesignAiSuggestion(
            id: item['id']?.toString() ?? action.name,
            title: title,
            detail: item['detail']?.toString().trim() ?? '',
            action: action,
          ),
        );
      }
      return out.take(5).toList();
    } catch (_) {
      return [];
    }
  }

  List<DesignAiSuggestion> _heuristicSuggestions({
    required String textLayersSummary,
    required int imageLayerCount,
  }) {
    final out = <DesignAiSuggestion>[];
    if (textLayersSummary.isEmpty) {
      out.add(
        const DesignAiSuggestion(
          id: 'heuristic_add_text',
          title: 'Add a headline',
          detail: 'Generate caption text for your design.',
          action: DesignAiSuggestionAction.addText,
        ),
      );
      out.add(
        const DesignAiSuggestion(
          id: 'heuristic_pick_theme',
          title: 'Pick a theme',
          detail: 'Choose Sale, Eid, Wedding, or Birthday captions.',
          action: DesignAiSuggestionAction.pickTheme,
        ),
      );
    } else {
      out.add(
        const DesignAiSuggestion(
          id: 'heuristic_edit_text',
          title: 'Edit text layer',
          detail: 'Open the text editor for your caption.',
          action: DesignAiSuggestionAction.editText,
        ),
      );
    }
    if (imageLayerCount > 0) {
      out.add(
        const DesignAiSuggestion(
          id: 'heuristic_remove_bg',
          title: 'Remove background',
          detail: 'Cut out the subject from your image layer.',
          action: DesignAiSuggestionAction.removeBackground,
        ),
      );
    }
    return out;
  }
}
