import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/core/models/editor_configs/text_editor_configs.dart';
import '/core/models/layers/text_layer.dart';
import '../../../../features/text_editor/widgets/rounded_background_text/rounded_background_text.dart';

/// Outline metadata from the host app (`musami_text_layer_style_sheet.dart`).
/// Kept as literals so this package stays independent of the app library.
const String _kMusamiOutlineW = 'musami_text_outline_w';
const String _kMusamiOutlineC = 'musami_text_outline_c';

List<Shadow> _outlineRingFromMeta(Map<String, dynamic>? meta, Color fallback) {
  if (meta == null) return [];
  final w = (meta[_kMusamiOutlineW] as num?)?.toDouble() ?? 0;
  if (w <= 0) return [];
  final ci = meta[_kMusamiOutlineC];
  final c = ci is int
      ? Color(ci)
      : ci is num
          ? Color(ci.toInt())
          : fallback;
  final q = w * 0.70710678;
  final offsets = <Offset>[
    Offset(-w, 0),
    Offset(w, 0),
    Offset(0, -w),
    Offset(0, w),
    Offset(-q, -q),
    Offset(q, -q),
    Offset(-q, q),
    Offset(q, q),
  ];
  return offsets
      .map((o) => Shadow(color: c, offset: o, blurRadius: 0))
      .toList();
}

/// A widget representing a text layer in the sticker editor.
class LayerWidgetTextItem extends StatelessWidget {
  /// Creates a [LayerWidgetTextItem] with the given text layer and editor
  /// configurations.
  const LayerWidgetTextItem({
    super.key,
    required this.layer,
    required this.textEditorConfigs,
    required this.showMoveCursor,
    required this.onHitChanged,
  });

  /// The text layer represented by this widget.
  final TextLayer layer;

  /// Configuration settings for the text editor.
  final TextEditorConfigs textEditorConfigs;

  /// Notifies whether the move cursor should be shown.
  final ValueNotifier<bool> showMoveCursor;

  /// Callback function that is triggered when a hit status changes.
  ///
  /// The [onHitChanged] function takes a boolean parameter [hasHit] which
  /// indicates whether a hit has occurred (true) or not (false).
  final Function(bool hasHit) onHitChanged;

  void _handleLayerHit(bool hasHit) {
    // Update hit detection and cursor visibility state.
    if (layer.hit != hasHit || showMoveCursor.value != hasHit) {
      layer.hit = hasHit;
      showMoveCursor.value = hasHit;
    }
    layer.hit = hasHit;
    onHitChanged(hasHit);
  }

  @override
  Widget build(BuildContext context) {
    final computedFontSize =
        textEditorConfigs.initFontSize * layer.scale * layer.fontScale;
    final baseStyle = TextStyle(
      fontSize: computedFontSize,
      color: layer.color,
      overflow: TextOverflow.ellipsis,
    );

    final maxTextWidth = layer.maxTextWidth;

    // Merge layer style; keep decorations, highlight, etc. Outline is driven by
    // meta so it stacks with user shadows from [TextStyle.shadows].
    // When [TextLayer.textStyle.fontSize] is set (e.g. size slider), use it;
    // otherwise fall back to [initFontSize] × layer scale × [fontScale].
    TextStyle finalStyle;
    if (layer.textStyle != null) {
      finalStyle = layer.textStyle!.copyWith(
        fontSize: layer.textStyle!.fontSize ?? computedFontSize,
        fontWeight: layer.textStyle!.fontWeight ?? baseStyle.fontWeight,
        color: baseStyle.color,
        fontFamily: layer.textStyle!.fontFamily ?? baseStyle.fontFamily,
      );
    } else {
      finalStyle = baseStyle;
    }
    final outline = _outlineRingFromMeta(
      layer.meta,
      baseStyle.color ?? layer.color,
    );
    final userShadows = finalStyle.shadows ?? const <Shadow>[];
    finalStyle = finalStyle.copyWith(
      shadows: outline.isEmpty && userShadows.isEmpty
          ? null
          : <Shadow>[...outline, ...userShadows],
    );

    return RoundedBackgroundText(
      enableHitBoxCorrection: true,
      maxTextWidth: maxTextWidth == null
          ? double.infinity
          : maxTextWidth * layer.scale,
      onHitTestResult: _handleLayerHit,
      layer.text.toString(),
      backgroundColor: layer.background,
      textAlign: layer.align,
      style: finalStyle,
      leadingDistribution: textEditorConfigs.style.leadingDistribution,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    layer.debugFillProperties(properties);
  }
}
