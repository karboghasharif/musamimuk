part of 'screen_16_online_designs_bloc.dart';

class Screen16OnlineDesignsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class Screen16OnlineDesignsInitialEvent extends Screen16OnlineDesignsEvent {
  @override
  List<Object?> get props => [];
}

class Screen16OnlineDesignsLoadEvent extends Screen16OnlineDesignsEvent {
  @override
  List<Object?> get props => [];
}

class Screen16OnlineDesignsSearchChangedEvent extends Screen16OnlineDesignsEvent {
  Screen16OnlineDesignsSearchChangedEvent(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

/// [categoryId] is `null` to show all categories.
class Screen16OnlineDesignsCategoryChangedEvent extends Screen16OnlineDesignsEvent {
  Screen16OnlineDesignsCategoryChangedEvent(this.categoryId);
  final int? categoryId;
  @override
  List<Object?> get props => [categoryId];
}
