import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/core/services/gesture_manager.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../utils/musami_image_fit.dart';

/// Visible knob diameter for transform handles (corners + mid-edges).
const double kMusamiTransformHandleVisualSize = 14;

/// Opaque touch target for transform handles (Material ~48dp friendly).
const double kMusamiTransformHandleHitSize = 44;

/// Canva-like selection stroke for photo layers.
const double kMusamiImageSelectionStrokeWidth = 2;

/// Top-left of a fixed [hitSize] box centered on [handle] of a [boxSize] frame.
///
/// Mid-edge handles must be point-sized (not full-edge strips). Full-edge
/// [Positioned] strips steal hits from corner handles on mobile.
Offset musamiTransformHandleOrigin({
  required TextTransformHandle handle,
  required Size boxSize,
  required double hitSize,
}) {
  final hitHalf = hitSize / 2;
  final midX = boxSize.width / 2 - hitHalf;
  final midY = boxSize.height / 2 - hitHalf;
  return switch (handle) {
    TextTransformHandle.topLeft => Offset(-hitHalf, -hitHalf),
    TextTransformHandle.top => Offset(midX, -hitHalf),
    TextTransformHandle.topRight => Offset(boxSize.width - hitHalf, -hitHalf),
    TextTransformHandle.right => Offset(boxSize.width - hitHalf, midY),
    TextTransformHandle.bottomRight =>
      Offset(boxSize.width - hitHalf, boxSize.height - hitHalf),
    TextTransformHandle.bottom => Offset(midX, boxSize.height - hitHalf),
    TextTransformHandle.bottomLeft => Offset(-hitHalf, boxSize.height - hitHalf),
    TextTransformHandle.left => Offset(-hitHalf, midY),
  };
}

/// Resize handle positions on a selected [TextLayer].
enum TextTransformHandle {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left;

  bool get isCorner =>
      this == topLeft ||
      this == topRight ||
      this == bottomLeft ||
      this == bottomRight;

  /// Direction from layer centre toward this handle (layer-local, unrotated).
  Offset get handleSign {
    return switch (this) {
      TextTransformHandle.topLeft => const Offset(-1, -1),
      TextTransformHandle.top => const Offset(0, -1),
      TextTransformHandle.topRight => const Offset(1, -1),
      TextTransformHandle.right => const Offset(1, 0),
      TextTransformHandle.bottomRight => const Offset(1, 1),
      TextTransformHandle.bottom => const Offset(0, 1),
      TextTransformHandle.bottomLeft => const Offset(-1, 1),
      TextTransformHandle.left => const Offset(-1, 0),
    };
  }

  /// Direction from layer centre toward the anchored (fixed) point.
  Offset get anchorSign => Offset(-handleSign.dx, -handleSign.dy);

  MouseCursor get cursor {
    return switch (this) {
      TextTransformHandle.topLeft || TextTransformHandle.bottomRight =>
        SystemMouseCursors.resizeUpLeftDownRight,
      TextTransformHandle.topRight || TextTransformHandle.bottomLeft =>
        SystemMouseCursors.resizeUpRightDownLeft,
      TextTransformHandle.top ||
      TextTransformHandle.bottom => SystemMouseCursors.resizeUpDown,
      TextTransformHandle.left ||
      TextTransformHandle.right => SystemMouseCursors.resizeLeftRight,
    };
  }
}

class _ResizeSession {
  _ResizeSession({
    required this.handle,
    required this.layerId,
    required this.startScale,
    required this.startMaxTextWidth,
    required this.startFontSize,
    required this.startOffset,
    required this.startVisualSize,
    required this.startPointerGlobal,
    required this.startRotation,
    required this.startFlipX,
    required this.startFlipY,
  });

  final TextTransformHandle handle;
  final String layerId;
  final double startScale;
  final double startMaxTextWidth;
  final double startFontSize;
  final Offset startOffset;
  final Size startVisualSize;
  final Offset startPointerGlobal;
  final double startRotation;
  final bool startFlipX;
  final bool startFlipY;
}

/// Figma / Canva-style 8-point transform overlay for canvas [TextLayer] elements.
class MusamiTextLayerTransformOverlay extends StatefulWidget {
  const MusamiTextLayerTransformOverlay({
    super.key,
    required this.info,
    required this.layer,
    required this.editorKey,
    required this.strokeColor,
    this.strokeWidth = 1.5,
    this.handleSize = kMusamiTransformHandleVisualSize,
    this.handleHitSize = kMusamiTransformHandleHitSize,
  });

