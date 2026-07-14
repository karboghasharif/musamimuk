import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../../../data/models/contest_item.dart';
import '../../../data/models/media_item.dart';
import '../../../data/repositories/global_search_repository.dart';
import '../models/screen_17_search_bar_model.dart';
part 'screen_17_search_bar_event.dart';
part 'screen_17_search_bar_state.dart';

class Screen17SearchBarBloc
    extends Bloc<Screen17SearchBarEvent, Screen17SearchBarState> {
  Screen17SearchBarBloc(super.initialState)
      : _searchRepo = GlobalSearchRepository() {
    on<Screen17SearchBarInitialEvent>(_onInitialize);
    on<Screen17SearchBarQueryChangedEvent>(_onQueryChanged);
  }

  final GlobalSearchRepository _searchRepo;
  int _searchGeneration = 0;

  void _onInitialize(
    Screen17SearchBarInitialEvent event,
    Emitter<Screen17SearchBarState> emit,
  ) {
    emit(state.copyWith(
      searchController: TextEditingController(),
    ));
  }

  Future<void> _onQueryChanged(
    Screen17SearchBarQueryChangedEvent event,
    Emitter<Screen17SearchBarState> emit,
  ) async {
    final q = event.query.trim();
    if (q.length < 2) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: null,
        results: const [],
        contestResults: const [],
      ));
      return;
    }
    if (!PrefUtils().isLoggedIn()) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Please sign in to search.',
        results: const [],
        contestResults: const [],
      ));
      return;
    }

    final generation = ++_searchGeneration;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final res = await _searchRepo.search(query: q, limit: 20);
      if (generation != _searchGeneration) return;

      if (res is GlobalSearchApiFailure) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: res.message,
          results: const [],
          contestResults: const [],
        ));
        return;
      }
      final data = (res as GlobalSearchApiSuccess).result;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: null,
        results: data.designs,
        contestResults: data.contests,
      ));
    } catch (_) {
      if (generation != _searchGeneration) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong',
        results: const [],
        contestResults: const [],
      ));
    }
  }
}
