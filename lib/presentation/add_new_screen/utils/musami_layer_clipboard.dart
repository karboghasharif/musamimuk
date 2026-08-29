import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

/// Nudge applied to a pasted / duplicated layer so it is visibly distinct from
/// the layer it came from.
const Offset kMusamiLayerCopyNudge = Offset(20, 20);

/// Nudge used by the toolbar duplicate action (kept at the historical value so
/// duplicating from the toolbar behaves exactly as before).
const Offset kMusamiLayerDuplicateNudge = Offset(12, 12);

/// The editor's single layer clipboard.
///
/// Deliberately a singleton: copy in one screen, paste in another. Every read
/// and write goes through [musamiCloneLayer], so the clipboard never shares
/// mutable state (meta maps, ids, keys) with a layer on the canvas.
class MusamiLayerClipboard extends ChangeNotifier {
  MusamiLayerClipboard._();

  static final MusamiLayerClipboard instance = MusamiLayerClipboard._();

  Layer? _stored;

  bool get hasContent => _stored != null;

  /// Stores a detached copy of [layer]. Later edits to [layer] do not leak in.
  bool copy(Layer layer) {
    final clone = musamiCloneLayer(layer);
    if (clone == null) return false;
    _stored = clone;
    notifyListeners();
    return true;
  }

  /// Returns a fresh copy of the stored layer, or `null` when empty.
  ///
  /// Each call clones again, so pasting twice yields two independent layers.
  Layer? read({Offset nudge = kMusamiLayerCopyNudge}) {
    final source = _stored;
    if (source == null) return null;
    return musamiCloneLayer(source, nudge: nudge);
  }

  void clear() {
    if (_stored == null) return;
    _stored = null;
    notifyListeners();
  }
}

/// Deep-copies a layer for duplicate / copy / paste.
///
/// The copy gets a new `id` and a new `key` (both are generated when omitted),
/// its own `meta` map, and an offset shifted by [nudge]. Returns `null` for
/// layer types the editor does not create.
Layer? musamiCloneLayer(Layer layer, {Offset nudge = Offset.zero}) {
  if (layer is TextLayer) return _cloneTextLayer(layer, nudge);
  if (layer is WidgetLayer) return _cloneWidgetLayer(layer, nudge);
  return null;
}

Map<String, dynamic>? _cloneMeta(Map<String, dynamic>? meta) {
  return meta == null ? null : Map<String, dynamic>.from(meta);
}

TextLayer _cloneTextLayer(TextLayer layer, Offset nudge) {
  return TextLayer(
    text: layer.text,
    customSecondaryColor: layer.customSecondaryColor,
    hit: layer.hit,
    textStyle: layer.textStyle,
    colorMode: layer.colorMode,
    color: layer.color,
    background: layer.background,
    align: layer.align,
    fontScale: layer.fontScale,
    maxTextWidth: layer.maxTextWidth,
    offset: layer.offset + nudge,
    rotation: layer.rotation,
    scale: layer.scale,
    flipX: layer.flipX,
    flipY: layer.flipY,
    interaction: layer.interaction,
    meta: _cloneMeta(layer.meta),
    boxConstraints: layer.boxConstraints,
  );
}

WidgetLayer _cloneWidgetLayer(WidgetLayer layer, Offset nudge) {
  return WidgetLayer(
    // The widget tree is immutable and safe to share; the mutable state that
    // matters (id, key, meta, transform) is all rebuilt here.
    widget: layer.widget,
    width: layer.width,
    offset: layer.offset + nudge,
    rotation: layer.rotation,
    scale: layer.scale,
    flipX: layer.flipX,
    flipY: layer.flipY,
    interaction: layer.interaction,
    exportConfigs: layer.exportConfigs,
    meta: _cloneMeta(layer.meta),
    boxConstraints: layer.boxConstraints,
    groupId: layer.groupId,
    startTime: layer.startTime,
    endTime: layer.endTime,
    enterDuration: layer.enterDuration,
    exitDuration: layer.exitDuration,
    enterCurve: layer.enterCurve,
    exitCurve: layer.exitCurve,
    transitionBuilder: layer.transitionBuilder,
  );
}

/// Adds [layer] to the canvas and selects it, as one history entry.
///
/// Returns the added layer so the caller can sync its own selection state.
Layer musamiAddAndSelectLayer(ProImageEditorState editor, Layer layer) {
  editor.addLayer(layer);
  editor.layerInteractionManager.selectedLayerId = layer.id;
  editor.setState(() {});
  return layer;
}
