import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../../../data/models/media_item.dart';
import '../../../data/repositories/design_repository.dart';
import '../../../data/repositories/media_repository.dart';
import '../../../data/services/local_design_store.dart';
import '../models/playlist_item_model.dart';
import '../models/screen_18_my_designs_model.dart';
part 'screen_18_my_designs_event.dart';
part 'screen_18_my_designs_state.dart';

class Screen18MyDesignsBloc
    extends Bloc<Screen18MyDesignsEvent, Screen18MyDesignsState> {
  Screen18MyDesignsBloc(super.initialState)
    : _repo = MediaRepository(type: MediaType.design),
      _designRepo = DesignRepository() {
    on<Screen18MyDesignsInitialEvent>(_onInitialize);
    on<Screen18MyDesignsLoadEvent>(_onLoad);
    on<Screen18MyDesignsSearchChangedEvent>(_onSearchChanged);
    on<Screen18MyDesignsVisibilityTabChangedEvent>(_onVisibilityTabChanged);
    on<Screen18MyDesignsDeleteEvent>(_onDelete);
    on<Screen18MyDesignsDeleteLocalEvent>(_onDeleteLocal);
  }
  final MediaRepository _repo;
  final DesignRepository _designRepo;

  /// Full library from last successful load (before search / tab filter).
  List<PlaylistItemModel> _allPlaylistCache = const [];
  List<PlaylistItemModel> _localPlaylistCache = const [];

  String _searchQuery = '';
  int _loadGeneration = 0;

  static final _fallback = <PlaylistItemModel>[
    PlaylistItemModel(
      image: ImageConstant.imgRectangle5591106x115,
      text1: "Untitled",
      text2: "Oct 14, 2023, 6:33 PM",
      isPrivate: false,
    ),
    PlaylistItemModel(
      image: ImageConstant.imgRectangle5592,
      text1: "square 1 1",
      text2: "Oct 13, 2023, 1:14 PM",
      isPrivate: true,
    ),
    PlaylistItemModel(
      image: ImageConstant.imgRectangle5593,
      text1: "square 1 3",
      text2: "Oct 13, 2023, 12:54 PM",
      isPrivate: false,
    ),
  ];

  void _onInitialize(
    Screen18MyDesignsInitialEvent event,
    Emitter<Screen18MyDesignsState> emit,
  ) {
    emit(state.copyWith(
      searchController: TextEditingController(),
      isLoading: true,
      errorMessage: null,
      clearDeleteFeedback: true,
    ));
    add(Screen18MyDesignsLoadEvent());
  }

  Future<void> _onLoad(
    Screen18MyDesignsLoadEvent event,
    Emitter<Screen18MyDesignsState> emit,
  ) async {
    final generation = ++_loadGeneration;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    // Always refresh local drafts (works offline / as guest).
    await _reloadLocalDrafts();

    if (state.visibilityTab == MyDesignsVisibilityTab.local) {
      if (generation != _loadGeneration) return;
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: null,
          screen18MyDesignsModelObj:
              (state.screen18MyDesignsModelObj ?? Screen18MyDesignsModel())
                  .copyWith(playlistItemList: _playlistForCurrentFilters()),
        ),
      );
      return;
    }

    try {
      if (!PrefUtils().isLoggedIn()) {
        _allPlaylistCache = const [];
        if (generation != _loadGeneration) return;
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Please sign in to see your designs.',
            screen18MyDesignsModelObj:
                (state.screen18MyDesignsModelObj ?? Screen18MyDesignsModel())
                    .copyWith(playlistItemList: const []),
          ),
        );
        return;
      }

      final result = await _repo.list();
      if (generation != _loadGeneration) return;

      if (result is MediaFailure) {
        _allPlaylistCache = const [];
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: result.message,
            screen18MyDesignsModelObj:
                (state.screen18MyDesignsModelObj ?? Screen18MyDesignsModel())
                    .copyWith(playlistItemList: _fallback),
          ),
        );
        return;
      }
      final list = (result as MediaSuccess).items ?? const <MediaItem>[];
      final session = PrefUtils().getUserSession();
      final myUserId = session == null
          ? null
          : int.tryParse(session['id']?.toString() ?? '');
      // `design/list` returns the signed-in user's library (public + private).
      final mine = myUserId == null
          ? list
          : list
              .where((e) => e.userId == null || e.userId == myUserId)
              .toList();

      final mapped = mine
          .map(
            (e) => PlaylistItemModel(
              image: e.fileUrl,
              text1: e.name,
              text2: _formatDesignDate(e.createdAt),
              id: e.id.toString(),
              isPrivate: e.isPrivateDesign,
              visibility: e.visibility,
              designDataRaw: e.designDataRaw,
              width: e.width,
              height: e.height,
            ),
          )
          .toList();

      _allPlaylistCache = List<PlaylistItemModel>.from(mapped);

      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: null,
          screen18MyDesignsModelObj:
              (state.screen18MyDesignsModelObj ?? Screen18MyDesignsModel())
                  .copyWith(playlistItemList: _playlistForCurrentFilters()),
        ),
      );
    } catch (_) {
      if (generation != _loadGeneration) return;
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Something went wrong',
        ),
      );
    }
  }

  Future<void> _reloadLocalDrafts() async {
    final drafts = await LocalDesignStore.instance.listDrafts();
    _localPlaylistCache = drafts
        .map(
          (d) => PlaylistItemModel(
            image: d.thumbnailPath == null || d.thumbnailPath!.isEmpty
                ? null
                : (d.thumbnailPath!.startsWith('file://')
                    ? d.thumbnailPath
                    : 'file://${d.thumbnailPath}'),
            text1: d.name,
            text2: _formatDesignDate(d.updatedAt.toIso8601String()),
            id: d.id,
            isPrivate: true,
            designDataRaw: d.historyJson,
            width: d.width.round(),
            height: d.height.round(),
            isLocal: true,
          ),
        )
        .toList(growable: false);
  }

  void _onSearchChanged(
    Screen18MyDesignsSearchChangedEvent event,
    Emitter<Screen18MyDesignsState> emit,
  ) {
    _searchQuery = event.query;
    emit(
      state.copyWith(
        screen18MyDesignsModelObj:
            (state.screen18MyDesignsModelObj ?? Screen18MyDesignsModel())
                .copyWith(playlistItemList: _playlistForCurrentFilters()),
      ),
    );
  }

  Future<void> _onVisibilityTabChanged(
    Screen18MyDesignsVisibilityTabChangedEvent event,
    Emitter<Screen18MyDesignsState> emit,
  ) async {
    emit(state.copyWith(visibilityTab: event.tab, isLoading: true));
    if (event.tab == MyDesignsVisibilityTab.local) {
      await _reloadLocalDrafts();
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: null,
          screen18MyDesignsModelObj:
              (state.screen18MyDesignsModelObj ?? Screen18MyDesignsModel())
                  .copyWith(
            playlistItemList: _playlistForCurrentFilters(tab: event.tab),
          ),
        ),
      );
      return;
    }
    add(Screen18MyDesignsLoadEvent());
  }

  Future<void> _onDeleteLocal(
    Screen18MyDesignsDeleteLocalEvent event,
    Emitter<Screen18MyDesignsState> emit,
  ) async {
    await LocalDesignStore.instance.deleteDraft(event.localId);
    await _reloadLocalDrafts();
    emit(
      state.copyWith(
        deleteFeedback: 'msg_local_design_deleted'.tr,
        screen18MyDesignsModelObj:
            (state.screen18MyDesignsModelObj ?? Screen18MyDesignsModel())
                .copyWith(playlistItemList: _playlistForCurrentFilters()),
      ),
    );
  }

  Future<void> _onDelete(
    Screen18MyDesignsDeleteEvent event,
    Emitter<Screen18MyDesignsState> emit,
  ) async {
    if (state.deletingDesignId != null) return;
    emit(
      state.copyWith(
        deletingDesignId: event.designId,
        clearDeleteFeedback: true,
      ),
    );

    final result = await _designRepo.delete(event.designId);
    if (result is DesignActionFailure) {
      emit(
        state.copyWith(
          clearDeletingDesignId: true,
          deleteFeedback: result.message,
        ),
      );
      return;
    }

    _allPlaylistCache = _allPlaylistCache
        .where((e) => e.id != event.designId.toString())
        .toList(growable: false);

    emit(
      state.copyWith(
        clearDeletingDesignId: true,
        deleteFeedback: 'msg_design_deleted'.tr,
        screen18MyDesignsModelObj:
            (state.screen18MyDesignsModelObj ?? Screen18MyDesignsModel())
                .copyWith(playlistItemList: _playlistForCurrentFilters()),
      ),
    );
  }

  List<PlaylistItemModel> _playlistForCurrentFilters({
    MyDesignsVisibilityTab? tab,
  }) {
    final activeTab = tab ?? state.visibilityTab;
    final source = switch (activeTab) {
      MyDesignsVisibilityTab.local => _localPlaylistCache,
      MyDesignsVisibilityTab.public =>
        _allPlaylistCache.where((e) => !e.isPrivate).toList(),
      MyDesignsVisibilityTab.private =>
        _allPlaylistCache.where((e) => e.isPrivate).toList(),
    };

    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((e) {
      final name = (e.text1 ?? '').toLowerCase();
      final date = (e.text2 ?? '').toLowerCase();
      return name.contains(q) || date.contains(q);
    }).toList();
  }

  static String _formatDesignDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final s = raw.trim();
    final t = s.indexOf('T');
    if (t > 0) return s.substring(0, t);
    return s;
  }
}
