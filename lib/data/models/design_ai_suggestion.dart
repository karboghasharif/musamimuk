/// Canvas-level AI suggestion actions from [AiDesignAssistantService].
enum DesignAiSuggestionAction {
  addText,
  removeBackground,
  pickTheme,
  editText,
  addAsset,
  setBackground,
  composeDesign;

  static DesignAiSuggestionAction? fromApiValue(String raw) {
    switch (raw.trim().toLowerCase().replaceAll(' ', '_')) {
      case 'add_text':
        return DesignAiSuggestionAction.addText;
      case 'remove_background':
        return DesignAiSuggestionAction.removeBackground;
      case 'pick_theme':
        return DesignAiSuggestionAction.pickTheme;
      case 'edit_text':
        return DesignAiSuggestionAction.editText;
      case 'add_asset':
        return DesignAiSuggestionAction.addAsset;
      case 'set_background':
        return DesignAiSuggestionAction.setBackground;
      case 'compose_design':
        return DesignAiSuggestionAction.composeDesign;
      default:
        return null;
    }
  }

  String get labelKey => switch (this) {
        DesignAiSuggestionAction.addText => 'lbl_ai_action_add_text',
        DesignAiSuggestionAction.removeBackground =>
          'lbl_ai_action_remove_bg',
        DesignAiSuggestionAction.pickTheme => 'lbl_ai_action_pick_theme',
        DesignAiSuggestionAction.editText => 'lbl_ai_action_edit_text',
        DesignAiSuggestionAction.addAsset => 'lbl_ai_action_add_asset',
        DesignAiSuggestionAction.setBackground =>
          'lbl_ai_action_set_background',
        DesignAiSuggestionAction.composeDesign =>
          'lbl_ai_action_compose_design',
      };
}

class DesignAiSuggestion {
  const DesignAiSuggestion({
    required this.id,
    required this.title,
    required this.detail,
    required this.action,
  });

  final String id;
  final String title;
  final String detail;
  final DesignAiSuggestionAction action;
}