  final OverlayChildLayoutInfo info;
  final TextLayer layer;
  final GlobalKey<ProImageEditorState> editorKey;
  final Color strokeColor;
  final double strokeWidth;
  final double handleSize;
  final double handleHitSize;

  @override
  State<MusamiTextLayerTransformOverlay> createState() =>
      _MusamiTextLayerTransformOverlayState();
}

class _MusamiTextLayerTransformOverlayState
    extends State<MusamiTextLayerTransformOverlay> {
  _ResizeSession? _session;
  int? _activePointer;
  PointerRoute? _pointerRoute;
  bool _isDisposing = false;
  bool _editorNotifyScheduled = false;

  TextLayer get _layer => widget.layer;

  ProImageEditorState? get _editor => widget.editorKey.currentState;

  TextEditorConfigs get _textConfigs =>
      _editor?.configs.textEditor ?? const TextEditorConfigs();

  /// After [ProImageEditorState.addHistory], layers are deep-copied; always
  /// resolve the live instance from the editor stack by id.
  TextLayer? _resolveLiveLayer() {
    final editor = _editor;
    if (editor == null) return null;
    final id = widget.layer.id;
    for (final layer in editor.activeLayers) {
      if (layer.id == id && layer is TextLayer) {
        return layer;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _isDisposing = true;
    _cleanupSessionResources(notifyEditor: false);
    super.dispose();
  }

  void _removePointerRoute() {
    if (_activePointer != null && _pointerRoute != null) {
      GestureBinding.instance.pointerRouter.removeRoute(
        _activePointer!,
        _pointerRoute!,
      );
    }
    _pointerRoute = null;
    _activePointer = null;
  }

  void _setEditorDragBlock(bool blocked) {
    final editor = widget.editorKey.currentState;
    if (editor == null) return;
    editor.blockOnScaleUpdateFunction = blocked;
  }

  /// Tear down pointer routing and restore editor flags without triggering rebuilds.
  void _cleanupSessionResources({required bool notifyEditor}) {
    _removePointerRoute();
    _setEditorDragBlock(false);
    _session = null;

    final editor = widget.editorKey.currentState;
    if (editor == null) return;

    editor.layerInteractionManager
      ..enabledHitDetection = true
      ..activeInteractionLayer = null;

    if (!notifyEditor || _isDisposing || !mounted) return;

    editor.callbacks.mainEditorCallbacks?.handleUpdateUI();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposing || !mounted) return;
      final ed = widget.editorKey.currentState;
      if (ed != null && ed.mounted) {
        ed.setState(() {});
      }
    });
  }

  void _finishSession() {
    _cleanupSessionResources(notifyEditor: true);
  }

  @override
  Widget build(BuildContext context) {
    final childWidth = widget.info.childSize.width;
    final childHeight = widget.info.childSize.height;
    final transform = widget.info.childPaintTransform.clone();

    return Positioned(
      width: childWidth,
      height: childHeight,
      left: 0,
      child: Transform(
        transform: transform,
        alignment: Alignment.topLeft,
        child: Transform.flip(
          flipX: _layer.flipX,
          flipY: _layer.flipY,
          child: Stack(
            fit: StackFit.passthrough,
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                foregroundPainter: _SelectionBorderPainter(
                  color: widget.strokeColor,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
              // Edges under corners so corner hits win if targets slightly overlap.
              ...TextTransformHandle.values
                  .where((h) => !h.isCorner)
                  .map(_buildHandle),
              ...TextTransformHandle.values
                  .where((h) => h.isCorner)
                  .map(_buildHandle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(TextTransformHandle handle) {
    final hit = widget.handleHitSize;
    final origin = musamiTransformHandleOrigin(
      handle: handle,
      boxSize: widget.info.childSize,
      hitSize: hit,
    );
    return Positioned(
      left: origin.dx,
      top: origin.dy,
      width: hit,
      height: hit,
      child: _TransformHandle(
        handle: handle,
        visualSize: widget.handleSize,
        hitSize: hit,
        color: widget.strokeColor,
        onPointerDown: (event) => _onHandleDown(handle, event),
      ),
    );
  }

  void _onHandleDown(TextTransformHandle handle, PointerDownEvent event) {
    if (!mounted || _isDisposing) return;
    if (!_layer.interaction.enableScale) return;
    final editor = _editor;
    if (editor == null || !editor.mounted) return;

    final liveLayer = _resolveLiveLayer();
    if (liveLayer == null) return;

    _activePointer = event.pointer;
    _pointerRoute = _handlePointerRoute;
    GestureBinding.instance.pointerRouter.addRoute(
      event.pointer,
      _pointerRoute!,
    );
    GestureManager.instance.stopPropagation();
    _setEditorDragBlock(true);

    editor.layerInteractionManager
      ..enabledHitDetection = false
      ..activeInteractionLayer = liveLayer
      ..layerWasTransformed = true;

    final visualSize = widget.info.childSize;
    final initFontSize = _textConfigs.initFontSize;

    editor.addHistory(blockCaptureScreenshot: true);

    // Re-resolve after history clones the layer list.
    final layerAfterHistory = _resolveLiveLayer();
    if (layerAfterHistory == null) return;

    _session = _ResizeSession(
      handle: handle,
      layerId: layerAfterHistory.id,
      startScale: layerAfterHistory.scale,
      startMaxTextWidth:
          layerAfterHistory.maxTextWidth ??
          (visualSize.width / layerAfterHistory.scale).clamp(40, 4000),
      startFontSize:
          layerAfterHistory.textStyle?.fontSize ??
          (initFontSize * layerAfterHistory.fontScale),
      startOffset: layerAfterHistory.offset,
      startVisualSize: visualSize,
      startPointerGlobal: event.position,
      startRotation: layerAfterHistory.rotation,
      startFlipX: layerAfterHistory.flipX,
      startFlipY: layerAfterHistory.flipY,
    );
  }

  void _handlePointerRoute(PointerEvent event) {
    if (!mounted || _isDisposing || _session == null) return;
    if (_activePointer != event.pointer) return;

    if (event is PointerMoveEvent) {
      _onHandleMove(event);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _finishSession();
    }
  }

  void _onHandleMove(PointerMoveEvent event) {
    if (!mounted || _isDisposing || _session == null) return;
    if (_activePointer != event.pointer) return;

    final editor = _editor;
    if (editor == null || !editor.mounted) return;

    final deltaGlobal = event.position - _session!.startPointerGlobal;
    final liveLayer = _resolveLiveLayer();
    if (liveLayer == null) return;

    final deltaLocal = _globalDeltaToLayerLocal(deltaGlobal, liveLayer);

    if (_session!.handle.isCorner) {
      _applyCornerResize(_session!, liveLayer, deltaLocal);
    } else {
      _applyEdgeResize(_session!, liveLayer, deltaLocal);
    }

    _notifyLayerChanged(liveLayer);
  }

  /// Updates the layer widget immediately and coalesces editor rebuilds per frame.
  void _notifyLayerChanged(TextLayer layer) {
    layer.key.currentState?.setState(() {});

    final editor = _editor;
    if (editor == null || !editor.mounted) return;
    editor.callbacks.mainEditorCallbacks?.handleUpdateLayer(layer);

    if (_editorNotifyScheduled) return;
    _editorNotifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editorNotifyScheduled = false;
      if (_isDisposing || !mounted) return;
      final ed = widget.editorKey.currentState;
      if (ed != null && ed.mounted) {
        ed.setState(() {});
      }
    });
  }

  /// Corner drag — proportional scale (width + height), opposite corner fixed.
  void _applyCornerResize(
    _ResizeSession session,
    TextLayer layer,
    Offset deltaLocal,
  ) {
    final grow = _projectOntoHandle(session.handle, deltaLocal);

    final startW = session.startVisualSize.width;
    final startH = session.startVisualSize.height;

    final sx = startW > 0 ? (startW + grow.dx) / startW : 1.0;
    final sy = startH > 0 ? (startH + grow.dy) / startH : 1.0;

    // Uniform scale — same behaviour as Canva / Figma corner handles.
    final factor = math.max(sx, sy).clamp(0.08, 12.0);
    final minScale = _textConfigs.minScale;
    final maxScale = _textConfigs.maxScale;
    final newScale = (session.startScale * factor).clamp(minScale, maxScale);
    final applied = newScale / session.startScale;

    layer.scale = newScale;

    final newSize = Size(startW * applied, startH * applied);
    _repositionKeepingAnchor(session, layer, newSize);
  }

  /// Side drag — single-axis resize, opposite edge fixed.
  void _applyEdgeResize(
    _ResizeSession session,
    TextLayer layer,
    Offset deltaLocal,
  ) {
    final handle = session.handle;
    final grow = _projectOntoHandle(handle, deltaLocal);

    if (handle == TextTransformHandle.left ||
        handle == TextTransformHandle.right) {
      layer.maxTextWidth =
          (session.startMaxTextWidth + grow.dx / session.startScale).clamp(
            24.0,
            4000.0,
          );

      final newVisualW = layer.maxTextWidth! * session.startScale;
      _repositionKeepingAnchor(
        session,
        layer,
        Size(newVisualW, session.startVisualSize.height),
      );
      return;
    }

    // Top / bottom — adjust base font size (height axis).
    final newFontSize = (session.startFontSize + grow.dy / session.startScale)
        .clamp(8.0, 400.0);
    _setFontSize(layer, newFontSize);

    final heightRatio = session.startFontSize > 0
        ? newFontSize / session.startFontSize
        : 1.0;
    final newVisualH = session.startVisualSize.height * heightRatio;
    _repositionKeepingAnchor(
      session,
      layer,
      Size(session.startVisualSize.width, newVisualH),
    );
  }

  /// Maps drag delta into the handle's growth direction (layer-local space).
  Offset _projectOntoHandle(TextTransformHandle handle, Offset deltaLocal) {
    final sign = handle.handleSign;
    return Offset(
      sign.dx == 0 ? 0 : deltaLocal.dx * sign.dx,
      sign.dy == 0 ? 0 : deltaLocal.dy * sign.dy,
    );
  }

  /// Keeps the anchored corner/edge fixed while the visual size changes.
  void _repositionKeepingAnchor(
    _ResizeSession session,
    TextLayer layer,
    Size newVisualSize,
  ) {
    final anchor = session.handle.anchorSign;
    final startW = session.startVisualSize.width;
    final startH = session.startVisualSize.height;

    final startAnchorLocal = Offset(
      anchor.dx * startW / 2,
      anchor.dy * startH / 2,
    );
    final newAnchorLocal = Offset(
      anchor.dx * newVisualSize.width / 2,
      anchor.dy * newVisualSize.height / 2,
    );

    final shift = _localDeltaToEditor(
      startAnchorLocal - newAnchorLocal,
      layer.rotation,
      layer.flipX,
      layer.flipY,
    );
    layer.offset = session.startOffset + shift;
  }

  Offset _globalDeltaToLayerLocal(Offset deltaGlobal, TextLayer layer) {
    final editor = _editor;
    if (editor == null) return deltaGlobal;

    final scaleFactor =
        editor.interactiveViewer.currentState?.scaleFactor ?? 1.0;
    final scaled = deltaGlobal / scaleFactor;

    final angle = -layer.rotation;
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    var dx = scaled.dx * cos - scaled.dy * sin;
    var dy = scaled.dx * sin + scaled.dy * cos;

    if (layer.flipX) dx = -dx;
    if (layer.flipY) dy = -dy;
    return Offset(dx, dy);
  }

  Offset _localDeltaToEditor(
    Offset localDelta,
    double rotation,
    bool flipX,
    bool flipY,
  ) {
    var dx = localDelta.dx;
    var dy = localDelta.dy;
    if (flipX) dx = -dx;
    if (flipY) dy = -dy;

    final cos = math.cos(rotation);
    final sin = math.sin(rotation);
    return Offset(dx * cos - dy * sin, dx * sin + dy * cos);
  }

  void _setFontSize(TextLayer layer, double size) {
    final style = layer.textStyle ?? const TextStyle();
    layer.textStyle = style.copyWith(fontSize: size);
  }
}

typedef MusamiWidgetLayerGeometryCallback =
    void Function(
      WidgetLayer layer, {
      required double width,
      required double aspect,
      required double scale,
      required Offset offset,
    });

/// Immutable snapshot taken on pointer-down.
///
/// Every move event derives the new frame from this snapshot instead of the
/// already-modified layer, which keeps the drag jitter-free and stops rounding
/// errors from accumulating over a long gesture.
class _WidgetResizeSession {
  _WidgetResizeSession({
    required this.handle,
    required this.layerId,
    required this.startScale,
    required this.startOffset,
    required this.startFrameSize,
    required this.startPointerGlobal,
    required this.startRotation,
    required this.startFlipX,
    required this.startFlipY,
    required this.maintainAspect,
  });

  final TextTransformHandle handle;
  final String layerId;
  final double startScale;
  final Offset startOffset;

  /// On-canvas size of the frame, selection chrome padding excluded.
  final Size startFrameSize;
  final Offset startPointerGlobal;
  final double startRotation;
  final bool startFlipX;
  final bool startFlipY;

  /// When true, corner/edge drags keep [startFrameSize] aspect.
  final bool maintainAspect;
}

/// Figma / Canva-style 8-point transform overlay for canvas [WidgetLayer] images.
class MusamiWidgetLayerTransformOverlay extends StatefulWidget {
  const MusamiWidgetLayerTransformOverlay({
    super.key,
    required this.info,
    required this.layer,
    required this.editorKey,
    required this.onApplyGeometry,
    required this.strokeColor,
    this.strokeWidth = kMusamiImageSelectionStrokeWidth,
    this.handleSize = kMusamiTransformHandleVisualSize,
    this.handleHitSize = kMusamiTransformHandleHitSize,
  });

  final OverlayChildLayoutInfo info;
  final WidgetLayer layer;
  final GlobalKey<ProImageEditorState> editorKey;
  final MusamiWidgetLayerGeometryCallback onApplyGeometry;
  final Color strokeColor;
  final double strokeWidth;
  final double handleSize;
  final double handleHitSize;

  @override
  State<MusamiWidgetLayerTransformOverlay> createState() =>
      _MusamiWidgetLayerTransformOverlayState();
}

class _MusamiWidgetLayerTransformOverlayState
    extends State<MusamiWidgetLayerTransformOverlay> {
  _WidgetResizeSession? _session;
  int? _activePointer;
  PointerRoute? _pointerRoute;
  bool _isDisposing = false;
  bool _editorNotifyScheduled = false;

  /// Frame size shown in the live badge; `null` hides it (no active drag).
  final ValueNotifier<Size?> _liveFrameSize = ValueNotifier<Size?>(null);

  WidgetLayer get _layer => widget.layer;

  ProImageEditorState? get _editor => widget.editorKey.currentState;

  WidgetLayer? _resolveLiveLayer() {
    final editor = _editor;
    if (editor == null) return null;
    final id = widget.layer.id;
    for (final layer in editor.activeLayers) {
      if (layer.id == id && layer is WidgetLayer) {
        return layer;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _isDisposing = true;
    _cleanupSessionResources(notifyEditor: false);
    _liveFrameSize.dispose();
    super.dispose();
  }

  void _removePointerRoute() {
    if (_activePointer != null && _pointerRoute != null) {
      GestureBinding.instance.pointerRouter.removeRoute(
        _activePointer!,
        _pointerRoute!,
      );
    }
    _pointerRoute = null;
    _activePointer = null;
  }

  void _setEditorDragBlock(bool blocked) {
    final editor = widget.editorKey.currentState;
    if (editor == null) return;
    editor.blockOnScaleUpdateFunction = blocked;
  }

  void _cleanupSessionResources({required bool notifyEditor}) {
    _removePointerRoute();
    _setEditorDragBlock(false);
    _session = null;
    if (!_isDisposing) _liveFrameSize.value = null;

    final editor = widget.editorKey.currentState;
    if (editor == null) return;

    editor.layerInteractionManager
      ..enabledHitDetection = true
      ..activeInteractionLayer = null;

    if (!notifyEditor || _isDisposing || !mounted) return;

    editor.callbacks.mainEditorCallbacks?.handleUpdateUI();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposing || !mounted) return;
      final ed = widget.editorKey.currentState;
      if (ed != null && ed.mounted) {
        ed.setState(() {});
      }
    });
  }

  void _finishSession() {
    final editor = _editor;
    final layerId = _session?.layerId;
    _cleanupSessionResources(notifyEditor: true);
    if (editor != null && layerId != null && editor.mounted) {
      editor.layerInteractionManager
        ..selectedLayerId = layerId
        ..layerWasTransformed = true;
    }
  }

  EdgeInsets get _overlayPad =>
      _editor?.configs.layerInteraction.style.overlayPadding ?? EdgeInsets.zero;

  /// Content box inside PIE overlay padding — selection must hug the image.
  Size get _contentBoxSize {
    final raw = widget.info.childSize;
    final pad = _overlayPad;
    return Size(
      math.max(raw.width - pad.horizontal, 1.0),
      math.max(raw.height - pad.vertical, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final childWidth = widget.info.childSize.width;
    final childHeight = widget.info.childSize.height;
    final transform = widget.info.childPaintTransform.clone();
    final pad = _overlayPad;
    final content = _contentBoxSize;

    return Positioned(
      width: childWidth,
      height: childHeight,
      left: 0,
      child: Transform(
        transform: transform,
        alignment: Alignment.topLeft,
        child: Transform.flip(
          flipX: _layer.flipX,
          flipY: _layer.flipY,
          child: Stack(
            fit: StackFit.passthrough,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: pad.left,
                top: pad.top,
                width: content.width,
                height: content.height,
                child: Stack(
                  fit: StackFit.passthrough,
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      foregroundPainter: _SelectionBorderPainter(
                        color: widget.strokeColor,
                        strokeWidth: widget.strokeWidth,
                      ),
                    ),
                    // Edges under corners so corner hits win if targets overlap.
                    ...TextTransformHandle.values
                        .where((h) => !h.isCorner)
                        .map(_buildHandle),
                    ...TextTransformHandle.values
                        .where((h) => h.isCorner)
                        .map(_buildHandle),
                    _buildLiveSizeBadge(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Live dimension readout; flips above the frame when dragging a bottom handle
  /// so it stays away from the finger.
  Widget _buildLiveSizeBadge() {
    final handle = _session?.handle;
    final preferAbove = handle == TextTransformHandle.bottom ||
        handle == TextTransformHandle.bottomLeft ||
        handle == TextTransformHandle.bottomRight;
    final gap = widget.handleHitSize / 2 + 10;

    return Positioned(
      left: 0,
      right: 0,
      top: preferAbove ? -gap - 28 : null,
      bottom: preferAbove ? null : -gap - 4,
      height: 28,
      child: ValueListenableBuilder<Size?>(
        valueListenable: _liveFrameSize,
        builder: (context, size, _) {
          final visible = size != null;
          return IgnorePointer(
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: visible
                  ? Center(
                      child: Transform.rotate(
                        angle: -_frameRotation(
                          _layer.rotation,
                          _layer.flipX,
                          _layer.flipY,
                        ),
                        child: _FrameSizeBadge(
                          size: size,
                          accent: widget.strokeColor,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandle(TextTransformHandle handle) {
    final hit = widget.handleHitSize;
    final origin = musamiTransformHandleOrigin(
      handle: handle,
      boxSize: _contentBoxSize,
      hitSize: hit,
    );
    return Positioned(
      left: origin.dx,
      top: origin.dy,
      width: hit,
      height: hit,
      child: _TransformHandle(
        handle: handle,
        visualSize: widget.handleSize,
        hitSize: hit,
        color: widget.strokeColor,
        onPointerDown: (event) => _onHandleDown(handle, event),
      ),
    );
  }

  void _onHandleDown(TextTransformHandle handle, PointerDownEvent event) {
    if (!mounted || _isDisposing) return;
    if (!_layer.interaction.enableScale) return;
    final editor = _editor;
    if (editor == null || !editor.mounted) return;

    final liveLayer = _resolveLiveLayer();
    if (liveLayer == null) return;

    _activePointer = event.pointer;
    _pointerRoute = _handlePointerRoute;
    GestureBinding.instance.pointerRouter.addRoute(
      event.pointer,
      _pointerRoute!,
    );
    GestureManager.instance.stopPropagation();
    _setEditorDragBlock(true);

    editor.layerInteractionManager
      ..enabledHitDetection = false
      ..activeInteractionLayer = liveLayer
      ..layerWasTransformed = true;

    final frameSize = _frameSize();

    editor.addHistory(blockCaptureScreenshot: true);

    final layerAfterHistory = _resolveLiveLayer();
    if (layerAfterHistory == null) return;

    editor.layerInteractionManager.selectedLayerId = layerAfterHistory.id;

    _session = _WidgetResizeSession(
      handle: handle,
      layerId: layerAfterHistory.id,
      startScale: layerAfterHistory.scale,
      startOffset: layerAfterHistory.offset,
      startFrameSize: frameSize,
      startPointerGlobal: event.position,
      startRotation: layerAfterHistory.rotation,
      startFlipX: layerAfterHistory.flipX,
      startFlipY: layerAfterHistory.flipY,
      maintainAspect: musamiMaintainAspectFromMeta(layerAfterHistory.meta),
    );
    _liveFrameSize.value = frameSize;
    // Rebuild so the dimension badge can flip above/below for the active handle.
    if (mounted) setState(() {});
  }

  /// On-canvas frame size with the selection chrome padding removed.
  ///
  /// [OverlayChildLayoutInfo.childSize] measures the layer content *plus* the
  /// [LayerInteractionStyle.overlayPadding] that `LayerWidget` inserts while a
  /// layer is selected. Feeding that padded box into the resize math skews the
  /// frame the user sees, so it is stripped here.
  Size _frameSize() {
    final raw = widget.info.childSize;
    final padding = _editor?.configs.layerInteraction.style.overlayPadding;
    final width = raw.width - (padding?.horizontal ?? 0);
    final height = raw.height - (padding?.vertical ?? 0);
    return Size(
      width.isFinite && width > 0 ? width : math.max(raw.width, 1),
      height.isFinite && height > 0 ? height : math.max(raw.height, 1),
    );
  }

  void _handlePointerRoute(PointerEvent event) {
    if (!mounted || _isDisposing || _session == null) return;
    if (_activePointer != event.pointer) return;

    if (event is PointerMoveEvent) {
      _onHandleMove(event);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _finishSession();
    }
  }

  void _onHandleMove(PointerMoveEvent event) {
    if (!mounted || _isDisposing || _session == null) return;
    if (_activePointer != event.pointer) return;

    final editor = _editor;
    if (editor == null || !editor.mounted) return;

    final session = _session!;
    final deltaGlobal = event.position - session.startPointerGlobal;
    final liveLayer = _resolveLiveLayer();
    if (liveLayer == null) return;

    final deltaLocal = _globalDeltaToLayerLocal(deltaGlobal, session);

    if (session.handle.isCorner) {
      _applyCornerResize(session, liveLayer, deltaLocal);
    } else {
      _applyEdgeResize(session, liveLayer, deltaLocal);
    }

    _notifyLayerChanged(liveLayer);
  }

  /// Live-paints the layer via its GlobalKey; coalesces editor chrome rebuilds.
  void _notifyLayerChanged(WidgetLayer layer) {
    // Same path as text overlay / pro_image_editor scale: LayerWidget paints
    // from this setState. Editor setState alone only refreshes after canvas tap.
    layer.key.currentState?.setState(() {});

    final editor = _editor;
    if (editor == null || !editor.mounted) return;
    editor.callbacks.mainEditorCallbacks?.handleUpdateLayer(layer);
    editor.layerInteractionManager.selectedLayerId = layer.id;

    if (_editorNotifyScheduled) return;
    _editorNotifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editorNotifyScheduled = false;
      if (_isDisposing || !mounted) return;
      final ed = widget.editorKey.currentState;
      if (ed != null && ed.mounted) {
        ed.layerInteractionManager.selectedLayerId = layer.id;
        ed.setState(() {});
      }
    });
  }

  /// Corner drag — free: W+H independent; locked: preserve start aspect.
  /// Opposite corner stays anchored via [_offsetKeepingAnchor].
  void _applyCornerResize(
    _WidgetResizeSession session,
    WidgetLayer layer,
    Offset deltaLocal,
  ) {
    final grow = _projectOntoHandle(session.handle, deltaLocal);
    _applyFrameSize(
      session,
      layer,
      musamiResizeFrameFromGesture(
        start: session.startFrameSize,
        grow: grow,
        maintainAspect: session.maintainAspect,
        isCorner: true,
        isHorizontalEdge: false,
      ),
    );
  }

  /// Mid-edge drag — free: one axis; locked: other axis follows aspect.
  void _applyEdgeResize(
    _WidgetResizeSession session,
    WidgetLayer layer,
    Offset deltaLocal,
  ) {
    final handle = session.handle;
    final isHorizontal =
        handle == TextTransformHandle.left ||
        handle == TextTransformHandle.right;

    final grow = _projectOntoHandle(handle, deltaLocal);
    _applyFrameSize(
      session,
      layer,
      musamiResizeFrameFromGesture(
        start: session.startFrameSize,
        grow: grow,
        maintainAspect: session.maintainAspect,
        isCorner: false,
        isHorizontalEdge: isHorizontal,
      ),
    );
  }

  /// Commits a new frame size, keeping the anchor pinned and the layer scale
  /// untouched — only the frame geometry changes.
  void _applyFrameSize(
    _WidgetResizeSession session,
    WidgetLayer layer,
    Size requested,
  ) {
    if (session.startScale <= 0 || !session.startScale.isFinite) return;
    if (!requested.width.isFinite || !requested.height.isFinite) return;

    // musamiResizeFrameFromGesture already clamps; re-clamp for safety.
    final frame = Size(
      requested.width.clamp(kMusamiMinFrameSizePx, kMusamiMaxFrameSizePx),
      requested.height.clamp(kMusamiMinFrameSizePx, kMusamiMaxFrameSizePx),
    );

    widget.onApplyGeometry(
      layer,
      width: frame.width / session.startScale,
      aspect: frame.height / frame.width,
      scale: session.startScale,
      offset: musamiOffsetKeepingAnchor(
        startOffset: session.startOffset,
        startFrame: session.startFrameSize,
        newFrame: frame,
        anchorSign: session.handle.anchorSign,
        rotation: session.startRotation,
        flipX: session.startFlipX,
        flipY: session.startFlipY,
      ),
    );
    _liveFrameSize.value = frame;
  }

  Offset _projectOntoHandle(TextTransformHandle handle, Offset deltaLocal) {
    final sign = handle.handleSign;
    return Offset(
      sign.dx == 0 ? 0 : deltaLocal.dx * sign.dx,
      sign.dy == 0 ? 0 : deltaLocal.dy * sign.dy,
    );
  }

  /// Rotation between the overlay's local frame and canvas coordinates.
  ///
  /// The overlay re-applies the layer flip on top of
  /// [OverlayChildLayoutInfo.childPaintTransform], which already carries it, so
  /// the two mirrors cancel out (`F · R · F == R⁻¹` for a single-axis flip).
  /// The frame is therefore never mirrored, only rotated.
  double _frameRotation(double rotation, bool flipX, bool flipY) {
    return flipX == flipY ? rotation : -rotation;
  }

  Offset _rotateOffset(Offset value, double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Offset(
      value.dx * cos - value.dy * sin,
      value.dx * sin + value.dy * cos,
    );
  }

  /// Screen pointer delta -> canvas delta -> layer-local delta.
  Offset _globalDeltaToLayerLocal(
    Offset deltaGlobal,
    _WidgetResizeSession session,
  ) {
    final editor = _editor;
    final viewerScale =
        editor?.interactiveViewer.currentState?.scaleFactor ?? 1.0;
    final canvasDelta = musamiScreenDeltaToCanvasDelta(deltaGlobal, viewerScale);

    return _rotateOffset(
      canvasDelta,
      -_frameRotation(
        session.startRotation,
        session.startFlipX,
        session.startFlipY,
      ),
    );
  }
}

class _TransformHandle extends StatefulWidget {
  const _TransformHandle({
    required this.handle,
    required this.visualSize,
    required this.hitSize,
    required this.color,
    required this.onPointerDown,
  });

  final TextTransformHandle handle;
  final double visualSize;
  final double hitSize;
  final Color color;
  final ValueChanged<PointerDownEvent> onPointerDown;

  @override
  State<_TransformHandle> createState() => _TransformHandleState();
}

class _TransformHandleState extends State<_TransformHandle> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final knobSize = widget.visualSize;
    final scale = _pressed ? 1.18 : 1.0;

    return MouseRegion(
      cursor: widget.handle.cursor,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          setState(() => _pressed = true);
          widget.onPointerDown(event);
        },
        onPointerUp: (_) {
          if (_pressed) setState(() => _pressed = false);
        },
        onPointerCancel: (_) {
          if (_pressed) setState(() => _pressed = false);
        },
        child: SizedBox(
          width: widget.hitSize,
          height: widget.hitSize,
          child: Center(
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOut,
              child: Container(
                width: knobSize,
                height: knobSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.color, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Color(_pressed ? 0x66000000 : 0x40000000),
                      blurRadius: _pressed ? 5 : 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact dimension pill shown under/above a frame while it is being resized.
class _FrameSizeBadge extends StatelessWidget {
  const _FrameSizeBadge({required this.size, required this.accent});

  final Size size;
  final Color accent;

  String _format(double value) {
    final rounded = value.roundToDouble();
    return (value - rounded).abs() < 0.05
        ? rounded.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF2141414),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.85), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          '${_format(size.width)} × ${_format(size.height)}',
          maxLines: 1,
          softWrap: false,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            height: 1.15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            decoration: TextDecoration.none,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _SelectionBorderPainter extends CustomPainter {
  const _SelectionBorderPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    // Inset by half stroke so the border sits on the image edge, not outside.
    final inset = strokeWidth / 2;
    canvas.drawRect(
      Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SelectionBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Default layer selection overlay (border + scale/rotate handle) for non-text layers.
class MusamiDefaultLayerTransformOverlay extends StatelessWidget {
  const MusamiDefaultLayerTransformOverlay({
    super.key,
    required this.info,
    required this.layer,
    required this.interactions,
    required this.strokeColor,
    this.strokeWidth = 1.5,
  });

  final OverlayChildLayoutInfo info;
  final Layer layer;
  final LayerItemInteractions interactions;
  final Color strokeColor;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final childWidth = info.childSize.width;
    final childHeight = info.childSize.height;
    final transform = info.childPaintTransform.clone();
    final rotation = layer.flipX ? layer.rotation : -layer.rotation;

    return Positioned(
      width: childWidth,
      height: childHeight,
      left: 0,
      child: Transform(
        transform: transform,
        alignment: Alignment.topLeft,
        child: Transform.flip(
          flipX: layer.flipX,
          flipY: layer.flipY,
          child: Stack(
            fit: StackFit.passthrough,
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                foregroundPainter: _SelectionBorderPainter(
                  color: strokeColor,
                  strokeWidth: strokeWidth,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: interactions.scaleRotateDown,
                  onPointerUp: interactions.scaleRotateUp,
                  child: Transform.rotate(
                    angle: rotation,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: strokeColor, width: 1.5),
                        ),
                        child: Icon(
                          Icons.open_with,
                          size: 16,
                          color: strokeColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
