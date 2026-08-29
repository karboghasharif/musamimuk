import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../../core/app_export.dart';
import '../../../../core/network/authenticated_image.dart';
import '../../../../data/models/online_asset_models.dart';
import '../../../../data/repositories/online_asset_repository.dart';
import 'online_asset_apply.dart';

Future<T?> showOnlineAssetBrowserSheet<T>({
  required BuildContext context,
  required GlobalKey<ProImageEditorState>? editorKey,
  required OnlineAssetProvider provider,
  bool pickOnly = false,
  VoidCallback? onAssetAdded,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.92,
      child: OnlineAssetBrowserSheet(
        editorKey: editorKey,
        provider: provider,
        pickOnly: pickOnly,
        onAssetAdded: onAssetAdded,
      ),
    ),
  );
}

class OnlineAssetBrowserSheet extends StatefulWidget {
  const OnlineAssetBrowserSheet({
    super.key,
    required this.editorKey,
    required this.provider,
    this.pickOnly = false,
    this.onAssetAdded,
  });

  final GlobalKey<ProImageEditorState>? editorKey;
  final OnlineAssetProvider provider;
  final bool pickOnly;
  final VoidCallback? onAssetAdded;

  @override
  State<OnlineAssetBrowserSheet> createState() =>
      _OnlineAssetBrowserSheetState();
}

