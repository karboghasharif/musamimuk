import 'dart:convert';

import '../models/design_compose_plan.dart';
import 'ai_text_service.dart';

/// Parses natural-language prompts into structured compose plans.
class AiDesignComposeService {
  AiDesignComposeService({AiTextService? aiText})
      : _aiText = aiText ?? AiTextService();

  final AiTextService _aiText;

  Future<DesignComposePlan> parseComponentPrompt(String userPrompt) async {
    final trimmed = userPrompt.trim();
    if (trimmed.isEmpty) {
      throw AiTextException('Prompt is empty.');
    }

    final prompt = '''
Parse this Musamimuk design editor request into a single JSON object.

User request: "$trimmed"

Return ONLY JSON:
{
  "action": "add_asset|add_text|set_background",
  "asset_type": "png|shape|logo|online_pic (API types only; map icon/sticker/frame to png or shape)",
  "search": "keywords for asset search",
  "position": "center|top_left|top_right|bottom_left|bottom_right|top_center|bottom_center",
  "summary": "One short sentence describing what will happen",
  "text_content": "only for add_text",
  "background": "only for set_background — color name or description"
}

Rules:
- "add burger icon" → action add_asset, asset_type png, search burger, position center
- "add flower frame" → action add_asset, asset_type shape, search flower
- Valid asset_type values: png, shape, logo, online_pic (never use icon, sticker, frame as type)
- Prefer add_asset for stickers, icons, frames, shapes, logos, PNGs
- search should be the main subject keywords without filler words (add, a, the)
- Phase 1: set_background and add_text are secondary; still parse if clearly requested
''';

    try {
      final raw = await _aiText.completeRaw(
        system:
            'You are a design compose parser for Musamimuk. Output valid JSON only.',
        user: prompt,
        prefer: AiTextProvider.groq,
        jsonMode: true,
      );
      final parsed = _parsePlan(raw);
      if (parsed != null) return parsed;
    } on AiTextException {
      // Fall through to heuristic parsing.
    } catch (_) {}

    final heuristic = _heuristicParse(trimmed);
    if (heuristic != null) return heuristic;
    throw AiTextException('Could not understand that request.');
  }

  DesignComposePlan? _parsePlan(String raw) {
    try {
      final decoded = jsonDecode(raw.trim());
      if (decoded is! Map) return null;

      final action = DesignComposeAction.fromApiValue(
            decoded['action']?.toString() ?? '',
          ) ??
          DesignComposeAction.addAsset;

      final assetType = decoded['asset_type']?.toString().trim();
      final search = decoded['search']?.toString().trim();
      final summary = decoded['summary']?.toString().trim() ?? '';
      final position = DesignComposePosition.fromApiValue(
        decoded['position']?.toString(),
      );

      return DesignComposePlan(
        action: action,
        assetType: assetType?.isNotEmpty == true ? assetType : null,
        searchQuery: search?.isNotEmpty == true ? search : null,
        position: position,
        summary: summary.isNotEmpty
            ? summary
            : _defaultSummary(action, assetType, search),
        textContent: decoded['text_content']?.toString().trim(),
        backgroundDescription: decoded['background']?.toString().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  DesignComposePlan? _heuristicParse(String prompt) {
    var text = prompt.trim().toLowerCase();
    if (text.isEmpty) return null;

    text = text.replaceFirst(
      RegExp(r'^(please\s+)?(add|put|insert|place|show)\s+(a\s+|an\s+|the\s+)?'),
      '',
    );

    String? assetType;
    var search = text;

    const typePatterns = <String, String>{
      r'\bframe\b': 'shape',
      r'\bicon\b': 'png',
      r'\bsticker\b': 'png',
      r'\blogo\b': 'logo',
      r'\bshape\b': 'shape',
      r'\bpng\b': 'png',
      r'\bonline[_\s-]?pic\b': 'online_pic',
    };

    for (final entry in typePatterns.entries) {
      if (RegExp(entry.key).hasMatch(search)) {
        assetType = entry.value;
        search = search.replaceAll(RegExp(entry.key), ' ').trim();
        break;
      }
    }

    assetType ??= 'png';
    search = search.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (search.isEmpty) search = text;

    return DesignComposePlan(
      action: DesignComposeAction.addAsset,
      assetType: assetType,
      searchQuery: search,
      position: DesignComposePosition.center,
      summary: _defaultSummary(
        DesignComposeAction.addAsset,
        assetType,
        search,
      ),
    );
  }

  String _defaultSummary(
    DesignComposeAction action,
    String? assetType,
    String? search,
  ) {
    return switch (action) {
      DesignComposeAction.addAsset =>
        'Add ${assetType ?? 'asset'}: ${search ?? ''}'.trim(),
      DesignComposeAction.addText => 'Add text: ${search ?? ''}'.trim(),
      DesignComposeAction.setBackground =>
        'Set background: ${search ?? ''}'.trim(),
      DesignComposeAction.composeDesign => 'Compose design',
    };
  }
}
