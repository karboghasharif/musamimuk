part of 'screen_contest_bloc.dart';

class ScreenContestEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ScreenContestInitialEvent extends ScreenContestEvent {}

class ScreenContestLoadEvent extends ScreenContestEvent {
  ScreenContestLoadEvent({
    this.forceRefresh = false,
    this.loadMore = false,
  });
  final bool forceRefresh;
  final bool loadMore;
  @override
  List<Object?> get props => [forceRefresh, loadMore];
}

class ScreenContestFilterEvent extends ScreenContestEvent {
  ScreenContestFilterEvent({
    this.categoryId,
    this.updateCategory = false,
    this.status,
    this.updateStatus = false,
    this.search,
  });
  final int? categoryId;
  final bool updateCategory;
  final String? status;
  final bool updateStatus;
  final String? search;
  @override
  List<Object?> get props => [categoryId, updateCategory, status, updateStatus, search];
}
