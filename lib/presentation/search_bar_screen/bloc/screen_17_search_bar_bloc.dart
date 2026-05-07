import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../../../data/models/media_item.dart';
import '../../../data/repositories/design_interaction_repository.dart';
import '../models/screen_17_search_bar_model.dart';
part 'screen_17_search_bar_event.dart';
part 'screen_17_search_bar_state.dart';

class Screen17SearchBarBloc
    extends Bloc<Screen17SearchBarEvent, Screen17SearchBarState> {
  Screen17SearchBarBloc(super.initialState) {
    on<Screen17SearchBarInitialEvent>(_onInitialize);
    on<Screen17SearchBarQueryChangedEvent>(_onQueryChanged);
  }
  _onInitialize(
    Screen17SearchBarInitialEvent event,
    Emitter<Screen17SearchBarState> emit,
  ) async {
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
      emit(state.copyWith(isLoading: false, errorMessage: null, results: const []));
      return;
    }
    if (!PrefUtils().isLoggedIn()) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Please sign in to search designs.',
        results: const [],
      ));
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: null));
    final res = await DesignInteractionRepository().search(search: q, limit: 20);
    if (res is FavoriteDesignsFailure) {
      emit(state.copyWith(isLoading: false, errorMessage: res.message, results: const []));
      return;
    }
    emit(state.copyWith(
      isLoading: false,
      errorMessage: null,
      results: (res as FavoriteDesignsSuccess).items,
    ));
  }
}
