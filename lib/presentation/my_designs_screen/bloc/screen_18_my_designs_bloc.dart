import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../../../data/models/media_item.dart';
import '../../../data/repositories/media_repository.dart';
import '../models/playlist_item_model.dart';
import '../models/screen_18_my_designs_model.dart';
part 'screen_18_my_designs_event.dart';
part 'screen_18_my_designs_state.dart';

class Screen18MyDesignsBloc
    extends Bloc<Screen18MyDesignsEvent, Screen18MyDesignsState> {
  Screen18MyDesignsBloc(super.initialState)
    : _repo = MediaRepository(type: MediaType.design) {
    on<Screen18MyDesignsInitialEvent>(_onInitialize);
    on<Screen18MyDesignsLoadEvent>(_onLoad);
    on<Screen18MyDesignsSearchChangedEvent>(_onSearchChanged);
  }
  final MediaRepository _repo;

  /// Cached designs from the last successful load (before search filter).
  List<PlaylistItemModel> _privatePlaylistCache = const [];

  String _searchQuery = '';
  int _loadGeneration = 0;

  static final _fallback = <PlaylistItemModel>[
    PlaylistItemModel(
      image: ImageConstant.imgRectangle5591106x115,
      text1: "Untitled",
      text2: "Oct 14, 2023, 6:33 PM",
    ),
    PlaylistItemModel(
      image: ImageConstant.imgRectangle5592,
      text1: "square 1 1",
      text2: "Oct 13, 2023, 1:14 PM",
    ),
    PlaylistItemModel(
      image: ImageConstant.imgRectangle5593,
      text1: "square 1 3",
      text2: "Oct 13, 2023, 12:54 PM",
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
    ));
    add(Screen18MyDesignsLoadEvent());
  }

  Future<void> _onLoad(
    Screen18MyDesignsLoadEvent event,
    Emitter<Screen18MyDesignsState> emit,
  ) async {
    final generation = ++_loadGeneration;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      if (!PrefUtils().isLoggedIn()) {
        _privatePlaylistCache = const [];
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
        _privatePlaylistCache = const [];
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
          .take(30)
          .map(
            (e) => PlaylistItemModel(
              image: e.fileUrl,
              text1: e.name,
              text2: _formatDesignDate(e.createdAt),
              id: e.id.toString(),
            ),
          )
          .toList();

      _privatePlaylistCache = List<PlaylistItemModel>.from(mapped);

      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: null,
          screen18MyDesignsModelObj:
              (state.screen18MyDesignsModelObj ?? Screen18MyDesignsModel())
                  .copyWith(playlistItemList: _playlistAfterSearch()),
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

  void _onSearchChanged(
    Screen18MyDesignsSearchChangedEvent event,
    Emitter<Screen18MyDesignsState> emit,
  ) {
    _searchQuery = event.query;
    if (_privatePlaylistCache.isEmpty) return;
    emit(
      state.copyWith(
        screen18MyDesignsModelObj:
            (state.screen18MyDesignsModelObj ?? Screen18MyDesignsModel())
                .copyWith(playlistItemList: _playlistAfterSearch()),
      ),
    );
  }

  List<PlaylistItemModel> _playlistAfterSearch() {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return List<PlaylistItemModel>.from(_privatePlaylistCache);
    return _privatePlaylistCache.where((e) {
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
