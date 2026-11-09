import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/app_export.dart';
import '../utils/musami_image_fit.dart';

const Color _kMusamiLayerQuickBarIconColor = Color(0xFF1A1A1A);

/// Vertical placement for the floating quick bar relative to the selection.
enum MusamiLayerQuickBarPlacement { above, below }

/// Gap between the selection border and the quick bar.
const double kMusamiLayerQuickBarGap = 10;

/// Fixed visual height of the pill bar.
const double kMusamiLayerQuickBarHeight = 44;

/// Horizontal margin when clamping the bar near canvas edges.
const double kMusamiLayerQuickBarEdgeMargin = 8;

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

/// Keeps a centered bar's centre-X inside [viewportWidth] with edge margin.
double musamiLayerQuickBarClampedCenterX({
  required double centerX,
  required double barWidth,
  required double viewportWidth,
  double margin = kMusamiLayerQuickBarEdgeMargin,
}) {
  if (viewportWidth <= 0 || barWidth <= 0) return centerX;
  final half = barWidth / 2;
  final minX = margin + half;
  final maxX = viewportWidth - margin - half;
  if (maxX < minX) return viewportWidth / 2;
  return centerX.clamp(minX, maxX);
}

/// Estimated width of the floating pill for the given [actions].
double musamiLayerQuickBarEstimatedWidth(MusamiLayerQuickBarActions actions) {
  var buttons = 4; // lock, duplicate, delete, more
  if (actions.onReplace != null) buttons++;
  if (actions.onComment != null) buttons++;
  return buttons * 40.0 + 8;
}

/// Callbacks wired from the editor screen into the floating quick bar.
class MusamiLayerQuickBarActions {
  const MusamiLayerQuickBarActions({
    required this.isLocked,
    required this.onLockToggle,
    required this.onDuplicate,
    required this.onDelete,
    required this.onMore,
    this.onReplace,
    this.onComment,
  });

  final bool isLocked;
  final VoidCallback onLockToggle;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  /// Receives the More button [BuildContext] for menu anchoring.
  final void Function(BuildContext anchorContext) onMore;

  /// Image layers: swap content while keeping frame geometry.
  final VoidCallback? onReplace;
  final VoidCallback? onComment;
}

/// White pill toolbar (replace / lock / duplicate / delete / more) on selection.
class MusamiLayerFloatingQuickBar extends StatelessWidget {
  const MusamiLayerFloatingQuickBar({super.key, required this.actions});

