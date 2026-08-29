import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../../../data/models/media_item.dart';
import '../../../data/repositories/admin_design_repository.dart';
import '../models/category_design_group_model.dart';
import '../models/listsection_item_model.dart';
import '../models/rectanglelistsection_item_model.dart';
import '../models/screen_16_online_designs_model.dart';
part 'screen_16_online_designs_event.dart';
part 'screen_16_online_designs_state.dart';

class Screen16OnlineDesignsBloc
    extends Bloc<Screen16OnlineDesignsEvent, Screen16OnlineDesignsState> {
  Screen16OnlineDesignsBloc(super.initialState)
    : _adminDesigns = AdminDesignRepository() {
    on<Screen16OnlineDesignsInitialEvent>(_onInitialize);
    on<Screen16OnlineDesignsLoadEvent>(_onLoad);
    on<Screen16OnlineDesignsSearchChangedEvent>(_onSearchChanged);
    on<Screen16OnlineDesignsCategoryChangedEvent>(_onCategoryChanged);
  }
  final AdminDesignRepository _adminDesigns;

  /// Cached full list from `GET /designs` (client-side search/filter).
  List<MediaItem> _allDesigns = [];
  String _searchQuery = '';
  int? _selectedCategoryId;
  int _loadGeneration = 0;

  static final _fallbackRectangle = <RectanglelistsectionItemModel>[
    RectanglelistsectionItemModel(rectangle: ImageConstant.imgRectangle5582),
    RectanglelistsectionItemModel(rectangle: ImageConstant.imgRectangle5580),
    RectanglelistsectionItemModel(rectangle: ImageConstant.imgRectangle5581),
  ];

  static final _fallbackList = <ListsectionItemModel>[
    ListsectionItemModel(rectangle: ImageConstant.imgRectangle5585),
    ListsectionItemModel(rectangle: ImageConstant.imgRectangle5583),
  ];

  List<MediaCategoryRef> _distinctCategories(List<MediaItem> items) {
    final map = <int, String>{};
    for (final e in items) {
      final c = e.category;
      if (c != null) {
        map[c.id] = c.name;
      } else if (e.categoryId != null) {
        map[e.categoryId!] = 'Category ${e.categoryId}';
      }
    }
    final list = map.entries
        .map((e) => MediaCategoryRef(id: e.key, name: e.value))
        .toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  void _validateCategorySelection(List<MediaCategoryRef> categories) {
    if (_selectedCategoryId == null) return;
    final exists = categories.any((c) => c.id == _selectedCategoryId);
    if (!exists) _selectedCategoryId = null;
  }

  void _onInitialize(
    Screen16OnlineDesignsInitialEvent event,
    Emitter<Screen16OnlineDesignsState> emit,
  ) {
    emit(
      state.copyWith(
        searchController: TextEditingController(),
        isLoading: true,
        errorMessage: null,
      ),
    );
    add(Screen16OnlineDesignsLoadEvent());
  }

  Future<void> _onLoad(
    Screen16OnlineDesignsLoadEvent event,
    Emitter<Screen16OnlineDesignsState> emit,
  ) async {
    final generation = ++_loadGeneration;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      if (!PrefUtils().isLoggedIn()) {
        _allDesigns = [];
        _selectedCategoryId = null;
        if (generation != _loadGeneration) return;
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Please sign in to view online designs.',
            selectedCategoryId: null,
            categoryOptions: const [],
            screen16OnlineDesignsModelObj:
                (state.screen16OnlineDesignsModelObj ??
                        Screen16OnlineDesignsModel())
                    .copyWith(
                      rectanglelistsectionItemList: _fallbackRectangle,
                      listsectionItemList: _fallbackList,
                      featuredImageUrls: const [],
                      featuredTiles: const [],
                      forYouGroupedSections: const [],
                    ),
          ),
        );
        return;
      }

      final result = await _adminDesigns.list(
        perPage: 50,
        sort: 'latest',
        visibility: 'public',
      );
      if (generation != _loadGeneration) return;

      if (result is AdminDesignListFailure) {
        _allDesigns = [];
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: result.message,
            selectedCategoryId: null,
            categoryOptions: const [],
            screen16OnlineDesignsModelObj:
                (state.screen16OnlineDesignsModelObj ??
                        Screen16OnlineDesignsModel())
                    .copyWith(
                      rectanglelistsectionItemList: _fallbackRectangle,
                      listsectionItemList: _fallbackList,
                      featuredImageUrls: const [],
                      featuredTiles: const [],
                      forYouGroupedSections: const [],
                    ),
          ),
        );
        return;
      }
      // Online Designs is a public catalog — never show private saves.
      _allDesigns = (result as AdminDesignListSuccess).items
          .where((e) => !e.isPrivateDesign)
          .toList();
      final categories = _distinctCategories(_allDesigns);
      _validateCategorySelection(categories);
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: null,
          categoryOptions: categories,
          selectedCategoryId: _selectedCategoryId,
          screen16OnlineDesignsModelObj: _mapDesignsToModel(
            _allDesigns,
            _searchQuery,
            _selectedCategoryId,
          ),
        ),
      );
    } catch (_) {
      if (generation != _loadGeneration) return;
      emit(
        state.copyWith(isLoading: false, errorMessage: 'Something went wrong'),
      );
    }
  }

  void _onSearchChanged(
    Screen16OnlineDesignsSearchChangedEvent event,
    Emitter<Screen16OnlineDesignsState> emit,
  ) {
    _searchQuery = event.query;
    if (_allDesigns.isEmpty) return;
    emit(
      state.copyWith(
        screen16OnlineDesignsModelObj: _mapDesignsToModel(
          _allDesigns,
          _searchQuery,
          _selectedCategoryId,
        ),
      ),
    );
  }

  void _onCategoryChanged(
    Screen16OnlineDesignsCategoryChangedEvent event,
    Emitter<Screen16OnlineDesignsState> emit,
  ) {
    _selectedCategoryId = event.categoryId;
    if (_allDesigns.isEmpty) {
      emit(state.copyWith(selectedCategoryId: _selectedCategoryId));
      return;
    }
    emit(
      state.copyWith(
        selectedCategoryId: _selectedCategoryId,
        screen16OnlineDesignsModelObj: _mapDesignsToModel(
          _allDesigns,
          _searchQuery,
          _selectedCategoryId,
        ),
      ),
    );
  }

  static const int _uncategorizedBucketId = -1;

  String _headingForCategoryBucket(int bucketId, List<MediaItem> bucket) {
    if (bucketId == _uncategorizedBucketId) {
      return 'lbl_uncategorized'.tr;
    }
    for (final e in bucket) {
      final n = e.category?.name;
      if (n != null && n.isNotEmpty) return n;
    }
    return 'Category $bucketId';
  }

  RectanglelistsectionItemModel _rectTileFrom(MediaItem m) {
    return RectanglelistsectionItemModel(
      rectangle: m.fileUrl,
      id: m.id.toString(),
      name: m.name,
      isFeatured: m.isFeatured == true,
      tier: m.tier,
      previewDetails: m.formatOnlineDesignPreviewDetails(),
      categoryName: m.category?.name,
      downloadsCount: m.downloadsCount,
      trendingScore: m.trendingScore,
      designDataRaw: m.designDataRaw,
      width: m.width,
      height: m.height,
    );
  }

  ListsectionItemModel _listTileFrom(MediaItem m) {
    return ListsectionItemModel(
      rectangle: m.fileUrl,
      id: m.id.toString(),
      name: m.name,
      isFeatured: m.isFeatured == true,
      tier: m.tier,
      previewDetails: m.formatOnlineDesignPreviewDetails(),
      categoryName: m.category?.name,
      downloadsCount: m.downloadsCount,
      trendingScore: m.trendingScore,
      designDataRaw: m.designDataRaw,
      width: m.width,
      height: m.height,
    );
  }

  Screen16OnlineDesignsModel _mapDesignsToModel(
    List<MediaItem> items,
    String query,
    int? categoryId,
  ) {
    int? resolvedId(MediaItem e) => e.category?.id ?? e.categoryId;

    final afterCategory = categoryId == null
        ? items
        : items.where((e) => resolvedId(e) == categoryId).toList();

    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? afterCategory
        : afterCategory.where((e) {
            final name = e.name.toLowerCase();
            final tags = (e.tags ?? '').toLowerCase();
            return name.contains(q) || tags.contains(q);
          }).toList();

    final featuredTiles = filtered.take(3).map(_rectTileFrom).toList();
    final featured = featuredTiles
        .map((e) => e.rectangle ?? '')
        .where((u) => u.isNotEmpty)
        .toList();

    final apiEmpty = items.isEmpty;
    final searchNoMatch =
        afterCategory.isNotEmpty && filtered.isEmpty && q.isNotEmpty;
    final categoryNoMatch =
        categoryId != null && afterCategory.isEmpty && !apiEmpty;

    if (categoryId == null) {
      final buckets = <int, List<MediaItem>>{};
      for (final e in filtered) {
        final bid = resolvedId(e) ?? _uncategorizedBucketId;
        buckets.putIfAbsent(bid, () => <MediaItem>[]).add(e);
      }
      final groupEntries = buckets.entries.toList();
      groupEntries.sort((a, b) {
        final ah = _headingForCategoryBucket(a.key, a.value).toLowerCase();
        final bh = _headingForCategoryBucket(b.key, b.value).toLowerCase();
        return ah.compareTo(bh);
      });
      final grouped = <CategoryDesignGroupModel>[];
      for (final e in groupEntries) {
        final items = e.value.map(_rectTileFrom).toList();
        grouped.add(
          CategoryDesignGroupModel(
            categoryHeading: _headingForCategoryBucket(e.key, e.value),
            categoryId: e.key,
            items: items,
          ),
        );
      }

      return (state.screen16OnlineDesignsModelObj ??
              Screen16OnlineDesignsModel())
          .copyWith(
            featuredImageUrls: featured,
            featuredTiles: searchNoMatch ? const [] : featuredTiles,
            forYouGroupedSections: searchNoMatch ? const [] : grouped,
            rectanglelistsectionItemList: const [],
            listsectionItemList: const [],
          );
    }

    final first = filtered.take(24).toList();
    final a = first.take(12).map(_rectTileFrom).toList();
    final b = first.skip(12).take(12).map(_listTileFrom).toList();

    return (state.screen16OnlineDesignsModelObj ?? Screen16OnlineDesignsModel())
        .copyWith(
          featuredImageUrls: featured,
          featuredTiles: searchNoMatch || categoryNoMatch
              ? const []
              : featuredTiles,
          forYouGroupedSections: const [],
          rectanglelistsectionItemList: searchNoMatch || categoryNoMatch
              ? const []
              : (a.isEmpty && apiEmpty ? _fallbackRectangle : a),
          listsectionItemList: searchNoMatch || categoryNoMatch
              ? const []
              : (b.isEmpty && apiEmpty ? _fallbackList : b),
        );
  }
}
