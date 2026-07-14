import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/app_export.dart';
import '../../../data/models/asset_meta.dart';
import '../../../data/models/design_compose_plan.dart';
import '../../../data/models/media_item.dart';
import '../../../data/repositories/asset_repository.dart';
import '../bloc/add_new_bloc.dart';
import '../utils/musami_asset_layer.dart';

sealed class ComposeExecuteResult {}

class ComposeExecuteSuccess extends ComposeExecuteResult {
  ComposeExecuteSuccess({required this.message, this.assetName});

  final String message;
  final String? assetName;
}

class ComposeExecuteFailure extends ComposeExecuteResult {
  ComposeExecuteFailure(this.message);
  final String message;
}

/// Runs [DesignComposePlan] actions against the live editor.
class DesignComposeExecutor {
  DesignComposeExecutor({AssetRepository? assetRepo})
      : _assetRepo = assetRepo ?? AssetRepository();

  final AssetRepository _assetRepo;
  List<String>? _cachedValidTypes;

  static const double _canvasMargin = 24;

  /// Semantic aliases mapped to API type search order (filtered against meta).
  static const Map<String, List<String>> _semanticTypeOrder = {
    'icon': ['png', 'shape', 'logo', 'online_pic'],
    'sticker': ['png', 'shape', 'logo', 'online_pic'],
    'frame': ['shape', 'png', 'logo'],
    'logo': ['logo', 'png'],
    'shape': ['shape', 'png'],
    'png': ['png', 'shape', 'logo', 'online_pic'],
    'online_pic': ['online_pic', 'png'],
  };

  Future<ComposeExecuteResult> execute({
    required BuildContext context,
    required ProImageEditorState editor,
    required DesignComposePlan plan,
  }) async {
    switch (plan.action) {
      case DesignComposeAction.addAsset:
        return executeAddAsset(
          context: context,
          editor: editor,
          assetType: plan.assetType,
          searchQuery: plan.searchQuery,
          position: plan.position,
        );
      case DesignComposeAction.addText:
      case DesignComposeAction.setBackground:
      case DesignComposeAction.composeDesign:
        return ComposeExecuteFailure('msg_ai_compose_phase2'.tr);
    }
  }

  Future<List<String>> _loadValidAssetTypes() async {
    if (_cachedValidTypes != null) return _cachedValidTypes!;

    final result = await _assetRepo.fetchMeta();
    if (result is AssetMetaSuccess && result.meta.types.isNotEmpty) {
      _cachedValidTypes = result.meta.types
          .map((t) => AssetRepository.unifiedAssetType(t) ?? t.trim().toLowerCase())
          .where((t) => t.isNotEmpty)
          .toList(growable: false);
    } else {
      _cachedValidTypes = AssetMeta.fallbackTypes;
    }
    return _cachedValidTypes!;
  }

  List<String> _resolveSearchTypes(String? rawHint, List<String> validTypes) {
    final validSet = validTypes.map((t) => t.toLowerCase()).toSet();
    final normalized = rawHint == null || rawHint.trim().isEmpty
        ? null
        : AssetRepository.unifiedAssetType(rawHint) ?? rawHint.trim().toLowerCase();

    final ordered = <String>[];

    void addType(String type) {
      final t = type.toLowerCase();
      if (validSet.contains(t) && !ordered.contains(t)) {
        ordered.add(t);
      }
    }

    if (normalized != null && _semanticTypeOrder.containsKey(normalized)) {
      for (final t in _semanticTypeOrder[normalized]!) {
        addType(t);
      }
    } else if (normalized != null) {
      addType(normalized);
    }

    const defaultOrder = ['png', 'shape', 'logo', 'online_pic'];
    for (final t in defaultOrder) {
      addType(t);
    }
    for (final t in validTypes) {
      addType(t);
    }

    return ordered;
  }

