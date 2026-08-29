import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/app_export.dart';
import '../../../core/network/authenticated_image.dart';
import '../../../data/models/category_item.dart';
import '../../../data/models/media_item.dart';
import '../../../data/repositories/asset_repository.dart';
import '../../../data/repositories/media_repository.dart';
import '../../../widgets/app_bar/appbar_leading_image.dart';
import '../utils/musami_asset_layer.dart';

/// Opens the asset picker sheet at ~92% screen height.
Future<T?> showApiAssetBottomSheet<T>({
  required BuildContext context,
  required GlobalKey<ProImageEditorState>? editorKey,
  MediaType? type,
  String? assetType,
  bool pickOnly = false,
  VoidCallback? onAssetAdded,
}) {
  assert(type != null || assetType != null, 'Provide either type or assetType');
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.92,
      child: ApiAssetBottomSheet(
        editorKey: editorKey,
        type: type,
        assetType: assetType,
        pickOnly: pickOnly,
        onAssetAdded: onAssetAdded,
      ),
    ),
  );
}

/// API-driven asset picker with search, category chips, and grid/list views.
class ApiAssetBottomSheet extends StatefulWidget {
  const ApiAssetBottomSheet({
    super.key,
    required this.editorKey,
    this.type,
    this.assetType,
    this.pickOnly = false,
    this.onAssetAdded,
  }) : assert(type != null || assetType != null);

  final GlobalKey<ProImageEditorState>? editorKey;
  final MediaType? type;
  final String? assetType;

  /// When true, selecting an asset pops the sheet with a [WidgetLayer].
  final bool pickOnly;

  /// Called after an asset is added to the editor (non–pick-only mode).
  final VoidCallback? onAssetAdded;

  @override
  State<ApiAssetBottomSheet> createState() => _ApiAssetBottomSheetState();
}

class _ApiAssetBottomSheetState extends State<ApiAssetBottomSheet> {
  static const int _gridColumnCount = 3;

  final AssetRepository _assetRepo = AssetRepository();
  late final MediaRepository? _legacyRepo =
      _assetType == null && widget.type != null
      ? MediaRepository(type: widget.type!)
      : null;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<CategoryItem> _apiCategories = [];
  List<String> _categories = [];
  Map<String, List<MediaItem>> _byCategory = {};
  int _selectedCategoryIndex = 0;
  bool _loading = true;
  String? _error;
  bool _isGridView = true;

