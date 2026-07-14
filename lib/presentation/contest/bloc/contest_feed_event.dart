part of 'contest_feed_bloc.dart';

sealed class ContestFeedEvent extends Equatable {
  const ContestFeedEvent();

  @override
  List<Object?> get props => [];
}

class ContestFeedInitialEvent extends ContestFeedEvent {
  const ContestFeedInitialEvent();
}

class ContestFeedRefreshEvent extends ContestFeedEvent {
  const ContestFeedRefreshEvent();
}

class ContestFeedLoadMoreEvent extends ContestFeedEvent {
  const ContestFeedLoadMoreEvent();
}

class ContestFeedToggleLikeEvent extends ContestFeedEvent {
  const ContestFeedToggleLikeEvent(this.submissionId);

  final int submissionId;

  @override
  List<Object?> get props => [submissionId];
}

class ContestFeedShareRecordedEvent extends ContestFeedEvent {
  const ContestFeedShareRecordedEvent({
    required this.submissionId,
    this.sharesCount,
  });

  final int submissionId;
  final int? sharesCount;

  @override
  List<Object?> get props => [submissionId, sharesCount];
}
