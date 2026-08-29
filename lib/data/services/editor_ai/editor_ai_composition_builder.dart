import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pro_image_editor/core/models/layers/layer_interaction.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/utils/design_state_history.dart';
import '../../models/editor_ai_api_models.dart';
import 'editor_ai_composition.dart';

class EditorAiCompositionBuilder {
  const EditorAiCompositionBuilder._();

  static List<Layer> buildLayers({
    required EditorAiComposition composition,
    required Size canvasSize,
    required Map<String, Uint8List> imageAssets,
    required Map<String, GeneratedAiAsset> generatedAssets,
    required double initialTextFontSize,
  }) {
    if (canvasSize.isEmpty || !canvasSize.width.isFinite) {
      throw const FormatException('Canvas size is not available');
    }

    return composition.elements
        .map((element) {
          return switch (element.type) {
            EditorAiCompositionElementType.text => _buildText(
              element,
              canvasSize,
              initialTextFontSize,
            ),
            EditorAiCompositionElementType.image => _buildImage(
              element,
              canvasSize,
              imageAssets,
              generatedAssets,
            ),
            EditorAiCompositionElementType.icon => _buildIcon(
              element,
              canvasSize,
            ),
            EditorAiCompositionElementType.shape => _buildShape(
              element,
              canvasSize,
            ),
          };
        })
        .toList(growable: false);
  }

