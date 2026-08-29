import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/core/services/gesture_manager.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

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
    this.handleSize = 10,
    this.handleHitSize = 28,
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
              ...TextTransformHandle.values.map(_buildHandle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(TextTransformHandle handle) {
    final hitHalf = widget.handleHitSize / 2;

    double? top;
    double? bottom;
    double? left;
    double? right;

    switch (handle) {
      case TextTransformHandle.topLeft:
        top = -hitHalf;
        left = -hitHalf;
      case TextTransformHandle.top:
        top = -hitHalf;
        left = 0;
        right = 0;
      case TextTransformHandle.topRight:
        top = -hitHalf;
        right = -hitHalf;
      case TextTransformHandle.right:
        top = 0;
        bottom = 0;
        right = -hitHalf;
      case TextTransformHandle.bottomRight:
        bottom = -hitHalf;
        right = -hitHalf;
      case TextTransformHandle.bottom:
        bottom = -hitHalf;
        left = 0;
        right = 0;
      case TextTransformHandle.bottomLeft:
        bottom = -hitHalf;
        left = -hitHalf;
      case TextTransformHandle.left:
        top = 0;
        bottom = 0;
        left = -hitHalf;
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: _TransformHandle(
        handle: handle,
        visualSize: widget.handleSize,
        hitSize: widget.handleHitSize,
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

/// Smallest / largest painted (on-canvas) frame size a resize may produce.
///
/// The frame is free to become any ratio inside these bounds — portrait,
/// landscape, square, very wide or very tall — because the image content is
/// cropped to the frame rather than stretched into it.
const double _kMinFrameSizePx = 16;
const double _kMaxFrameSizePx = 6000;

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
    this.strokeWidth = 1.5,
    this.handleSize = 10,
    this.handleHitSize = 28,
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
              ...TextTransformHandle.values.map(_buildHandle),
              _buildLiveSizeBadge(),
            ],
          ),
        ),
      ),
    );
  }

  /// Live `W … H …` readout of the FRAME while a handle is being dragged.
  Widget _buildLiveSizeBadge() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: -(widget.handleHitSize / 2) - 26,
      height: 24,
      child: ValueListenableBuilder<Size?>(
        valueListenable: _liveFrameSize,
        builder: (context, size, _) {
          if (size == null) return const SizedBox.shrink();
          // Counter-rotate so the readout stays upright on a rotated frame.
          return Center(
            child: Transform.rotate(
              angle: -_frameRotation(
                _layer.rotation,
                _layer.flipX,
                _layer.flipY,
              ),
              child: _FrameSizeBadge(size: size, color: widget.strokeColor),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandle(TextTransformHandle handle) {
    final hitHalf = widget.handleHitSize / 2;

    double? top;
    double? bottom;
    double? left;
    double? right;

    switch (handle) {
      case TextTransformHandle.topLeft:
        top = -hitHalf;
        left = -hitHalf;
      case TextTransformHandle.top:
        top = -hitHalf;
        left = 0;
        right = 0;
      case TextTransformHandle.topRight:
        top = -hitHalf;
        right = -hitHalf;
      case TextTransformHandle.right:
        top = 0;
        bottom = 0;
        right = -hitHalf;
      case TextTransformHandle.bottomRight:
        bottom = -hitHalf;
        right = -hitHalf;
      case TextTransformHandle.bottom:
        bottom = -hitHalf;
        left = 0;
        right = 0;
      case TextTransformHandle.bottomLeft:
        bottom = -hitHalf;
        left = -hitHalf;
      case TextTransformHandle.left:
        top = 0;
        bottom = 0;
        left = -hitHalf;
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: _TransformHandle(
        handle: handle,
        visualSize: widget.handleSize,
        hitSize: widget.handleHitSize,
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
    );
    _liveFrameSize.value = frameSize;
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

  /// Corner drag — width and height move independently, opposite corner pinned.
  ///
  /// The frame is free to take any ratio; the image inside is re-cropped by
  /// [musamiFrameWidgetLayerCore], never stretched.
  void _applyCornerResize(
    _WidgetResizeSession session,
    WidgetLayer layer,
    Offset deltaLocal,
  ) {
    final grow = _projectOntoHandle(session.handle, deltaLocal);
    _applyFrameSize(
      session,
      layer,
      Size(
        session.startFrameSize.width + grow.dx,
        session.startFrameSize.height + grow.dy,
      ),
    );
  }

  /// Mid-edge drag — moves one axis of the frame and leaves the other alone.
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
      Size(
        session.startFrameSize.width + (isHorizontal ? grow.dx : 0),
        session.startFrameSize.height + (isHorizontal ? 0 : grow.dy),
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

    final frame = Size(
      requested.width.clamp(_kMinFrameSizePx, _kMaxFrameSizePx),
      requested.height.clamp(_kMinFrameSizePx, _kMaxFrameSizePx),
    );

    widget.onApplyGeometry(
      layer,
      width: frame.width / session.startScale,
      aspect: frame.height / frame.width,
      scale: session.startScale,
      offset: _offsetKeepingAnchor(session, frame),
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

  /// Moves the layer centre so the corner/edge opposite the dragged handle
  /// stays at the exact same canvas point while the frame grows or shrinks.
  Offset _offsetKeepingAnchor(
    _WidgetResizeSession session,
    Size newFrameSize,
  ) {
    final anchor = session.handle.anchorSign;
    final startW = session.startFrameSize.width;
    final startH = session.startFrameSize.height;

    final startAnchorLocal = Offset(
      anchor.dx * startW / 2,
      anchor.dy * startH / 2,
    );
    final newAnchorLocal = Offset(
      anchor.dx * newFrameSize.width / 2,
      anchor.dy * newFrameSize.height / 2,
    );

    final shift = _localDeltaToEditor(
      startAnchorLocal - newAnchorLocal,
      session.startRotation,
      session.startFlipX,
      session.startFlipY,
    );
    final next = session.startOffset + shift;
    if (!next.dx.isFinite || !next.dy.isFinite) return session.startOffset;
    return next;
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
    if (!deltaGlobal.dx.isFinite || !deltaGlobal.dy.isFinite) return Offset.zero;

    final editor = _editor;
    final viewerScale =
        editor?.interactiveViewer.currentState?.scaleFactor ?? 1.0;
    final canvasDelta = (viewerScale.isFinite && viewerScale > 0)
        ? deltaGlobal / viewerScale
        : deltaGlobal;

    return _rotateOffset(
      canvasDelta,
      -_frameRotation(
        session.startRotation,
        session.startFlipX,
        session.startFlipY,
      ),
    );
  }

  Offset _localDeltaToEditor(
    Offset localDelta,
    double rotation,
    bool flipX,
    bool flipY,
  ) {
    return _rotateOffset(localDelta, _frameRotation(rotation, flipX, flipY));
  }
}

class _TransformHandle extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isCorner = handle.isCorner;
    final edgeLong = visualSize * 2.4;
    final edgeShort = visualSize * 0.9;

    final visualW = isCorner
        ? visualSize
        : (handle == TextTransformHandle.top ||
                  handle == TextTransformHandle.bottom
              ? edgeLong
              : edgeShort);
    final visualH = isCorner
        ? visualSize
        : (handle == TextTransformHandle.left ||
                  handle == TextTransformHandle.right
              ? edgeLong
              : edgeShort);

    return MouseRegion(
      cursor: handle.cursor,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: onPointerDown,
        child: SizedBox(
          width: hitSize,
          height: hitSize,
          child: Center(
            child: Container(
              width: visualW,
              height: visualH,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isCorner ? 1.5 : 2),
                border: Border.all(color: color, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact `W … H …` pill shown under a frame while it is being resized.
class _FrameSizeBadge extends StatelessWidget {
  const _FrameSizeBadge({required this.size, required this.color});

  final Size size;
  final Color color;

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
        color: const Color(0xE6000000),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          'W ${_format(size.width)}  H ${_format(size.height)}',
          maxLines: 1,
          softWrap: false,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            height: 1.1,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
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
      ..strokeWidth = strokeWidth;
    canvas.drawRect(Offset.zero & size, paint);
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
