part of 'screen_18_my_designs_bloc.dart';

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