  static TextLayer _buildText(
    EditorAiCompositionElement element,
    Size canvas,
    double initialTextFontSize,
  ) {
    final width = element.width * canvas.width;
    final height = element.height * canvas.height;
    final fontSize = element.fontSize! * canvas.height;
    final color = Color(element.color!);
    final background = Color(element.backgroundColor!);

    final layer = TextLayer(
      text: element.text!,
      offset: _offset(element, canvas),
      colorMode: background.a == 0
          ? LayerBackgroundMode.onlyColor
          : LayerBackgroundMode.backgroundAndColor,
      color: color,
      background: background,
      align: switch (element.align) {
        'center' => TextAlign.center,
        'right' => TextAlign.right,
        _ => TextAlign.left,
      },
      maxTextWidth: width,
      fontScale: fontSize / initialTextFontSize,
      textStyle: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: _fontWeight(element.fontWeight!),
        height: height / fontSize < 1 ? 1 : 1.15,
      ),
      interaction: LayerInteraction(),
      meta: <String, dynamic>{
        'musamiLayerKind': 'ai-text',
        'aiGenerated': true,
      },
    );
    return layer;
  }

  static WidgetLayer _buildImage(
    EditorAiCompositionElement element,
    Size canvas,
    Map<String, Uint8List> imageAssets,
    Map<String, GeneratedAiAsset> generatedAssets,
  ) {
    final bytes = imageAssets[element.assetId];
    if (bytes == null || bytes.isEmpty) {
      throw FormatException('Missing image asset: ${element.assetId}');
    }

    final requestedWidth = element.width * canvas.width;
    final requestedHeight = element.height * canvas.height;
    final diameter = requestedWidth < requestedHeight
        ? requestedWidth
        : requestedHeight;
    final width = element.clip == EditorAiCompositionClip.circle
        ? diameter
        : requestedWidth;
    final height = element.clip == EditorAiCompositionClip.circle
        ? diameter
        : requestedHeight;
    Widget image = Image.memory(
      bytes,
      width: width,
      height: height,
      fit: BoxFit.cover,
      gaplessPlayback: true,
    );
    if (element.clip == EditorAiCompositionClip.circle) {
      image = ClipOval(child: image);
    } else {
      image = ClipRect(child: image);
    }

    final generatedAsset = generatedAssets[element.assetId];
    final assetUrl = generatedAsset?.url?.trim();
    final exportMeta = <String, dynamic>{
      'musamiLayerKind': 'ai-image',
      'aiGenerated': true,
      if (generatedAsset != null) 'aiAssetId': generatedAsset.id,
      if (assetUrl != null && assetUrl.isNotEmpty) 'url': assetUrl,
    };
    final layer = WidgetLayer(
      width: width,
      scale: 1,
      offset: _offset(element, canvas),
      interaction: LayerInteraction(enableEdit: false),
      boxConstraints: kMusamiWidgetLayerBoxConstraints,
      exportConfigs: generatedAsset == null
          ? const WidgetLayerExportConfigs()
          : WidgetLayerExportConfigs(
              id: 'musami-ai-asset:${generatedAsset.id}',
              meta: exportMeta,
            ),
      meta: <String, dynamic>{
        ...exportMeta,
        'musamiAspect': height / width,
        'aiCompositionAssetId': element.assetId,
        'aiClip': element.clip.name,
      },
      // No fileUrl/id: state export records this individual widget's pixels,
      // keeping it as a separate image layer when the design is reopened.
      widget: SizedBox(width: width, height: height, child: image),
    );
    return layer;
  }

  static WidgetLayer _buildIcon(
    EditorAiCompositionElement element,
    Size canvas,
  ) {
    final requestedWidth = element.width * canvas.width;
    final requestedHeight = element.height * canvas.height;
    final diameter = requestedWidth < requestedHeight
        ? requestedWidth
        : requestedHeight;
    final width = element.shape == EditorAiCompositionShape.circle
        ? diameter
        : requestedWidth;
    final height = element.shape == EditorAiCompositionShape.circle
        ? diameter
        : requestedHeight;
    final color = Color(element.color!);
    final background = Color(element.backgroundColor!);

    return WidgetLayer(
      width: width,
      scale: 1,
      offset: _offset(element, canvas),
      interaction: LayerInteraction(enableEdit: false),
      boxConstraints: kMusamiWidgetLayerBoxConstraints,
      exportConfigs: WidgetLayerExportConfigs(
        id: 'musami-ai-icon:${element.icon}',
        meta: <String, dynamic>{
          'icon': element.icon,
          'color': element.color,
          'backgroundColor': element.backgroundColor,
        },
      ),
      meta: <String, dynamic>{
        'musamiLayerKind': 'ai-icon',
        'musamiAspect': height / width,
        'aiGenerated': true,
        'icon': element.icon,
      },
      widget: buildEditorAiIconWidget(
        name: element.icon!,
        color: color,
        backgroundColor: background,
        width: width,
        height: height,
      ),
    );
  }

  static PaintLayer _buildShape(
    EditorAiCompositionElement element,
    Size canvas,
  ) {
    final width = element.width * canvas.width;
    final height = element.height * canvas.height;
    final mode = switch (element.shape!) {
      EditorAiCompositionShape.rectangle => PaintMode.rect,
      EditorAiCompositionShape.circle => PaintMode.circle,
      EditorAiCompositionShape.line => PaintMode.line,
    };
    final strokeWidth = element.strokeWidth! * canvas.shortestSide;
    final strokeInset = (strokeWidth / 2)
        .clamp(0.0, (width < height ? width : height) / 2)
        .toDouble();
    final offsets = element.shape == EditorAiCompositionShape.line
        ? <Offset?>[
            Offset(strokeInset, height / 2),
            Offset(width - strokeInset, height / 2),
          ]
        : <Offset?>[
            Offset(strokeInset, strokeInset),
            Offset(width - strokeInset, height - strokeInset),
          ];

    return PaintLayer(
      item: PaintedModel(
        mode: mode,
        offsets: offsets,
        erasedOffsets: const [],
        color: Color(element.color!),
        strokeWidth: strokeWidth,
        opacity: 1,
        fill: element.fill,
      ),
      rawSize: Size(width, height),
      opacity: 1,
      offset: _offset(element, canvas),
      interaction: LayerInteraction(enableEdit: false),
      meta: <String, dynamic>{
        'musamiLayerKind': 'ai-shape',
        'aiGenerated': true,
      },
    );
  }

  static Offset _offset(EditorAiCompositionElement element, Size canvas) {
    return Offset(
      (element.x - 0.5) * canvas.width,
      (element.y - 0.5) * canvas.height,
    );
  }

  static FontWeight _fontWeight(int weight) {
    return FontWeight.values[((weight.clamp(100, 900) - 100) ~/ 100).clamp(
      0,
      8,
    )];
  }
}
