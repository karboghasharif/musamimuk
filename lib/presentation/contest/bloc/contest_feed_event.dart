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

class ContestFeedSortChangedEvent extends ContestFeedEvent {
  const ContestFeedSortChangedEvent(this.sort);

  /// `recent` or `likes`
  final String sort;

  @override
  List<Object?> get props => [sort];
}

class ContestFeedFeaturedFilterEvent extends ContestFeedEvent {
  const ContestFeedFeaturedFilterEvent(this.featuredOnly);

  final bool featuredOnly;

  @override
  List<Object?> get props => [featuredOnly];
}

class ContestFeedToggleLikeEvent extends ContestFeedEvent {
  const ContestFeedToggleLikeEvent(this.submissionId);

  final int submissionId;

  @override
  List<Object?> get props => [submissionId];
}

class ContestFeedShareEvent extends ContestFeedEvent {
  const ContestFeedShareEvent({
    required this.submissionId,
    this.channel,
    this.source = 'contest_feed',
  });

  final int submissionId;
  final String? channel;
  final String source;

  @override
  List<Object?> get props => [submissionId, channel, source];
}

class ContestFeedRecordViewEvent extends ContestFeedEvent {
  const ContestFeedRecordViewEvent(this.submissionId);

  final int submissionId;

  @override
  List<Object?> get props => [submissionId];
}

class ContestFeedClearErrorEvent extends ContestFeedEvent {
  const ContestFeedClearErrorEvent();
}
