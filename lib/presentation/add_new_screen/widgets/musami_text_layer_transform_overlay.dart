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
      TextTransformHandle.top || TextTransformHandle.bottom =>
        SystemMouseCursors.resizeUpDown,
      TextTransformHandle.left || TextTransformHandle.right =>
        SystemMouseCursors.resizeLeftRight,
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
    GestureBinding.instance.pointerRouter.addRoute(event.pointer, _pointerRoute!);
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
      startMaxTextWidth: layerAfterHistory.maxTextWidth ??
          (visualSize.width / layerAfterHistory.scale).clamp(40, 4000),
      startFontSize: layerAfterHistory.textStyle?.fontSize ??
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

    final newSize = Size(
      startW * applied,
      startH * applied,
    );
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
          (session.startMaxTextWidth + grow.dx / session.startScale)
              .clamp(24.0, 4000.0);

      final newVisualW = layer.maxTextWidth! * session.startScale;
      _repositionKeepingAnchor(
        session,
        layer,
        Size(newVisualW, session.startVisualSize.height),
      );
      return;
    }

    // Top / bottom — adjust base font size (height axis).
    final newFontSize =
        (session.startFontSize + grow.dy / session.startScale)
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
    return Offset(
      dx * cos - dy * sin,
      dx * sin + dy * cos,
    );
  }

  void _setFontSize(TextLayer layer, double size) {
    final style = layer.textStyle ?? const TextStyle();
    layer.textStyle = style.copyWith(fontSize: size);
  }
}

typedef MusamiWidgetLayerGeometryCallback = void Function(
  WidgetLayer layer, {
  required double width,
  required double aspect,
  required double scale,
  required Offset offset,
});

class _WidgetResizeSession {
  _WidgetResizeSession({
    required this.handle,
    required this.layerId,
    required this.startWidth,
    required this.startScale,
    required this.startAspect,
    required this.startOffset,
    required this.startVisualSize,
    required this.startPointerGlobal,
    required this.startRotation,
    required this.startFlipX,
    required this.startFlipY,
  });

  final TextTransformHandle handle;
  final String layerId;
  final double startWidth;
  final double startScale;
  final double startAspect;
  final Offset startOffset;
  final Size startVisualSize;
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

  WidgetLayer get _layer => widget.layer;

  ProImageEditorState? get _editor => widget.editorKey.currentState;

  double get _initWidth =>
      _editor?.configs.stickerEditor.initWidth ?? 100.0;

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
    GestureBinding.instance.pointerRouter.addRoute(event.pointer, _pointerRoute!);
    GestureManager.instance.stopPropagation();
    _setEditorDragBlock(true);

    editor.layerInteractionManager
      ..enabledHitDetection = false
      ..activeInteractionLayer = liveLayer
      ..layerWasTransformed = true;

    final visualSize = widget.info.childSize;
    final startWidth = liveLayer.width ?? _initWidth;
    final startAspect = (liveLayer.meta?['musamiAspect'] as num?)?.toDouble() ??
        (visualSize.width > 0
            ? visualSize.height / visualSize.width
            : 1.0);

    editor.addHistory(blockCaptureScreenshot: true);

    final layerAfterHistory = _resolveLiveLayer();
    if (layerAfterHistory == null) return;

    editor.layerInteractionManager.selectedLayerId = layerAfterHistory.id;

    _session = _WidgetResizeSession(
      handle: handle,
      layerId: layerAfterHistory.id,
      startWidth: startWidth,
      startScale: layerAfterHistory.scale,
      startAspect: startAspect,
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

  /// Coalesces editor rebuilds per frame; avoids layer.key setState (drops pointer).
  void _notifyLayerChanged(WidgetLayer layer) {
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

  void _applyCornerResize(
    _WidgetResizeSession session,
    WidgetLayer layer,
    Offset deltaLocal,
  ) {
    const minScale = 0.05;
    const maxScale = 8.0;

    final grow = _projectOntoHandle(session.handle, deltaLocal);
    final startW = session.startVisualSize.width;
    final startH = session.startVisualSize.height;

    final sx = startW > 0 ? (startW + grow.dx) / startW : 1.0;
    final sy = startH > 0 ? (startH + grow.dy) / startH : 1.0;
    final factor = math.max(sx, sy).clamp(0.08, 12.0);

    final newScale =
        (session.startScale * factor).clamp(minScale, maxScale);
    final applied = newScale / session.startScale;

    final newSize = Size(
      startW * applied,
      startH * applied,
    );
    final newOffset = _offsetKeepingAnchor(session, newSize);

    widget.onApplyGeometry(
      layer,
      width: session.startWidth,
      aspect: session.startAspect,
      scale: newScale,
      offset: newOffset,
    );
  }

  void _applyEdgeResize(
    _WidgetResizeSession session,
    WidgetLayer layer,
    Offset deltaLocal,
  ) {
    final handle = session.handle;
    final grow = _projectOntoHandle(handle, deltaLocal);

    if (handle == TextTransformHandle.left ||
        handle == TextTransformHandle.right) {
      final newVisualW =
          (session.startVisualSize.width + grow.dx).clamp(24.0, 4000.0);
      final newWidth =
          (newVisualW / session.startScale).clamp(8.0, 4000.0);
      final newOffset = _offsetKeepingAnchor(
        session,
        Size(newVisualW, session.startVisualSize.height),
      );

      widget.onApplyGeometry(
        layer,
        width: newWidth,
        aspect: session.startAspect,
        scale: session.startScale,
        offset: newOffset,
      );
      return;
    }

    final newVisualH =
        (session.startVisualSize.height + grow.dy).clamp(24.0, 4000.0);
    final startVisualW = session.startVisualSize.width;
    final newAspect = startVisualW > 0
        ? (newVisualH / startVisualW).clamp(0.05, 20.0)
        : session.startAspect;
    final newOffset = _offsetKeepingAnchor(
      session,
      Size(startVisualW, newVisualH),
    );

    widget.onApplyGeometry(
      layer,
      width: session.startWidth,
      aspect: newAspect,
      scale: session.startScale,
      offset: newOffset,
    );
  }

  Offset _projectOntoHandle(TextTransformHandle handle, Offset deltaLocal) {
    final sign = handle.handleSign;
    return Offset(
      sign.dx == 0 ? 0 : deltaLocal.dx * sign.dx,
      sign.dy == 0 ? 0 : deltaLocal.dy * sign.dy,
    );
  }

  Offset _offsetKeepingAnchor(
    _WidgetResizeSession session,
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
      session.startRotation,
      session.startFlipX,
      session.startFlipY,
    );
    return session.startOffset + shift;
  }

  Offset _globalDeltaToLayerLocal(Offset deltaGlobal, WidgetLayer layer) {
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
    return Offset(
      dx * cos - dy * sin,
      dx * sin + dy * cos,
    );
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
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
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
