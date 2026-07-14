/// Parsed intent from a natural-language compose prompt.
enum DesignComposeAction {
  addAsset,
  addText,
  setBackground,
  composeDesign;

  static DesignComposeAction? fromApiValue(String raw) {
    switch (raw.trim().toLowerCase().replaceAll(' ', '_')) {
      case 'add_asset':
        return DesignComposeAction.addAsset;
      case 'add_text':
        return DesignComposeAction.addText;
      case 'set_background':
        return DesignComposeAction.setBackground;
      case 'compose_design':
        return DesignComposeAction.composeDesign;
      default:
        return null;
    }
  }
}

/// Canvas placement for composed assets.
enum DesignComposePosition {
  center,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  topCenter,
  bottomCenter;

  static DesignComposePosition fromApiValue(String? raw) {
    if (raw == null || raw.trim().isEmpty) return DesignComposePosition.center;
    switch (raw.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_')) {
      case 'top_left':
        return DesignComposePosition.topLeft;
      case 'top_right':
        return DesignComposePosition.topRight;
      case 'bottom_left':
        return DesignComposePosition.bottomLeft;
      case 'bottom_right':
        return DesignComposePosition.bottomRight;
      case 'top_center':
        return DesignComposePosition.topCenter;
      case 'bottom_center':
        return DesignComposePosition.bottomCenter;
      default:
        return DesignComposePosition.center;
    }
  }
}

class DesignComposePlan {
  const DesignComposePlan({
    required this.action,
    this.assetType,
    this.searchQuery,
    this.position = DesignComposePosition.center,
    this.summary = '',
    this.textContent,
    this.backgroundDescription,
  });

  final DesignComposeAction action;
  final String? assetType;
  final String? searchQuery;
  final DesignComposePosition position;
  final String summary;
  final String? textContent;
  final String? backgroundDescription;

  bool get isExecutable => switch (action) {
        DesignComposeAction.addAsset =>
          (searchQuery?.trim().isNotEmpty ?? false) ||
              (assetType?.trim().isNotEmpty ?? false),
        DesignComposeAction.addText =>
          textContent?.trim().isNotEmpty ?? false,
        DesignComposeAction.setBackground =>
          backgroundDescription?.trim().isNotEmpty ?? false,
        DesignComposeAction.composeDesign => false,
      };
}
