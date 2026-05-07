import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/app_toast.dart';

/// Rough display size for canvas alignment (axis-aligned; rotation ignored).
Size musamiEstimateLayerPaintSize(Layer layer, ProImageEditorState editor) {
  final sticker = editor.configs.stickerEditor;
  if (layer is WidgetLayer) {
    final w = (layer.width ?? sticker.initWidth) * layer.scale;
    final aspect = (layer.meta?['musamiAspect'] as num?)?.toDouble();
    final h = (aspect != null && aspect > 0) ? w / aspect : w;
    return Size(w, h);
  }
  if (layer is TextLayer) {
    final fs =
        (layer.textStyle?.fontSize ?? 24.0) * layer.fontScale * layer.scale;
    final mw = (layer.maxTextWidth ?? 240.0) * layer.scale;
    return Size(mw.clamp(40.0, 800.0), (fs * 2 + 12).clamp(32.0, 600.0));
  }
  if (layer is EmojiLayer) {
    final s = 56.0 * layer.scale;
    return Size(s, s);
  }
  return Size(80, 80);
}

/// [xT] / [yT]: -1 = start (left/top), 0 = center, 1 = end (right/bottom).
/// `null` keeps the current anchor on that axis.
Offset musamiAnchorAfterAlignAxes({
  required Offset currentAnchorInBody,
  required Size body,
  required Size paintSize,
  required int? xT,
  required int? yT,
  double edge = 8,
}) {
  final w = paintSize.width;
  final h = paintSize.height;
  double x = currentAnchorInBody.dx;
  double y = currentAnchorInBody.dy;
  if (xT != null) {
    if (xT < 0) {
      x = edge + w / 2;
    } else if (xT > 0) {
      x = body.width - edge - w / 2;
    } else {
      x = body.width / 2;
    }
  }
  if (yT != null) {
    if (yT < 0) {
      y = edge + h / 2;
    } else if (yT > 0) {
      y = body.height - edge - h / 2;
    } else {
      y = body.height / 2;
    }
  }
  return Offset(x, y);
}

/// Offset stored on [Layer] is relative to body center (see pro_image_editor
/// [LayerWidget] `offsetX = layer.offset.dx + halfBody.width`).
Offset musamiLayerOffsetForAnchor(Offset anchorInBody, Size body) {
  return Offset(
    anchorInBody.dx - body.width / 2,
    anchorInBody.dy - body.height / 2,
  );
}

void _commitLayer(
  ProImageEditorState editor,
  Layer updated,
) {
  final idx = editor.activeLayers.indexWhere((l) => l.id == updated.id);
  if (idx < 0) return;
  editor.replaceLayer(index: idx, layer: updated);
  editor.layerInteractionManager.selectedLayerId = updated.id;
}

void _reorderLayerTo(
  ProImageEditorState editor,
  String layerId,
  int targetIndex,
) {
  final list = List<Layer>.from(editor.activeLayers);
  final i = list.indexWhere((l) => l.id == layerId);
  if (i < 0) return;
  final item = list.removeAt(i);
  final t = targetIndex.clamp(0, list.length);
  list.insert(t, item);
  editor.addHistory(layers: list);
  editor.layerInteractionManager.selectedLayerId = layerId;
}

