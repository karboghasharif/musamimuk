import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/app_export.dart';
import '../../../data/models/asset_meta.dart';
import '../../../data/repositories/asset_repository.dart';
import '../models/gridgallery_pic_item_model.dart';
import 'api_asset_bottom_sheet.dart';
import 'gridgallery_pic_item_widget.dart';
import 'online_assets/online_assets_category_sheet.dart';

/// Add-new yellow panel: main tools grid, then asset types from API.
class AddNewBookmarkPanel extends StatefulWidget {
  const AddNewBookmarkPanel({
    super.key,
    required this.editorKey,
    required this.baseGridItems,
    required this.onToolTap,
    this.onAssetAdded,
  });

  final GlobalKey<ProImageEditorState>? editorKey;
  final List<GridgalleryPicItemModel> baseGridItems;
  final Future<void> Function(GridgalleryPicItemModel model) onToolTap;
  final VoidCallback? onAssetAdded;

  @override
  State<AddNewBookmarkPanel> createState() => _AddNewBookmarkPanelState();
}

class _AddNewBookmarkPanelState extends State<AddNewBookmarkPanel> {
  final AssetRepository _assetRepo = AssetRepository();

  List<String> _assetTypes = const [];
  bool _loadingTypes = true;

  @override
  void initState() {
    super.initState();
    _loadAssetTypes();
  }

  Future<void> _loadAssetTypes() async {
    setState(() => _loadingTypes = true);
    final result = await _assetRepo.fetchMeta();
    if (!mounted) return;
    if (result is AssetMetaSuccess) {
      setState(() {
        _assetTypes = result.meta.types;
        _loadingTypes = false;
      });
      return;
    }
    setState(() {
      _assetTypes = AssetMeta.fallbackTypes;
      _loadingTypes = false;
    });
  }

  Future<void> _openAssetType(String type) async {
    final normalized = AssetRepository.unifiedAssetType(type);
    if (normalized == null) return;
    await showApiAssetBottomSheet<void>(
      context: context,
      editorKey: widget.editorKey,
      assetType: normalized,
      onAssetAdded: widget.onAssetAdded,
    );
  }

  List<GridgalleryPicItemModel> get _combinedGridItems {
    final base = widget.baseGridItems;
    final result = List<GridgalleryPicItemModel>.from(base);

    // Always expose Online Assets next to Add Text.
    final onlineTile = GridgalleryPicItemModel(
      gallerypic: 'lbl_online_assets'.tr,
      icon: Icons.travel_explore_rounded,
      id: 'online_assets',
    );
    final insertAfterText =
        result.indexWhere((e) => e.gallerypic == 'Add Text');
    final onlineAt = insertAfterText >= 0 ? insertAfterText + 1 : result.length;
    result.insert(onlineAt, onlineTile);

    if (_loadingTypes || _assetTypes.isEmpty) return result;

    final assetTiles = _assetTypes.map((type) {
      return GridgalleryPicItemModel(
        gallerypic: _labelForAssetType(type),
        icon: _iconForAssetType(type),
        id: 'asset_type:$type',
      );
    });
    result.insertAll(onlineAt + 1, assetTiles);
    return result;
  }

  static String _labelForAssetType(String type) {
    return switch (type.toLowerCase()) {
      'shape' => 'Shapes',
      'png' => 'PNG Images',
      'logo' => 'Logos',
      'online_pic' => 'Online Pic',
      _ => type.isEmpty
          ? 'Assets'
          : '${type[0].toUpperCase()}${type.substring(1)}',
    };
  }

  static IconData _iconForAssetType(String type) {
    return switch (type.toLowerCase()) {
      'shape' => Icons.category_outlined,
      'png' => Icons.image,
      'logo' => Icons.branding_watermark_outlined,
      'online_pic' => Icons.wallpaper_outlined,
      _ => Icons.folder_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.55;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Column(
        children: [
          SizedBox(height: 25.v),
          Expanded(child: _buildToolsGrid()),
        ],
      ),
    );
  }

  Widget _buildToolsGrid() {
    final items = _combinedGridItems;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.only(right: 1.h),
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            mainAxisExtent: 93.v,
            crossAxisCount: 3,
            mainAxisSpacing: 15.h,
            crossAxisSpacing: 15.h,
          ),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final model = items[index];
            return GridgalleryPicItemWidget(
              model,
              onTapColumngallery: () async {
                final id = model.id ?? '';
                if (id == 'online_assets') {
                  await showOnlineAssetsCategorySheet<void>(
                    context: context,
                    editorKey: widget.editorKey,
                    onAssetAdded: widget.onAssetAdded,
                  );
                  return;
                }
                if (id.startsWith('asset_type:')) {
                  final rawType = id.substring('asset_type:'.length);
                  await _openAssetType(rawType);
                  return;
                }
                await widget.onToolTap(model);
              },
            );
          },
        ),
      ),
    );
  }
}
