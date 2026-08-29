part of 'screen_18_my_designs_bloc.dart';

enum MyDesignsVisibilityTab { public, private, local }

class Screen18MyDesignsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class Screen18MyDesignsInitialEvent extends Screen18MyDesignsEvent {
  @override
  List<Object?> get props => [];
}

class Screen18MyDesignsLoadEvent extends Screen18MyDesignsEvent {
  @override
  List<Object?> get props => [];
}

class Screen18MyDesignsSearchChangedEvent extends Screen18MyDesignsEvent {
  Screen18MyDesignsSearchChangedEvent(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

class Screen18MyDesignsVisibilityTabChangedEvent
    extends Screen18MyDesignsEvent {
  Screen18MyDesignsVisibilityTabChangedEvent(this.tab);
  final MyDesignsVisibilityTab tab;
  @override
  List<Object?> get props => [tab];
}

class Screen18MyDesignsDeleteEvent extends Screen18MyDesignsEvent {
  Screen18MyDesignsDeleteEvent(this.designId);
  final int designId;
  @override
  List<Object?> get props => [designId];
}

class Screen18MyDesignsDeleteLocalEvent extends Screen18MyDesignsEvent {
  Screen18MyDesignsDeleteLocalEvent(this.localId);
  final String localId;
  @override
  List<Object?> get props => [localId];
}
