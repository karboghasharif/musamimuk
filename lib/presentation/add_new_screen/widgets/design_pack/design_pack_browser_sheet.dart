import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/app_export.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../data/models/design_pack_models.dart';
import '../../../../data/services/design_pack_catalog.dart';
import '../../utils/musami_design_pack_apply.dart';

Future<T?> showDesignPackBrowserSheet<T>({
  required BuildContext context,
  required GlobalKey<ProImageEditorState>? editorKey,
  VoidCallback? onAssetAdded,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.92,
      child: DesignPackBrowserSheet(
        editorKey: editorKey,
        onAssetAdded: onAssetAdded,
      ),
    ),
  );
}

class DesignPackBrowserSheet extends StatefulWidget {
  const DesignPackBrowserSheet({
    super.key,
    required this.editorKey,
    this.onAssetAdded,
  });

  final GlobalKey<ProImageEditorState>? editorKey;
  final VoidCallback? onAssetAdded;

  @override
  State<DesignPackBrowserSheet> createState() => _DesignPackBrowserSheetState();
}

class _DesignPackBrowserSheetState extends State<DesignPackBrowserSheet> {
  final _catalog = DesignPackCatalog.instance;
  final _search = TextEditingController();

  DesignPackCategory _category = DesignPackCategory.borders;
  String? _subcategory;
  bool _loading = true;
  String? _error;
  bool _inserting = false;
  List<DesignPackItem> _items = const [];
  List<String> _subs = const [];

  static const _pageSize = 48;
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _catalog.ensureLoaded();
      if (!mounted) return;
      _refreshList();
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'msg_design_pack_load_failed'.tr;
      });
    }
  }

  void _onSearchChanged() {
    _refreshList();
    setState(() {});
  }

  void _refreshList() {
    _subs = _catalog.subcategories(_category);
    if (_subcategory != null && !_subs.contains(_subcategory)) {
      _subcategory = _subs.isEmpty ? null : _subs.first;
    }
    if ((_category == DesignPackCategory.shapes ||
            _category == DesignPackCategory.specialtext) &&
        _subcategory == null &&
        _subs.isNotEmpty) {
      _subcategory = _subs.first;
    }
    _items = _catalog.items(
      category: _category,
      subcategory: _subcategory,
      query: _search.text,
    );
    _visibleCount = _pageSize;
  }

  Future<void> _insert(DesignPackItem item) async {
    if (_inserting) return;
    setState(() => _inserting = true);
    try {
      final layer = await musamiApplyDesignPackItem(
        context: context,
        item: item,
        editorKey: widget.editorKey,
        onAssetAdded: widget.onAssetAdded,
      );
      if (!mounted) return;
      if (layer == null) {
        showAppToast(
          'msg_design_pack_insert_failed'.tr,
          type: ToastificationType.error,
        );
      } else {
        Navigator.of(context).maybePop();
      }
    } catch (_) {
      if (!mounted) return;
      showAppToast(
        'msg_design_pack_insert_failed'.tr,
        type: ToastificationType.error,
      );
    } finally {
      if (mounted) setState(() => _inserting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    return Material(
      color: AppDs.surfaceBase,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDs.radiusSheet.adaptSize),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: 10.v),
            Container(
              width: 40.h,
              height: 4.v,
              decoration: BoxDecoration(
                color: AppDs.sheetBorderSubtle(),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.h, 12.v, 8.h, 8.v),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'lbl_design_pack'.tr,
                      style: TextStyle(
                        fontSize: 18.fSize,
                        fontWeight: FontWeight.w700,
                        color: AppDs.textOnDarkPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.close, color: AppDs.textOnDarkSecondary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.h),
              child: AppSearchField(
                controller: _search,
                hintText: 'lbl_design_pack_search'.tr,
              ),
            ),
            SizedBox(height: 10.v),
            SizedBox(
              height: 40.v,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 12.h),
                children: [
                  for (final cat in DesignPackCategory.values) ...[
                    _chip(
                      label: cat.labelKey.tr,
                      selected: _category == cat,
                      onTap: () {
                        setState(() {
                          _category = cat;
                          _subcategory = null;
                          _refreshList();
                        });
                      },
                      primary: primary,
                    ),
                    SizedBox(width: 8.h),
                  ],
                ],
              ),
            ),
            if (_subs.isNotEmpty) ...[
              SizedBox(height: 8.v),
              SizedBox(
                height: 36.v,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 12.h),
                  children: [
                    for (final sub in _subs) ...[
                      _chip(
                        label: _subLabel(sub),
                        selected: _subcategory == sub,
                        onTap: () {
                          setState(() {
                            _subcategory = sub;
                            _refreshList();
                          });
                        },
                        primary: primary,
                        compact: true,
                      ),
                      SizedBox(width: 8.h),
                    ],
                  ],
                ),
              ),
            ],
            SizedBox(height: 8.v),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  String _subLabel(String raw) {
    if (raw.isEmpty) return 'lbl_design_pack_all'.tr;
    return raw.replaceAll('-', ' ');
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color primary,
    bool compact = false,
  }) {
    return Material(
      color: selected ? primary.withValues(alpha: 0.22) : AppDs.surfaceRaised,
      borderRadius: BorderRadius.circular(20.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.h),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12.h : 14.h,
            vertical: compact ? 6.v : 8.v,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.h),
            border: Border.all(
              color: selected
                  ? primary.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? primary : AppDs.textOnDarkSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: compact ? 12.fSize : 13.fSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.h),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppDs.textOnDarkSecondary),
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(
          'msg_design_pack_empty'.tr,
          style: const TextStyle(color: AppDs.textOnDarkSecondary),
        ),
      );
    }

    final visible = _items.take(_visibleCount).toList(growable: false);
    final hasMore = _visibleCount < _items.length;

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (!hasMore) return false;
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 240) {
          setState(() {
            _visibleCount =
                (_visibleCount + _pageSize).clamp(0, _items.length);
          });
        }
        return false;
      },
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(12.h, 4.v, 12.h, 24.v),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10.v,
          crossAxisSpacing: 10.h,
          childAspectRatio: 0.85,
        ),
        itemCount: visible.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= visible.length) {
            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final item = visible[index];
          return _PackTile(
            item: item,
            busy: _inserting,
            onTap: () => _insert(item),
          );
        },
      ),
    );
  }
}