class _OnlineAssetBrowserSheetState extends State<OnlineAssetBrowserSheet> {
  final OnlineAssetRepository _repo = OnlineAssetRepository();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  List<OnlineAssetItem> _items = const [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = false;

  String get _searchHint {
    return switch (widget.provider) {
      OnlineAssetProvider.unsplash => 'lbl_oa_search_unsplash'.tr,
      OnlineAssetProvider.pexels => 'lbl_oa_search_pexels'.tr,
      OnlineAssetProvider.pixabay => 'lbl_oa_search_pixabay'.tr,
      OnlineAssetProvider.iconify => 'lbl_oa_search_iconify'.tr,
      OnlineAssetProvider.dummyImage => 'lbl_oa_search_dummy'.tr,
      OnlineAssetProvider.iconHorse => 'lbl_oa_search_domain'.tr,
      OnlineAssetProvider.phpNoise => 'lbl_oa_search_hex'.tr,
      OnlineAssetProvider.lottieLibrary => 'lbl_oa_search_lottie_library'.tr,
      OnlineAssetProvider.lordicon => 'lbl_oa_search_lordicon'.tr,
      OnlineAssetProvider.icons8 => 'lbl_oa_search_icon'.tr,
      OnlineAssetProvider.emojiHub => 'lbl_oa_search_emoji'.tr,
      _ => 'lbl_search_online_assets'.tr,
    };
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _load(reset: true);
    });
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      _load(reset: false);
    }
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _items = const [];
        _hasMore = false;
      });
    } else {
      if (!_hasMore || _loadingMore) return;
      setState(() => _loadingMore = true);
    }

    final page = reset ? 1 : _page;
    final result = await _repo.list(
      provider: widget.provider,
      query: _searchController.text,
      page: page,
    );

    if (!mounted) return;

    if (result is OnlineAssetListFailure) {
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (reset) {
          _error = result.message;
          _items = const [];
        }
      });
      return;
    }

    final success = result as OnlineAssetListSuccess;
    setState(() {
      _loading = false;
      _loadingMore = false;
      _items = reset ? success.items : [..._items, ...success.items];
      _hasMore = success.hasMore;
      _page = success.nextPage ?? (page + 1);
      if (_items.isEmpty) {
        _error = 'msg_online_assets_empty'.tr;
      } else {
        _error = null;
      }
    });
  }

  Future<void> _onSelect(OnlineAssetItem item) async {
    final layer = await applyOnlineAssetItem(
      context: context,
      item: item,
      editorKey: widget.editorKey,
      pickOnly: widget.pickOnly,
      onAssetAdded: widget.onAssetAdded,
    );
    if (!mounted) return;
    if (widget.pickOnly) {
      Navigator.of(context).pop(layer);
      return;
    }
    // Pop only this sheet; the category sheet closes itself once it sees the
    // `true` result. Popping both routes in one frame tears the editor subtree
    // down while it is capturing the new layer's screenshot.
    if (layer != null) Navigator.of(context).pop(true);
  }

  Future<void> _onSelectPaletteColor(
    OnlineAssetItem palette,
    Color color,
  ) async {
    final argb = color.toARGB32().toRadixString(16).padLeft(8, '0');
    final hex = argb.substring(2);
    final url = '${OnlineAssetRepository.dummyImageBase}/400x400/$hex/$hex.png';
    final solid = OnlineAssetItem(
      id: '${palette.id}_$hex',
      title: '#${hex.toUpperCase()}',
      provider: palette.provider,
      applyKind: OnlineAssetApplyKind.image,
      imageUrl: url,
      thumbUrl: url,
      width: 400,
      height: 400,
      attribution: palette.attribution,
    );
    await _onSelect(solid);
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
            _buildHeader(context),
            SizedBox(height: AppDs.space2.v),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDs.space4.h),
              child: AppSearchField(
                controller: _searchController,
                hintText: _searchHint,
              ),
            ),
            if (widget.provider == OnlineAssetProvider.colormind ||
                widget.provider == OnlineAssetProvider.phpNoise) ...[
              SizedBox(height: AppDs.space2.v),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: _loading ? null : () => _load(reset: true),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text('lbl_oa_refresh'.tr),
                ),
              ),
            ],
            SizedBox(height: AppDs.space2.v),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDs.space2.h),
      child: Row(
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: theme.colorScheme.primary,
              size: 20.adaptSize,
            ),
          ),
          Expanded(
            child: AppText(
              widget.provider.titleKey.tr,
              variant: AppTextVariant.title,
              color: Colors.white,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 48.adaptSize),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppDs.space4.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppDs.textOnDarkSecondary),
              ),
              SizedBox(height: AppDs.space3.v),
              TextButton(
                onPressed: () => _load(reset: true),
                child: Text('lbl_oa_retry'.tr),
              ),
            ],
          ),
        ),
      );
    }

    final isPalette =
        widget.provider == OnlineAssetProvider.colormind ||
        widget.provider == OnlineAssetProvider.colourLovers;
    final isEmoji = widget.provider == OnlineAssetProvider.emojiHub;
    final isLottie =
        widget.provider == OnlineAssetProvider.lottieLibrary ||
        widget.provider == OnlineAssetProvider.lordicon;
    final isSvg = widget.provider == OnlineAssetProvider.iconify;

    if (isPalette) {
      return ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(AppDs.space4.h, 0, AppDs.space4.h, 24.v),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => SizedBox(height: 12.v),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _PaletteTile(
            item: _items[index],
            onTapPalette: () => _onSelect(_items[index]),
            onTapColor: (c) => _onSelectPaletteColor(_items[index], c),
          );
        },
      );
    }

    if (isEmoji) {
      return GridView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(AppDs.space4.h, 0, AppDs.space4.h, 24.v),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10.v,
          crossAxisSpacing: 10.h,
          childAspectRatio: 0.85,
        ),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = _items[index];
          return Material(
            color: AppDs.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _onSelect(item),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.emoji ?? '', style: TextStyle(fontSize: 32.fSize)),
                  SizedBox(height: 4.v),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.h),
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.fSize,
                        color: AppDs.textOnDarkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    if (isLottie) {
      return GridView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(AppDs.space4.h, 0, AppDs.space4.h, 24.v),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12.v,
          crossAxisSpacing: 12.h,
          childAspectRatio: 0.95,
        ),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = _items[index];
          return Material(
            color: AppDs.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _onSelect(item),
              child: Padding(
                padding: EdgeInsets.all(10.adaptSize),
                child: Column(
                  children: [
                    Expanded(
                      child: item.lottieUrl == null
                          ? const Icon(Icons.animation)
                          : Lottie.network(
                              item.lottieUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.broken_image),
                            ),
                    ),
                    SizedBox(height: 6.v),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.fSize,
                        fontWeight: FontWeight.w600,
                        color: AppDs.textOnDarkPrimary,
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

    if (isSvg) {
      return GridView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(AppDs.space4.h, 0, AppDs.space4.h, 24.v),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10.v,
          crossAxisSpacing: 10.h,
          childAspectRatio: 0.8,
        ),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = _items[index];
          final svg = item.svgUrl ?? item.previewUrl;
          return Material(
            color: AppDs.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _onSelect(item),
              child: Padding(
                padding: EdgeInsets.all(8.adaptSize),
                child: Column(
                  children: [
                    Expanded(
                      child: svg == null
                          ? const Icon(Icons.category_outlined)
                          : SvgPicture.network(
                              svg,
                              fit: BoxFit.contain,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                              placeholderBuilder: (_) => const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    SizedBox(height: 4.v),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.fSize,
                        color: AppDs.textOnDarkSecondary,
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

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(AppDs.space4.h, 0, AppDs.space4.h, 24.v),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10.v,
        crossAxisSpacing: 10.h,
        childAspectRatio: 0.78,
      ),
      itemCount: _items.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final item = _items[index];
        return Material(
          color: AppDs.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _onSelect(item),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: item.previewUrl == null
                      ? const Center(child: Icon(Icons.image_not_supported))
                      : Image(
                          image: musamiAuthenticatedNetworkImage(
                            item.previewUrl!,
                          ),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Center(child: Icon(Icons.broken_image)),
                        ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(6.h, 6.v, 6.h, 8.v),
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.fSize,
                      color: AppDs.textOnDarkPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.item,
    required this.onTapPalette,
    required this.onTapColor,
  });

  final OnlineAssetItem item;
  final VoidCallback onTapPalette;
  final ValueChanged<Color> onTapColor;

  @override
  Widget build(BuildContext context) {
    final colors = item.colors ?? const <Color>[];
    return Material(
      color: AppDs.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTapPalette,
        child: Padding(
          padding: EdgeInsets.all(12.adaptSize),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.w600,
                  color: AppDs.textOnDarkPrimary,
                ),
              ),
              SizedBox(height: 8.v),
              if (item.previewUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 5,
                    child: Image(
                      image: musamiAuthenticatedNetworkImage(item.previewUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _colorStrip(colors),
                    ),
                  ),
                )
              else
                _colorStrip(colors),
              if (colors.isNotEmpty) ...[
                SizedBox(height: 8.v),
                Wrap(
                  spacing: 6.h,
                  runSpacing: 6.v,
                  children: [
                    for (final c in colors)
                      GestureDetector(
                        onTap: () => onTapColor(c),
                        child: Container(
                          width: 28.adaptSize,
                          height: 28.adaptSize,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppDs.sheetBorderSubtle(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorStrip(List<Color> colors) {
    if (colors.isEmpty) {
      return Container(height: 48, color: AppDs.surfaceBase);
    }
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          for (final c in colors) Expanded(child: ColoredBox(color: c)),
        ],
      ),
    );
  }
}
