import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../../core/utils/design_state_history.dart';
import '../../../../data/models/media_item.dart';
import '../../../../data/models/online_asset_models.dart';
import '../../../../data/repositories/online_asset_repository.dart';
import '../../utils/musami_asset_layer.dart';

/// Builds / adds an [OnlineAssetItem] to the editor.
///
/// Returns the created layer (for pick-only flows). Does not close sheets.
Future<Object?> applyOnlineAssetItem({
  required BuildContext context,
  required OnlineAssetItem item,
  required GlobalKey<ProImageEditorState>? editorKey,
  bool pickOnly = false,
  VoidCallback? onAssetAdded,
  OnlineAssetRepository? repository,
}) async {
  final editor = editorKey?.currentState;
  final repo = repository ?? OnlineAssetRepository();

  switch (item.applyKind) {
    case OnlineAssetApplyKind.emojiText:
      final emoji = item.emoji?.trim();
      if (emoji == null || emoji.isEmpty) return null;
      final layer = TextLayer(
        text: emoji,
        color: const Color(0xFF111111),
        textStyle: const TextStyle(fontSize: 64),
        meta: <String, dynamic>{
          'musamiLayerKind': 'online_asset_emoji',
          'onlineAssetProvider': item.provider.id,
        },
      );
      if (pickOnly) return layer;
      if (editor == null) return null;
      editor.addLayer(layer);
      onAssetAdded?.call();
      return layer;

    case OnlineAssetApplyKind.lottie:
      final url = item.lottieUrl?.trim();
      if (url == null || url.isEmpty) return null;
      final lottieSize = const Size(220, 220);
      final layer = WidgetLayer(
        width: lottieSize.width,
        scale: musamiInsertedImageScale(
          intrinsic: lottieSize,
          canvas: musamiEditorCanvasSize(editor),
        ),
        offset: Offset.zero,
        boxConstraints: kMusamiWidgetLayerBoxConstraints,
        exportConfigs: WidgetLayerExportConfigs(
          networkUrl: url,
          meta: <String, dynamic>{
            'musamiLayerKind': kMusamiLottieLayerKind,
            'fileUrl': url,
            'onlineAssetProvider': item.provider.id,
          },
        ),
        meta: <String, dynamic>{
          'musamiLayerKind': kMusamiLottieLayerKind,
          'fileUrl': url,
          'onlineAssetProvider': item.provider.id,
        },
        widget: SizedBox(
          width: 220,
          height: 220,
          child: Lottie.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
          ),
        ),
      );
      if (pickOnly) return layer;
      if (editor == null) return null;
      editor.addLayer(layer);
      onAssetAdded?.call();
      return layer;

    case OnlineAssetApplyKind.svg:
      final url = (item.svgUrl ?? item.imageUrl)?.trim();
      if (url == null || url.isEmpty) return null;
      final svgSize = const Size(160, 160);
      final layer = WidgetLayer(
        width: svgSize.width,
        scale: musamiInsertedImageScale(
          intrinsic: svgSize,
          canvas: musamiEditorCanvasSize(editor),
        ),
        offset: Offset.zero,
        boxConstraints: kMusamiWidgetLayerBoxConstraints,
        exportConfigs: WidgetLayerExportConfigs(
          networkUrl: url,
          meta: <String, dynamic>{
            'musamiLayerKind': kMusamiSvgLayerKind,
            'fileUrl': url,
            'onlineAssetProvider': item.provider.id,
          },
        ),
        meta: <String, dynamic>{
          'musamiLayerKind': kMusamiSvgLayerKind,
          'fileUrl': url,
          'onlineAssetProvider': item.provider.id,
          'musamiAspect': 1.0,
        },
        widget: SizedBox(
          width: 160,
          height: 160,
          child: SvgPicture.network(
            url,
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              Color(0xFF111111),
              BlendMode.srcIn,
            ),
            placeholderBuilder: (_) => const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      );
      if (pickOnly) return layer;
      if (editor == null) return null;
      editor.addLayer(layer);
      onAssetAdded?.call();
      return layer;

    case OnlineAssetApplyKind.image:
    case OnlineAssetApplyKind.paletteImage:
      final url = item.imageUrl?.trim();
      if (url == null || url.isEmpty) return null;
      final media = MediaItem(
        id: item.mediaId,
        name: item.title,
        fileUrl: url,
        width: (item.width != null && item.width! > 0) ? item.width : 800,
        height: (item.height != null && item.height! > 0) ? item.height : 800,
        tags: 'online_asset:${item.provider.id}',
      );
      final layer = await musamiBuildAssetWidgetLayer(
        context: context,
        item: media,
        layerKind: 'online_pic',
        editor: editor,
      );
      if (layer == null) return null;

      final downloadLoc = item.downloadLocation?.trim();
      if (downloadLoc != null &&
          downloadLoc.isNotEmpty &&
          item.provider == OnlineAssetProvider.unsplash) {
        unawaited(repo.trackUnsplashDownload(downloadLoc));
      }

      if (pickOnly) return layer;
      if (editor == null) return null;
      editor.addLayer(layer);
      onAssetAdded?.call();
      return layer;
  }
}