class _PackTile extends StatelessWidget {
  const _PackTile({
    required this.item,
    required this.onTap,
    required this.busy,
  });

  final DesignPackItem item;
  final VoidCallback onTap;
  final bool busy;

  bool get _tintSvg =>
      item.category == DesignPackCategory.borders ||
      item.category == DesignPackCategory.shapes;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppDs.surfaceRaised,
      borderRadius: BorderRadius.circular(12.h),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(12.h),
        child: Padding(
          padding: EdgeInsets.all(8.h),
          child: Column(
            children: [
              Expanded(child: _thumb(item)),
              SizedBox(height: 6.v),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.fSize,
                  color: AppDs.textOnDarkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb(DesignPackItem item) {
    final thumb = item.thumbPath ?? (item.isSvg ? null : item.assetPath);
    if (thumb != null && !thumb.toLowerCase().endsWith('.svg')) {
      return Image.asset(
        thumb,
        fit: BoxFit.contain,
        cacheWidth: 160,
        cacheHeight: 160,
        errorBuilder: (_, _, _) => _svgOrFallback(item),
      );
    }
    return _svgOrFallback(item);
  }

  Widget _svgOrFallback(DesignPackItem item) {
    if (item.isSvg) {
      return SvgPicture.asset(
        item.assetPath,
        fit: BoxFit.contain,
        colorFilter: _tintSvg
            ? const ColorFilter.mode(Color(0xFFEEEEEE), BlendMode.srcIn)
            : null,
        placeholderBuilder: (_) => const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorBuilder: (_, _, _) => const Icon(
          Icons.broken_image_outlined,
          color: AppDs.textOnDarkSecondary,
        ),
      );
    }
    return Image.asset(
      item.assetPath,
      fit: BoxFit.contain,
      cacheWidth: 160,
      cacheHeight: 160,
      errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
    );
  }
}
