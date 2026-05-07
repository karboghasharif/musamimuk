part of 'screen_17_search_bar_bloc.dart';

class Screen17SearchBarEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class Screen17SearchBarInitialEvent extends Screen17SearchBarEvent {
  @override
  List<Object?> get props => [];
}

class Screen17SearchBarQueryChangedEvent extends Screen17SearchBarEvent {
  Screen17SearchBarQueryChangedEvent(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}