/// Align / arrange popup matching reference: grid + z-order + flip.
Future<void> showEditorAlignArrangeSheet({
  required BuildContext context,
  required ProImageEditorState editor,
  required Layer layer,
}) {
  final primary = Theme.of(context).colorScheme.primary;
  final body = editor.sizesManager.bodySize;
  if (body.width <= 0 || body.height <= 0) {
    showAppToast('msg_editor_align_no_canvas'.tr);
    return Future.value();
  }

  return showAppModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);

      void alignAxes({int? xT, int? yT}) {
        final cur = editor.activeLayers.cast<Layer?>().firstWhere(
              (l) => l?.id == layer.id,
              orElse: () => null,
            );
        if (cur == null) return;
        final psz = musamiEstimateLayerPaintSize(cur, editor);
        final currentAnchor = Offset(
          cur.offset.dx + body.width / 2,
          cur.offset.dy + body.height / 2,
        );
        final anchor = musamiAnchorAfterAlignAxes(
          currentAnchorInBody: currentAnchor,
          body: body,
          paintSize: psz,
          xT: xT,
          yT: yT,
        );
        final off = musamiLayerOffsetForAnchor(anchor, body);
        final next = _copyLayerWithOffset(cur, off);
        _commitLayer(editor, next);
        Navigator.pop(ctx);
      }

      void flipH() {
        final cur = editor.activeLayers.cast<Layer?>().firstWhere(
              (l) => l?.id == layer.id,
              orElse: () => null,
            );
        if (cur == null) return;
        final next = _copyLayerWithFlip(cur, flipX: !cur.flipX);
        _commitLayer(editor, next);
        Navigator.pop(ctx);
      }

      void flipV() {
        final cur = editor.activeLayers.cast<Layer?>().firstWhere(
              (l) => l?.id == layer.id,
              orElse: () => null,
            );
        if (cur == null) return;
        final next = _copyLayerWithFlip(cur, flipY: !cur.flipY);
        _commitLayer(editor, next);
        Navigator.pop(ctx);
      }

      void zBringToFront() {
        final list = editor.activeLayers;
        _reorderLayerTo(editor, layer.id, list.length - 1);
        Navigator.pop(ctx);
      }

      void zSendToBack() {
        _reorderLayerTo(editor, layer.id, 0);
        Navigator.pop(ctx);
      }

      void zForward() {
        final list = List<Layer>.from(editor.activeLayers);
        final i = list.indexWhere((l) => l.id == layer.id);
        if (i < 0 || i >= list.length - 1) return;
        final item = list.removeAt(i);
        list.insert(i + 1, item);
        editor.addHistory(layers: list);
        editor.layerInteractionManager.selectedLayerId = layer.id;
        Navigator.pop(ctx);
      }

      void zBackward() {
        final list = List<Layer>.from(editor.activeLayers);
        final i = list.indexWhere((l) => l.id == layer.id);
        if (i <= 0) return;
        final item = list.removeAt(i);
        list.insert(i - 1, item);
        editor.addHistory(layers: list);
        editor.layerInteractionManager.selectedLayerId = layer.id;
        Navigator.pop(ctx);
      }

      Widget cell({
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDs.radiusSm.adaptSize),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppDs.space3.v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: const Color(0xFF424242), size: 26.adaptSize),
                SizedBox(height: AppDs.space1.v),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF424242),
                    fontSize: 10.fSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppDs.space4.h),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDs.radiusLg.adaptSize),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  color: primary,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDs.space3.h,
                    vertical: AppDs.space3.v,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.open_with_rounded,
                        color: Colors.white,
                        size: 22.adaptSize,
                      ),
                      Expanded(
                        child: Text(
                          'lbl_editor_align_arrange'.tr,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(AppDs.space3.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'lbl_editor_align_position'.tr,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                      SizedBox(height: AppDs.space2.v),
                      Row(
                        children: [
                          Expanded(
                            child: cell(
                              icon: Icons.format_align_left,
                              label: 'lbl_editor_align_left'.tr,
                              onTap: () => alignAxes(xT: -1, yT: 0),
                            ),
                          ),
                          Expanded(
                            child: cell(
                              icon: Icons.format_align_center,
                              label: 'lbl_editor_align_center_h'.tr,
                              onTap: () => alignAxes(xT: 0, yT: 0),
                            ),
                          ),
                          Expanded(
                            child: cell(
                              icon: Icons.format_align_right,
                              label: 'lbl_editor_align_right'.tr,
                              onTap: () => alignAxes(xT: 1, yT: 0),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: cell(
                              icon: Icons.vertical_align_top,
                              label: 'lbl_editor_align_top'.tr,
                              onTap: () => alignAxes(xT: 0, yT: -1),
                            ),
                          ),
                          Expanded(
                            child: cell(
                              icon: Icons.vertical_align_center,
                              label: 'lbl_editor_align_middle'.tr,
                              onTap: () => alignAxes(xT: 0, yT: 0),
                            ),
                          ),
                          Expanded(
                            child: cell(
                              icon: Icons.vertical_align_bottom,
                              label: 'lbl_editor_align_bottom'.tr,
                              onTap: () => alignAxes(xT: 0, yT: 1),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppDs.space3.v),
                      Text(
                        'lbl_editor_align_order'.tr,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                      SizedBox(height: AppDs.space2.v),
                      Row(
                        children: [
                          Expanded(
                            child: cell(
                              icon: Icons.flip_to_front_outlined,
                              label: 'lbl_editor_order_front'.tr,
                              onTap: zBringToFront,
                            ),
                          ),
                          Expanded(
                            child: cell(
                              icon: Icons.arrow_upward,
                              label: 'lbl_editor_order_forward'.tr,
                              onTap: zForward,
                            ),
                          ),
                          Expanded(
                            child: cell(
                              icon: Icons.arrow_downward,
                              label: 'lbl_editor_order_backward'.tr,
                              onTap: zBackward,
                            ),
                          ),
                          Expanded(
                            child: cell(
                              icon: Icons.flip_to_back_outlined,
                              label: 'lbl_editor_order_back'.tr,
                              onTap: zSendToBack,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppDs.space3.v),
                      Text(
                        'lbl_editor_align_flip'.tr,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                      SizedBox(height: AppDs.space2.v),
                      Row(
                        children: [
                          Expanded(
                            child: cell(
                              icon: Icons.flip,
                              label: 'lbl_editor_flip_h'.tr,
                              onTap: flipH,
                            ),
                          ),
                          Expanded(
                            child: cell(
                              icon: Icons.flip_camera_android_outlined,
                              label: 'lbl_editor_flip_v'.tr,
                              onTap: flipV,
                            ),
                          ),
                        ],
                      ),
                      if (layer is TextLayer) ...[
                        SizedBox(height: AppDs.space3.v),
                        Text(
                          'lbl_editor_text_align'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                        SizedBox(height: AppDs.space2.v),
                        Row(
                          children: [
                            Expanded(
                              child: cell(
                                icon: Icons.format_align_left,
                                label: 'lbl_editor_para_left'.tr,
                                onTap: () {
                                  final cur = editor.activeLayers
                                      .whereType<TextLayer>()
                                      .firstWhere((l) => l.id == layer.id);
                                  _commitLayer(
                                    editor,
                                    cur.copyWith(align: TextAlign.left),
                                  );
                                  Navigator.pop(ctx);
                                },
                              ),
                            ),
                            Expanded(
                              child: cell(
                                icon: Icons.format_align_center,
                                label: 'lbl_editor_para_center'.tr,
                                onTap: () {
                                  final cur = editor.activeLayers
                                      .whereType<TextLayer>()
                                      .firstWhere((l) => l.id == layer.id);
                                  _commitLayer(
                                    editor,
                                    cur.copyWith(align: TextAlign.center),
                                  );
                                  Navigator.pop(ctx);
                                },
                              ),
                            ),
                            Expanded(
                              child: cell(
                                icon: Icons.format_align_right,
                                label: 'lbl_editor_para_right'.tr,
                                onTap: () {
                                  final cur = editor.activeLayers
                                      .whereType<TextLayer>()
                                      .firstWhere((l) => l.id == layer.id);
                                  _commitLayer(
                                    editor,
                                    cur.copyWith(align: TextAlign.right),
                                  );
                                  Navigator.pop(ctx);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Layer _copyLayerWithOffset(Layer layer, Offset offset) {
  if (layer is WidgetLayer) {
    return layer.copyWith(offset: offset);
  }
  if (layer is TextLayer) {
    return layer.copyWith(offset: offset);
  }
  if (layer is EmojiLayer) {
    return layer.copyWith(offset: offset);
  }
  if (layer is PaintLayer) {
    return layer.copyWith(offset: offset);
  }
  return layer;
}

Layer _copyLayerWithFlip(Layer layer, {bool? flipX, bool? flipY}) {
  if (layer is WidgetLayer) {
    return layer.copyWith(flipX: flipX ?? layer.flipX, flipY: flipY ?? layer.flipY);
  }
  if (layer is TextLayer) {
    return layer.copyWith(flipX: flipX ?? layer.flipX, flipY: flipY ?? layer.flipY);
  }
  if (layer is EmojiLayer) {
    return layer.copyWith(flipX: flipX ?? layer.flipX, flipY: flipY ?? layer.flipY);
  }
  if (layer is PaintLayer) {
    return layer.copyWith(flipX: flipX ?? layer.flipX, flipY: flipY ?? layer.flipY);
  }
  return layer;
}
