import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/app_export.dart';

const Color _kMusamiLayerQuickBarIconColor = Color(0xFF1A1A1A);

/// Vertical placement for the floating quick bar relative to the selection.
enum MusamiLayerQuickBarPlacement { above, below }

/// Gap between the selection border and the quick bar.
const double kMusamiLayerQuickBarGap = 8;

/// Fixed visual height of the pill bar.
const double kMusamiLayerQuickBarHeight = 40;

/// Chooses where to show the quick bar so it stays on canvas.
///
/// Layers in the top half of the page get the bar below; layers in the bottom
/// half get it above — matching Canva-style behaviour.
MusamiLayerQuickBarPlacement musamiLayerQuickBarPlacement({
  required Layer layer,
  required Size canvasBodySize,
}) {
  if (canvasBodySize.height <= 0) return MusamiLayerQuickBarPlacement.above;

  final anchorY = layer.offset.dy + canvasBodySize.height / 2;
  if (anchorY <= canvasBodySize.height / 2) {
    return MusamiLayerQuickBarPlacement.below;
  }
  return MusamiLayerQuickBarPlacement.above;
}

/// Axis-aligned bounds of the selection in overlay coordinates.
Rect musamiLayerSelectionBounds(OverlayChildLayoutInfo info) {
  final w = info.childSize.width;
  final h = info.childSize.height;
  final matrix = info.childPaintTransform;

  final corners = <Offset>[
    MatrixUtils.transformPoint(matrix, Offset.zero),
    MatrixUtils.transformPoint(matrix, Offset(w, 0)),
    MatrixUtils.transformPoint(matrix, Offset(0, h)),
    MatrixUtils.transformPoint(matrix, Offset(w, h)),
  ];

  final xs = corners.map((c) => c.dx);
  final ys = corners.map((c) => c.dy);
  return Rect.fromLTRB(
    xs.reduce(math.min),
    ys.reduce(math.min),
    xs.reduce(math.max),
    ys.reduce(math.max),
  );
}

/// Top-left anchor for [MusamiLayerFloatingQuickBar] in overlay coordinates.
Offset musamiLayerQuickBarAnchor({
  required OverlayChildLayoutInfo info,
  required MusamiLayerQuickBarPlacement placement,
  double toolbarHeight = kMusamiLayerQuickBarHeight,
}) {
  return musamiLayerQuickBarAnchorForBounds(
    bounds: musamiLayerSelectionBounds(info),
    placement: placement,
    toolbarHeight: toolbarHeight,
  );
}

/// Same as [musamiLayerQuickBarAnchor] but accepts a precomputed [bounds] rect.
Offset musamiLayerQuickBarAnchorForBounds({
  required Rect bounds,
  required MusamiLayerQuickBarPlacement placement,
  double toolbarHeight = kMusamiLayerQuickBarHeight,
}) {
  final centerX = bounds.center.dx;
  final dy = placement == MusamiLayerQuickBarPlacement.below
      ? bounds.bottom + kMusamiLayerQuickBarGap
      : bounds.top - kMusamiLayerQuickBarGap - toolbarHeight;
  return Offset(centerX, dy);
}

/// Callbacks wired from the editor screen into the floating quick bar.
class MusamiLayerQuickBarActions {
  const MusamiLayerQuickBarActions({
    required this.isLocked,
    required this.onLockToggle,
    required this.onDuplicate,
    required this.onDelete,
    required this.onMore,
    this.onComment,
  });

  final bool isLocked;
  final VoidCallback onLockToggle;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  /// Receives the More button [BuildContext] for menu anchoring.
  final void Function(BuildContext anchorContext) onMore;
  final VoidCallback? onComment;
}

/// White pill toolbar (lock / duplicate / delete / more) shown on selection.
class MusamiLayerFloatingQuickBar extends StatelessWidget {
  const MusamiLayerFloatingQuickBar({super.key, required this.actions});

  final MusamiLayerQuickBarActions actions;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDs.radiusFull),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.10)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDs.space1),
        child: SizedBox(
          height: kMusamiLayerQuickBarHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (actions.onComment != null)
                _QuickBarIconButton(
                  icon: Icons.add_comment_outlined,
                  tooltip: 'lbl_layer_menu_comment'.tr,
                  onTap: actions.onComment!,
                ),
              _QuickBarIconButton(
                icon: actions.isLocked
                    ? Icons.lock_rounded
                    : Icons.lock_open_rounded,
                tooltip: actions.isLocked
                    ? 'lbl_layer_menu_unlock'.tr
                    : 'lbl_layer_menu_lock'.tr,
                onTap: actions.onLockToggle,
              ),
              _QuickBarIconButton(
                icon: Icons.control_point_duplicate_rounded,
                tooltip: 'lbl_layer_menu_duplicate'.tr,
                onTap: actions.onDuplicate,
              ),
              _QuickBarIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'lbl_layer_menu_delete'.tr,
                onTap: actions.onDelete,
              ),
              Builder(
                builder: (anchorContext) => _QuickBarIconButton(
                  icon: Icons.more_horiz_rounded,
                  tooltip: 'lbl_more'.tr,
                  onTap: () => actions.onMore(anchorContext),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickBarIconButton extends StatelessWidget {
  const _QuickBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusFull),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: AppDs.iconSm,
            color: _kMusamiLayerQuickBarIconColor,
          ),
        ),
      ),
    );
  }
}

/// Selection overlay + floating quick bar in the same overlay coordinate space.
class MusamiLayerSelectionChrome extends StatelessWidget {
  const MusamiLayerSelectionChrome({
    super.key,
    required this.info,
    required this.layer,
    required this.canvasBodySize,
    required this.actions,
    required this.selectionOverlay,
  });

  final OverlayChildLayoutInfo info;
  final Layer layer;
  final Size canvasBodySize;
  final MusamiLayerQuickBarActions actions;
  final Widget selectionOverlay;

  @override
  Widget build(BuildContext context) {
    final placement = musamiLayerQuickBarPlacement(
      layer: layer,
      canvasBodySize: canvasBodySize,
    );
    final anchor = musamiLayerQuickBarAnchor(
      info: info,
      placement: placement,
    );

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        selectionOverlay,
        Positioned(
          left: anchor.dx,
          top: anchor.dy,
          child: FractionalTranslation(
            translation: const Offset(-0.5, 0),
            child: MusamiLayerFloatingQuickBar(actions: actions),
          ),
        ),
      ],
    );
  }
}

/// Exported for unit tests — upright counter-rotation helper (legacy).
double musamiLayerQuickBarUprightCounterRotation(Layer layer) {
  final rotation = layer.flipX == layer.flipY
      ? layer.rotation
      : -layer.rotation;
  return -rotation;
}