  String? get _assetType {
    final key = widget.assetType;
    if (key != null) {
      return AssetRepository.unifiedAssetType(key) ?? key.trim().toLowerCase();
    }
    final mediaType = widget.type;
    if (mediaType != null) return AssetRepository.typeParamFor(mediaType);
    return null;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadAssets();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _loadAssets);
  }

  void _toggleViewMode() {
    setState(() => _isGridView = !_isGridView);
  }

  Future<void> _loadAssets() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_assetType != null) {
        await _loadUnifiedAssets();
      } else {
        await _loadLegacyAssets();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Something went wrong';
        _byCategory = {};
        _categories = const [];
        _selectedCategoryIndex = 0;
      });
    }
  }

  Future<void> _loadUnifiedAssets() async {
    final type = _assetType!;
    final search = _searchController.text.trim();

    if (_apiCategories.isEmpty) {
      final catResult = await _assetRepo.categories(type: type);
      if (catResult is AssetCategoriesSuccess) {
        _apiCategories = catResult.items;
      }
    }

    final result = await _assetRepo.listAssets(
      type: type,
      search: search.isEmpty ? null : search,
      perPage: 50,
    );
    if (!mounted) return;

    if (result is AssetFailure) {
      setState(() {
        _loading = false;
        _error = result.message;
        _byCategory = {};
        _categories = const [];
        _selectedCategoryIndex = 0;
      });
      return;
    }

    final list = (result as AssetSuccess).items ?? const <MediaItem>[];
    final byCategory = <String, List<MediaItem>>{};
    for (final s in list) {
      final name = s.category?.name ?? 'Other';
      byCategory.putIfAbsent(name, () => []).add(s);
    }

    final tabNames = <String>['Home'];
    if (_apiCategories.isNotEmpty) {
      tabNames.addAll(_apiCategories.map((c) => c.name));
    } else {
      tabNames.addAll(byCategory.keys.toList()..sort());
    }

    setState(() {
      _byCategory = byCategory;
      _categories = tabNames;
      _loading = false;
      if (list.isEmpty) _error = 'No items found';
      if (_selectedCategoryIndex >= _categories.length) {
        _selectedCategoryIndex = 0;
      }
    });
  }

  Future<void> _loadLegacyAssets() async {
    final result = await _legacyRepo!.list();
    if (!mounted) return;

    if (result is MediaFailure) {
      setState(() {
        _loading = false;
        _error = result.message;
        _byCategory = {};
        _categories = const [];
        _selectedCategoryIndex = 0;
      });
      return;
    }

    final list = (result as MediaSuccess).items ?? const <MediaItem>[];
    final byCategory = <String, List<MediaItem>>{};
    for (final s in list) {
      final name = s.category?.name ?? 'Other';
      byCategory.putIfAbsent(name, () => []).add(s);
    }
    final categories = ['Home', ...byCategory.keys.toList()..sort()];
    setState(() {
      _byCategory = byCategory;
      _categories = categories;
      _loading = false;
      if (list.isEmpty) _error = 'No items found';
      if (_selectedCategoryIndex >= _categories.length) {
        _selectedCategoryIndex = 0;
      }
    });
  }

  Map<String, List<MediaItem>> get _sectionsToShow {
    if (_categories.isEmpty) return const {};
    if (_selectedCategoryIndex == 0) return _byCategory;
    final name = _categories[_selectedCategoryIndex];
    final list = _byCategory[name] ?? const <MediaItem>[];
    return {name: list};
  }

  String _layerKindForSelection() {
    final unified = _assetType;
    if (unified != null) return unified;
    return switch (widget.type) {
      MediaType.logo => 'logo',
      MediaType.png => 'png',
      MediaType.shape => 'shape',
      MediaType.design => 'png',
      null => 'png',
    };
  }

  void _selectCategory(int index) {
    setState(() => _selectedCategoryIndex = index);
  }

  void _onSeeAll(String categoryName) {
    final index = _categories.indexOf(categoryName);
    if (index >= 0) _selectCategory(index);
  }

  Future<void> _onSelectAsset(MediaItem item) async {
    if (_assetType != null) {
      unawaited(_assetRepo.interact(item.id, action: 'download'));
    }

    final layerKind = _layerKindForSelection();
    final layer = await musamiBuildAssetWidgetLayer(
      context: context,
      item: item,
      layerKind: layerKind,
      editor: widget.editorKey?.currentState,
    );
    if (layer == null || !mounted) return;

    if (widget.pickOnly) {
      Navigator.of(context).pop(layer);
      return;
    }
    final editor = widget.editorKey?.currentState;
    if (editor == null) return;
    editor.addLayer(layer);
    widget.onAssetAdded?.call();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppDs.surfaceBase,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDs.radiusSheet.adaptSize),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: AppDs.space3.v),
            _buildBackRow(context),
            SizedBox(height: AppDs.space3.v),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDs.space4.h),
              child: AppSearchField(
                controller: _searchController,
                hintText: 'lbl_search'.tr,
              ),
            ),
            SizedBox(height: AppDs.space4.v),
            _buildCategoryTabs(),
            SizedBox(height: AppDs.space2.v),
            Expanded(
              child: _loading
                  ? const AppLoadingBlock()
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppDs.space6.h),
                        child: AppText(
                          _error!,
                          variant: AppTextVariant.secondary,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _buildSections(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackRow(BuildContext context) {
    final primary = theme.colorScheme.primary;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDs.space4.h),
      child: Row(
        children: [
          AppbarLeadingImage(
            imagePath: ImageConstant.imgArrowLeftPrimary,
            onTap: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          _ViewModeToggle(
            isGridView: _isGridView,
            primary: primary,
            onToggle: _toggleViewMode,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44.v,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppDs.space4.h),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => SizedBox(width: AppDs.space4.h),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategoryIndex;
          if (index == 0) return _buildHomeTab(isSelected, index);
          return _buildTextCategoryTab(
            label: _categories[index],
            isSelected: isSelected,
            index: index,
          );
        },
      ),
    );
  }

  Widget _buildHomeTab(bool isSelected, int index) {
    return GestureDetector(
      onTap: () => _selectCategory(index),
      child: Container(
        height: 43.v,
        width: 48.h,
        padding: EdgeInsets.symmetric(
          horizontal: AppDs.space3.h,
          vertical: AppDs.space2.v,
        ),
        decoration: AppDecoration.fillGray800.copyWith(
          borderRadius: BorderRadiusStyle.roundedBorder15,
          border: Border.all(
            color: isSelected ? appTheme.yellow500 : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: CustomImageView(
          imagePath: ImageConstant.imgHome,
          height: AppDs.iconMd.adaptSize,
          width: AppDs.iconMd.adaptSize,
          alignment: Alignment.center,
          color: isSelected ? appTheme.yellow500 : appTheme.gray100,
        ),
      ),
    );
  }

  Widget _buildTextCategoryTab({
    required String label,
    required bool isSelected,
    required int index,
  }) {
    return GestureDetector(
      onTap: () => _selectCategory(index),
      child: Center(
        child: AppText(
          label,
          variant: isSelected ? AppTextVariant.heading : AppTextVariant.body,
          color: isSelected
              ? AppDs.textOnDarkPrimary
              : AppDs.textOnDarkSecondary,
        ),
      ),
    );
  }

  Widget _buildSections() {
    final sections = _sectionsToShow;
    if (sections.isEmpty) {
      return Center(
        child: AppText(
          'No items in this category',
          variant: AppTextVariant.secondary,
        ),
      );
    }

    // Category / See all: one full category body.
    if (_selectedCategoryIndex != 0 && sections.length == 1) {
      final entry = sections.entries.first;
      return _buildCategoryBody(title: entry.key, items: entry.value);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppDs.space4.h,
        AppDs.space3.v,
        AppDs.space4.h,
        AppDs.space6.v,
      ),
      children: sections.entries.map((e) {
        final title = e.key;
        final items = e.value;
        if (items.isEmpty) return const SizedBox.shrink();
        return _buildSection(title: title, items: items);
      }).toList(),
    );
  }

  Widget _buildCategoryBody({
    required String title,
    required List<MediaItem> items,
  }) {
    if (items.isEmpty) {
      return Center(
        child: AppText(
          'No items in this category',
          variant: AppTextVariant.secondary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppDs.space4.h,
            AppDs.space3.v,
            AppDs.space4.h,
            AppDs.space2.v,
          ),
          child: AppSectionHeader(title: title),
        ),
        Expanded(
          child: _isGridView
              ? GridView.builder(
                  padding: EdgeInsets.fromLTRB(
                    AppDs.space4.h,
                    AppDs.space2.v,
                    AppDs.space4.h,
                    AppDs.space6.v,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridColumnCount,
                    mainAxisSpacing: AppDs.space4.v,
                    crossAxisSpacing: AppDs.space4.h,
                    childAspectRatio: 1,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _buildAssetGridTile(items[index]),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    AppDs.space4.h,
                    AppDs.space2.v,
                    AppDs.space4.h,
                    AppDs.space6.v,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => SizedBox(height: AppDs.space2.v),
                  itemBuilder: (context, index) =>
                      _buildAssetListTile(items[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<MediaItem> items,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppDs.space6.v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: title,
            trailing: GestureDetector(
              onTap: () => _onSeeAll(title),
              child: AppText('lbl_see_all'.tr, variant: AppTextVariant.accent),
            ),
          ),
          if (_isGridView)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridColumnCount,
                mainAxisSpacing: AppDs.space4.v,
                crossAxisSpacing: AppDs.space4.h,
                childAspectRatio: 1,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  _buildAssetGridTile(items[index]),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => SizedBox(height: AppDs.space2.v),
              itemBuilder: (context, index) =>
                  _buildAssetListTile(items[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildAssetGridTile(MediaItem asset) {
    return GestureDetector(
      onTap: () => _onSelectAsset(asset),
      child: SizedBox(
        width: 104.h,
        height: 104.v,
        child: Padding(
          padding: EdgeInsets.all(AppDs.space2.h),
          child: _buildAssetImage(asset, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildAssetListTile(MediaItem asset) {
    final subtitle = asset.category?.name.trim();
    return Material(
      color: AppDs.surfaceElevated,
      borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => _onSelectAsset(asset),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDs.space3.h,
          vertical: AppDs.space1.v,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppDs.radiusSm.adaptSize),
          child: SizedBox(
            width: 52.adaptSize,
            height: 52.adaptSize,
            child: ColoredBox(
              color: AppDs.surfaceBase,
              child: _buildAssetImage(asset, fit: BoxFit.contain),
            ),
          ),
        ),
        title: AppText(
          asset.name.trim().isEmpty ? 'Asset #${asset.id}' : asset.name,
          variant: AppTextVariant.body,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: (subtitle != null && subtitle.isNotEmpty)
            ? AppText(
                subtitle,
                variant: AppTextVariant.secondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Icon(
          Icons.add_circle_outline_rounded,
          color: theme.colorScheme.primary,
          size: 22.adaptSize,
        ),
      ),
    );
  }

  Widget _buildAssetImage(MediaItem asset, {required BoxFit fit}) {
    return Image.network(
      asset.fileUrl,
      fit: fit,
      headers: musamiAuthenticatedHeadersForUrl(asset.fileUrl),
      errorBuilder: (_, _, _) => Icon(
        Icons.broken_image_outlined,
        color: AppDs.textOnDarkDisabled,
        size: 28.adaptSize,
      ),
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({
    required this.isGridView,
    required this.primary,
    required this.onToggle,
  });

  final bool isGridView;
  final Color primary;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppDs.surfaceElevated,
      borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
      child: Padding(
        padding: EdgeInsets.all(2.adaptSize),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ViewModeButton(
              icon: Icons.grid_view_rounded,
              tooltip: 'lbl_grid_view'.tr,
              selected: isGridView,
              primary: primary,
              onTap: isGridView ? null : onToggle,
            ),
            _ViewModeButton(
              icon: Icons.view_list_rounded,
              tooltip: 'lbl_list_view'.tr,
              selected: !isGridView,
              primary: primary,
              onTap: isGridView ? onToggle : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  const _ViewModeButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final Color primary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusSm.adaptSize),
        child: AnimatedContainer(
          duration: AppDs.motionFast,
          padding: EdgeInsets.symmetric(
            horizontal: AppDs.space2.h,
            vertical: AppDs.space1.v + 2,
          ),
          decoration: BoxDecoration(
            color: selected ? primary.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDs.radiusSm.adaptSize),
          ),
          child: Icon(
            icon,
            size: 20.adaptSize,
            color: selected ? primary : AppDs.textOnDarkSecondary,
          ),
        ),
      ),
    );
  }
}
