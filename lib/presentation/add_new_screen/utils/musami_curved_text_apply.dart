import 'package:flutter/material.dart';
import 'package:pro_image_editor/core/models/layers/layer_interaction.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/utils/design_state_history.dart';
import '../widgets/musami_curved_text_layer.dart';
import 'musami_curved_text_meta.dart';
import 'musami_curved_text_painter.dart';

export 'musami_curved_text_meta.dart';

String musamiNewCurvedTextExportId() =>
    '$kMusamiCurvedTextIdPrefix${DateTime.now().microsecondsSinceEpoch}';

Widget musamiBuildCurvedTextWidget(
  MusamiCurvedTextParams params, {
  double stripStep = 1.0,
}) {
  final size = musamiCurvedTextLayoutSize(params);
  return MusamiCurvedTextLayer(
    params: params,
    stripStep: stripStep,
    width: size.width,
    height: size.height,
  );
}

WidgetLayer musamiBuildCurvedTextLayer({
  required MusamiCurvedTextParams params,
  required ProImageEditorState editor,
  Offset? offset,
  double? rotation,
  double? scale,
  String? keepId,
  Map<String, dynamic>? extraMeta,
  LayerInteraction? interaction,
  double stripStep = 1.0,
}) {
  final size = musamiCurvedTextLayoutSize(params);
  final meta = <String, dynamic>{
    ...params.toMeta(),
    'musamiAspect': size.height / size.width,
    'musamiImageAspect': size.height / size.width,
    if (extraMeta != null) ...extraMeta,
  };
  final exportId = keepId != null &&
          keepId.startsWith(kMusamiCurvedTextIdPrefix)
      ? keepId
      : musamiNewCurvedTextExportId();

  return WidgetLayer(
    id: keepId,
    width: size.width,
    offset: offset ?? Offset.zero,
    rotation: rotation ?? 0,
    scale: scale ??
        musamiInsertedImageScale(
          intrinsic: size,
          canvas: musamiEditorCanvasSize(editor),
        ),
    boxConstraints: kMusamiWidgetLayerBoxConstraints,
    interaction: interaction,
    exportConfigs: WidgetLayerExportConfigs(
      id: exportId,
      meta: meta,
    ),
    meta: meta,
    widget: musamiBuildCurvedTextWidget(params, stripStep: stripStep),
  );
}

/// Replaces [textLayer] with a curved [WidgetLayer] via [ProImageEditorState.addHistory].
WidgetLayer? musamiConvertTextLayerToCurved({
  required ProImageEditorState editor,
  required TextLayer textLayer,
  MusamiCurvedTextParams? paramsOverride,
}) {
  final params = paramsOverride ??
      MusamiCurvedTextParams.fromPlainText(
        text: textLayer.text,
        style: textLayer.textStyle,
        align: textLayer.align,
        fallbackColor: textLayer.color,
      );
  final curved = musamiBuildCurvedTextLayer(
    params: params,
    editor: editor,
    offset: textLayer.offset,
    rotation: textLayer.rotation,
    scale: textLayer.scale,
    interaction: textLayer.interaction,
    extraMeta: () {
      final raw = textLayer.meta;
      if (raw == null) return null;
      final copy = Map<String, dynamic>.from(raw);
      copy.removeWhere(
        (k, _) =>
            k == 'musamiLayerKind' ||
            k.startsWith('musamiCurved') ||
            k == kMusamiCurvedSourceStringMetaKey ||
            k == kMusamiCurvedArcAmountMetaKey ||
            k == kMusamiCurvedClockwiseMetaKey ||
            k == kMusamiCurvedRtlMetaKey,
      );
      return copy;
    }(),
  );

  final layers = List<Layer>.from(editor.activeLayers);
  final idx = layers.indexWhere((l) => l.id == textLayer.id);
  if (idx < 0) {
    editor.addLayer(curved);
  } else {
    // Preserve z-order: swap in place then commit history.
    layers[idx] = curved;
    editor.addHistory(layers: layers);
  }
  return curved;
}

/// Updates curve params / text on an existing curved layer (undo via history).
WidgetLayer? musamiUpdateCurvedTextLayer({
  required ProImageEditorState editor,
  required WidgetLayer layer,
  required MusamiCurvedTextParams params,
  double stripStep = 1.0,
  bool commitHistory = true,
}) {
  if (!musamiMetaIsCurvedText(layer.meta)) return null;
  final exportId = layer.exportConfigs.id ?? musamiNewCurvedTextExportId();
  final updated = musamiBuildCurvedTextLayer(
    params: params,
    editor: editor,
    offset: layer.offset,
    rotation: layer.rotation,
    scale: layer.scale,
    keepId: layer.id,
    interaction: layer.interaction,
    stripStep: stripStep,
    extraMeta: {
      ...?layer.meta,
      ...params.toMeta(),
    },
  );
  // Keep stable export id across edits.
  updated.exportConfigs = WidgetLayerExportConfigs(
    id: exportId.startsWith(kMusamiCurvedTextIdPrefix)
        ? exportId
        : musamiNewCurvedTextExportId(),
    meta: updated.meta,
  );

  final layers = List<Layer>.from(editor.activeLayers);
  final idx = layers.indexWhere((l) => l.id == layer.id);
  if (idx < 0) return null;
  layers[idx] = updated;
  if (commitHistory) {
    editor.addHistory(layers: layers);
  } else {
    editor.replaceLayer(index: idx, layer: updated);
  }
  return updated;
}

/// Converts curved [WidgetLayer] back to a straight [TextLayer].
TextLayer? musamiRemoveCurveToTextLayer({
  required ProImageEditorState editor,
  required WidgetLayer layer,
}) {
  if (!musamiMetaIsCurvedText(layer.meta)) return null;
  final params = MusamiCurvedTextParams.fromMeta(layer.meta);
  final text = TextLayer(
    text: params.sourceString.isEmpty ? 'Text' : params.sourceString,
    textStyle: params.textStyle,
    color: params.color,
    align: params.textAlign,
    offset: layer.offset,
    rotation: layer.rotation,
    scale: layer.scale,
    interaction: layer.interaction,
    meta: () {
      final copy = Map<String, dynamic>.from(layer.meta ?? const {});
      for (final k in [
        'musamiLayerKind',
        kMusamiCurvedTextFlagMetaKey,
        kMusamiCurvedSourceStringMetaKey,
        kMusamiCurvedArcAmountMetaKey,
        kMusamiCurvedClockwiseMetaKey,
        kMusamiCurvedRtlMetaKey,
        kMusamiCurvedTextAlignMetaKey,
        kMusamiCurvedFontFamilyMetaKey,
        kMusamiCurvedFontSizeMetaKey,
        kMusamiCurvedFontWeightMetaKey,
        kMusamiCurvedFontStyleMetaKey,
        kMusamiCurvedColorMetaKey,
        kMusamiCurvedLetterSpacingMetaKey,
        'musamiAspect',
        'musamiImageAspect',
      ]) {
        copy.remove(k);
      }
      return copy.isEmpty ? null : copy;
    }(),
  );

  final layers = List<Layer>.from(editor.activeLayers);
  final idx = layers.indexWhere((l) => l.id == layer.id);
  if (idx < 0) return null;
  layers[idx] = text;
  editor.addHistory(layers: layers);
  return text;
}