  final MusamiLayerQuickBarActions actions;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDs.radiusFull),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: kMusamiLayerQuickBarHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (actions.onReplace != null)
                _QuickBarIconButton(
                  icon: Icons.swap_horiz_rounded,
                  tooltip: 'lbl_replace'.tr,
                  onTap: actions.onReplace!,
                ),
              if (actions.onComment != null)
                _QuickBarIconButton(
                  icon: Icons.add_comment_outlined,
                  tooltip: 'lbl_layer_menu_comment'.tr,
                  onTap: actions.onComment!,
                ),
              _QuickBarIconButton(
                icon: Icons.control_point_duplicate_rounded,
                tooltip: 'lbl_layer_menu_duplicate'.tr,
                onTap: actions.onDuplicate,
              ),
              _QuickBarIconButton(
                icon: actions.isLocked
                    ? Icons.lock_rounded
                    : Icons.lock_open_rounded,
                tooltip: actions.isLocked
                    ? 'lbl_layer_menu_unlock'.tr
                    : 'lbl_layer_menu_lock'.tr,
                onTap: actions.onLockToggle,
                emphasized: actions.isLocked,
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
    this.emphasized = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color = emphasized
        ? kMusamiImageSelectionColor
        : _kMusamiLayerQuickBarIconColor;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusFull),
        child: SizedBox(
          width: 40,
          height: kMusamiLayerQuickBarHeight,
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

/// Safe top/bottom insets so OverlayPortal selection chrome stays under the
/// editor app bar and above scaffold bottom toolbars.
///
/// [minTop] should be the reserved editor app-bar height (status + accent +
/// row). Live PIE [appBarHeight] / [canvasBodySize] refine the band when known.
({double top, double bottom}) musamiSelectionOverlayClipInsets({
  required Size screenSize,
  required double appBarHeight,
  required Size canvasBodySize,
  double minTop = 0,
}) {
  final top = math.max(
    minTop.isFinite && minTop > 0 ? minTop : 0.0,
    appBarHeight.isFinite && appBarHeight > 0 ? appBarHeight : 0.0,
  );
  final bodyH = canvasBodySize.height;
  final bottom = bodyH.isFinite && bodyH > 0
      ? math.max(0.0, screenSize.height - top - bodyH)
      : 0.0;
  return (top: top, bottom: bottom);
}

/// Wraps [child] so only the band between [top] and [bottom] screen insets is
/// visible, while keeping [child] in full-overlay coordinates (needed for
/// [Transform] selection frames from OverlayPortal).
Widget musamiClipOverlayPortalToViewport({
  required double top,
  required double bottom,
  required Widget child,
}) {
  final topPad = top.isFinite && top > 0 ? top : 0.0;
  final bottomPad = bottom.isFinite && bottom > 0 ? bottom : 0.0;
  if (topPad <= 0 && bottomPad <= 0) return child;

  // Positive padding shrinks the clip window; matching negative padding puts
  // the child back in absolute overlay space so layer transforms stay aligned.
  return Positioned.fill(
    child: Padding(
      padding: EdgeInsets.only(top: topPad, bottom: bottomPad),
      child: ClipRect(
        child: Padding(
          padding: EdgeInsets.only(top: -topPad, bottom: -bottomPad),
          child: child,
        ),
      ),
    ),
  );
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
    this.appBarHeight = 0,
    this.minAppBarHeight = 0,
    this.editorKey,
  });

  final OverlayChildLayoutInfo info;
  final Layer layer;
  final Size canvasBodySize;
  final MusamiLayerQuickBarActions actions;
  final Widget selectionOverlay;

  /// PIE app-bar height snapshot (may be 0 before first measure).
  final double appBarHeight;

  /// Always-on floor for the top clip (status bar + editor app bar row).
  final double minAppBarHeight;

  /// When set, live [SizesManager] values override stale closure snapshots.
  final GlobalKey<ProImageEditorState>? editorKey;

  @override
  Widget build(BuildContext context) {
    final liveEditor = editorKey?.currentState;
    final liveBody = liveEditor?.sizesManager.bodySize;
    final bodySize = (liveBody != null && liveBody.height > 0)
        ? liveBody
        : canvasBodySize;
    final liveAppBar = liveEditor?.sizesManager.appBarHeight ?? 0;
    final insets = musamiSelectionOverlayClipInsets(
      screenSize: MediaQuery.sizeOf(context),
      appBarHeight: math.max(appBarHeight, liveAppBar),
      canvasBodySize: bodySize,
      minTop: minAppBarHeight,
    );

    final placement = musamiLayerQuickBarPlacement(
      layer: layer,
      canvasBodySize: bodySize,
    );
    final rawAnchor = musamiLayerQuickBarAnchor(
      info: info,
      placement: placement,
    );
    final barW = musamiLayerQuickBarEstimatedWidth(actions);
    final clampedX = musamiLayerQuickBarClampedCenterX(
      centerX: rawAnchor.dx,
      barWidth: barW,
      viewportWidth: bodySize.width > 0
          ? bodySize.width
          : MediaQuery.sizeOf(context).width,
    );

    final chrome = Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        selectionOverlay,
        Positioned(
          left: clampedX,
          top: rawAnchor.dy,
          child: FractionalTranslation(
            translation: const Offset(-0.5, 0),
            child: AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 140),
              child: MusamiLayerFloatingQuickBar(actions: actions),
            ),
          ),
        ),
      ],
    );

    // OverlayPortal paints above Scaffold chrome — always clip to the canvas
    // band so borders/handles cannot cover the app bar or bottom toolbars.
    return musamiClipOverlayPortalToViewport(
      top: insets.top,
      bottom: insets.bottom,
      child: chrome,
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
