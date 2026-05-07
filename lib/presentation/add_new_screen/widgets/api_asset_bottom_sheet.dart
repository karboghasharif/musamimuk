import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/app_export.dart';
import '../../../data/models/media_item.dart';
import '../../../data/repositories/media_repository.dart';

/// Reusable API-driven asset picker bottom sheet.
///
/// Same UI/behavior as Shapes bottom sheet, but supports different endpoints
/// via [MediaType] (shape/png/logo/design).
class ApiAssetBottomSheet extends StatefulWidget {
  const ApiAssetBottomSheet({
    super.key,
    required this.editorKey,
    required this.type,
    this.pickOnly = false,
  });

  final GlobalKey<ProImageEditorState>? editorKey;
  final MediaType type;

  /// When true, selecting an asset pops the sheet with a [WidgetLayer] instead
  /// of adding it to the editor (used for "Replace image").
  final bool pickOnly;

  @override
  State<ApiAssetBottomSheet> createState() => _ApiAssetBottomSheetState();
}

class _ApiAssetBottomSheetState extends State<ApiAssetBottomSheet> {
  late final MediaRepository _repo = MediaRepository(type: widget.type);
  final TextEditingController _searchController = TextEditingController();

  List<String> _categories = [];
  Map<String, List<MediaItem>> _byCategory = {};
  int _selectedCategoryIndex = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.list();
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
      if (list.isEmpty) {
        _error = 'No items found';
      }
      if (_selectedCategoryIndex >= _categories.length) {
        _selectedCategoryIndex = 0;
      }
    });
  }

  Map<String, List<MediaItem>> get _sectionsToShow {
    if (_selectedCategoryIndex == 0) return _byCategory;
    if (_categories.isEmpty) return const {};
    final name = _categories[_selectedCategoryIndex];
    final list = _byCategory[name] ?? const <MediaItem>[];
    return {name: list};
  }

  String _layerKindForType() {
    return switch (widget.type) {
      MediaType.logo => 'logo',
      MediaType.png => 'png',
      MediaType.shape => 'shape',
      MediaType.design => 'png',
    };
  }

  void _onSelectAsset(MediaItem item) {
    final layer = WidgetLayer(
      meta: <String, dynamic>{'musamiLayerKind': _layerKindForType()},
      widget: Container(
        width: 150,
        height: 150,
        constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
        child: Image.network(
          item.fileUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
        ),
      ),
    );
    if (widget.pickOnly) {
      if (mounted) Navigator.of(context).pop(layer);
      return;
    }
    final editor = widget.editorKey?.currentState;
    if (editor == null) return;
    editor.addLayer(layer);
    if (mounted) Navigator.of(context).pop();
  }

  static const Color _searchBarFill = Color(0xFF3A4048);
  static const Color _textLight = Color(0xFFF5F5F5);
  static const Color _textMuted = Color(0xFFB0B0B0);
  static const Color _textOnYellow = Color(0xFF1A1A1A);
  static const Color _borderLight = Color(0xFF4A5058);
  static const Color _cardFill = Color(0xFF3A4048);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDs.sheetBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDs.radiusSheet.adaptSize),
        ),
        boxShadow: AppDs.shadowSheetHandle(),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: AppDs.space4.v),
            _buildSearchBar(),
            SizedBox(height: AppDs.space3.v),
            _buildCategoryTabs(),
            SizedBox(height: AppDs.space2.v),
            Flexible(
              child: _loading
                  ? const AppLoadingBlock()
                  : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: _textMuted),
                      ),
                    )
                  : _buildSections(),
            ),
            SizedBox(height: AppDs.space6.v),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDs.space4.h),
      child: Container(
        height: 48.v,
        decoration: BoxDecoration(
          color: _searchBarFill,
          borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: _textLight, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: const TextStyle(color: _textMuted, fontSize: 16),
            prefixIcon: Icon(Icons.search, color: _textMuted, size: 22),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.h,
              vertical: 14.v,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    if (_categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44.v,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppDs.space4.h),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategoryIndex;
          final isHome = index == 0;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              margin: EdgeInsets.only(right: 10.h),
              padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 10.v),
              decoration: BoxDecoration(
                color: isSelected ? appTheme.yellow500 : AppDs.sheetBackground,
                borderRadius: BorderRadius.circular(AppDs.radiusSm.h),
                border: Border.all(
                  color: isSelected ? appTheme.yellow500 : _borderLight,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isHome)
                    Icon(
                      isSelected ? Icons.home : Icons.home_outlined,
                      color: isSelected ? _textOnYellow : _textMuted,
                      size: 20,
                    ),
                  if (isHome) SizedBox(width: 6.h),
                  Text(
                    _categories[index],
                    style: TextStyle(
                      color: isSelected ? _textOnYellow : _textMuted,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSections() {
    final sections = _sectionsToShow;
    if (sections.isEmpty) {
      return Center(
        child: Text(
          'No items in this category',
          style: const TextStyle(color: _textMuted, fontSize: 15),
        ),
      );
    }
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(
        horizontal: AppDs.space4.h,
        vertical: AppDs.space3.v,
      ),
      children: sections.entries.map((e) {
        final title = e.key;
        final items = _applySearch(e.value);
        if (items.isEmpty) return const SizedBox.shrink();
        return _buildSection(title: title, items: items);
      }).toList(),
    );
  }

  List<MediaItem> _applySearch(List<MediaItem> items) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  Widget _buildSection({
    required String title,
    required List<MediaItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.v),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _textLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'See all',
                style: TextStyle(
                  color: appTheme.yellow500,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110.v,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final asset = items[index];
              return GestureDetector(
                onTap: () => _onSelectAsset(asset),
                child: Container(
                  width: 100.h,
                  height: 100.v,
                  margin: EdgeInsets.only(right: 12.h),
                  decoration: BoxDecoration(
                    color: _cardFill,
                    borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
                    border: Border.all(color: _borderLight),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
                    child: Image.network(
                      asset.fileUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          Icon(Icons.broken_image, color: _textMuted, size: 32),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16.v),
      ],
    );
  }
}