  Future<ComposeExecuteResult> executeAddAsset({
    required BuildContext context,
    required ProImageEditorState editor,
    String? assetType,
    String? searchQuery,
    DesignComposePosition position = DesignComposePosition.center,
  }) async {
    final search = searchQuery?.trim() ?? '';
    final validTypes = await _loadValidAssetTypes();
    final typesToTry = _resolveSearchTypes(assetType, validTypes);

    MediaItem? best;
    String? matchedType;
    var bestScore = -1;

    for (final type in typesToTry) {
      final result = await _assetRepo.listAssets(
        type: type,
        search: search.isEmpty ? null : search,
        perPage: 30,
      );
      if (result is! AssetSuccess) continue;
      final items = result.items ?? const <MediaItem>[];
      if (items.isEmpty) continue;

      for (final item in items) {
        final score = _scoreItem(item, search);
        if (score > bestScore) {
          bestScore = score;
          best = item;
          matchedType = type;
        }
      }
    }

    if (best == null || matchedType == null) {
      return ComposeExecuteFailure('msg_ai_asset_not_found'.tr);
    }

    if (!context.mounted) {
      return ComposeExecuteFailure('msg_ai_failed'.tr);
    }

    final layerKind = AssetRepository.unifiedAssetType(matchedType) ?? matchedType;
    final built = await musamiBuildAssetWidgetLayer(
      context: context,
      item: best,
      layerKind: layerKind,
    );
    if (!context.mounted) {
      return ComposeExecuteFailure('msg_ai_failed'.tr);
    }
    if (built == null) {
      return ComposeExecuteFailure('msg_ai_asset_not_found'.tr);
    }

    final canvasSize = _canvasSize(context, editor);
    final aspect = (built.meta?['musamiAspect'] as num?)?.toDouble() ?? 1.0;
    final layerW = built.width ?? 200.0;
    final layerH = layerW * aspect;
    final scale = built.scale;
    final offset = _offsetForPosition(
      position: position,
      canvasSize: canvasSize,
      layerWidth: layerW,
      layerHeight: layerH,
      scale: scale,
    );

    final layer = built.copyWith(offset: offset);
    editor.addLayer(layer);
    _selectLayer(context, editor, layer.id);

    unawaited(_assetRepo.interact(best.id, action: 'download'));

    return ComposeExecuteSuccess(
      message: 'msg_ai_compose_success'.tr,
      assetName: best.name,
    );
  }

  static int _scoreItem(MediaItem item, String search) {
    if (search.isEmpty) return 1;

    final q = search.toLowerCase();
    final name = item.name.toLowerCase();
    final tags = (item.tags ?? '').toLowerCase();
    final words = q.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();

    if (name == q) return 100;
    if (name.contains(q)) return 80;
    if (tags.contains(q)) return 70;

    var score = 0;
    for (final word in words) {
      if (name.contains(word)) score += 20;
      if (tags.contains(word)) score += 10;
    }
    return score;
  }

  static Size _canvasSize(BuildContext context, ProImageEditorState editor) {
    final body = editor.sizesManager.bodySize;
    if (body.isEmpty || body == Size.infinite) {
      return MediaQuery.sizeOf(context);
    }
    return body;
  }

  static Offset _offsetForPosition({
    required DesignComposePosition position,
    required Size canvasSize,
    required double layerWidth,
    required double layerHeight,
    required double scale,
  }) {
    final w = layerWidth * scale;
    final h = layerHeight * scale;
    final m = _canvasMargin;

    return switch (position) {
      DesignComposePosition.center => Offset(
          (canvasSize.width - w) / 2,
          (canvasSize.height - h) / 2,
        ),
      DesignComposePosition.topLeft => Offset(m, m),
      DesignComposePosition.topRight => Offset(canvasSize.width - w - m, m),
      DesignComposePosition.bottomLeft => Offset(m, canvasSize.height - h - m),
      DesignComposePosition.bottomRight => Offset(
          canvasSize.width - w - m,
          canvasSize.height - h - m,
        ),
      DesignComposePosition.topCenter => Offset(
          (canvasSize.width - w) / 2,
          m,
        ),
      DesignComposePosition.bottomCenter => Offset(
          (canvasSize.width - w) / 2,
          canvasSize.height - h - m,
        ),
    };
  }

  static void _selectLayer(
    BuildContext context,
    ProImageEditorState editor,
    String id,
  ) {
    editor.layerInteractionManager.selectedLayerId = id;
    context.read<AddNewBloc>().add(
          EditorSelectionChangedEvent(
            selectedElementId: id,
            selectedElementType: 'image',
          ),
        );
    editor.setState(() {});
  }
}
