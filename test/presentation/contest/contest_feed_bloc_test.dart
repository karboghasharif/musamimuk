import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/data/models/contest_submission.dart';
import 'package:musamimuk/data/repositories/contest_repository.dart';
import 'package:musamimuk/presentation/contest/bloc/contest_feed_bloc.dart';
import 'package:musamimuk/presentation/contest/contest_feed_social_access.dart';

void main() {
  late List<RequestOptions> captured;

  ContestSubmission sample({
    int id = 1,
    bool liked = false,
    int likes = 5,
    int shares = 1,
    int views = 10,
  }) {
    return ContestSubmission(
      id: id,
      contestId: 2,
      likesCount: likes,
      sharesCount: shares,
      viewsCount: views,
      isLiked: liked,
      comments: 'Hello',
      submitterName: 'Designer',
      contestTitle: 'Contest',
      designSummary: const ContestSubmissionDesignSummary(
        id: 10,
        fileUrl: 'https://cdn.example/a.png',
      ),
    );
  }

  ContestRepository repoWith(Map<String, dynamic> body, {int status = 200}) {
    return ContestRepository(
      dio: _scriptedDio(
        onRequest: (options) {
          captured.add(options);
          if (status >= 400) {
            throw DioException(
              requestOptions: options,
              response: Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: status,
                data: body,
              ),
              type: DioExceptionType.badResponse,
            );
          }
          return body;
        },
      ),
    );
  }

  setUp(() {
    captured = [];
    ContestRepository.resetInstanceForTest();
  });

  tearDown(ContestRepository.resetInstanceForTest);

  test('resolveContestFeedSocialAccess covers login and guest upgrade', () {
    expect(
      resolveContestFeedSocialAccess(isLoggedIn: false, isGuestAccount: false),
      ContestFeedSocialAccess.loginRequired,
    );
    expect(
      resolveContestFeedSocialAccess(isLoggedIn: true, isGuestAccount: true),
      ContestFeedSocialAccess.upgradeRequired,
    );
    expect(
      resolveContestFeedSocialAccess(isLoggedIn: true, isGuestAccount: false),
      ContestFeedSocialAccess.allowed,
    );
  });

  test('loads first page anonymously from public feed', () async {
    final repo = repoWith({
      'success': true,
      'data': [
        {
          'id': 1,
          'contest_id': 2,
          'likes_count': 5,
          'views_count': 10,
          'shares_count': 1,
          'comments': 'Hello',
          'design': {'id': 10, 'file_url': 'https://cdn.example/a.png'},
          'user': {'id': 4, 'name': 'Designer'},
          'contest': {'id': 2, 'name': 'Contest'},
        },
      ],
      'meta': {'current_page': 1, 'next_page': 2, 'per_page': 20, 'total': 40},
    });
    final bloc = ContestFeedBloc(const ContestFeedState(), repository: repo);
    bloc.add(const ContestFeedInitialEvent());
    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<ContestFeedState>(
          (s) =>
              !s.isLoading && s.items.length == 1 && s.hasMore && s.page == 2,
        ),
      ),
    );
    expect(captured.single.path, 'public/contests/submissions/feed');
    expect(captured.single.headers['Authorization'], isNull);
    await bloc.close();
  });

  test('load more appends next page', () async {
    var pageHits = 0;
    final repo = ContestRepository(
      dio: _scriptedDio(
        onRequest: (options) {
          captured.add(options);
          pageHits++;
          if (pageHits == 1) {
            return {
              'success': true,
              'data': [
                {
                  'id': 1,
                  'contest_id': 2,
                  'likes_count': 1,
                  'design': {'id': 10, 'file_url': 'https://cdn.example/a.png'},
                },
              ],
              'meta': {
                'current_page': 1,
                'next_page': 2,
                'per_page': 20,
                'total': 2,
              },
            };
          }
          return {
            'success': true,
            'data': [
              {
                'id': 2,
                'contest_id': 2,
                'likes_count': 2,
                'design': {'id': 11, 'file_url': 'https://cdn.example/b.png'},
              },
            ],
            'meta': {
              'current_page': 2,
              'next_page': null,
              'per_page': 20,
              'total': 2,
            },
          };
        },
      ),
    );
    final bloc = ContestFeedBloc(const ContestFeedState(), repository: repo);
    bloc.add(const ContestFeedInitialEvent());
    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<ContestFeedState>((s) => !s.isLoading && s.items.length == 1),
      ),
    );
    bloc.add(const ContestFeedLoadMoreEvent());
    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<ContestFeedState>(
          (s) =>
              !s.isLoadingMore &&
              s.items.map((e) => e.id).toList().toString() == '[1, 2]' &&
              s.hasMore == false,
        ),
      ),
    );
    expect(captured.last.queryParameters['page'], '2');
    await bloc.close();
  });

  test('optimistic like rolls back on 429', () async {
    final repo = repoWith({
      'success': false,
      'message': 'Too many requests',
    }, status: 429);
    final bloc = ContestFeedBloc(
      ContestFeedState(items: [sample()]),
      repository: repo,
    );
    final states = <ContestFeedState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(const ContestFeedToggleLikeEvent(1));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();

    expect(states.any((s) => s.items.single.isLiked == true), isTrue);
    final last = states.last;
    expect(last.items.single.isLiked, isFalse);
    expect(last.items.single.likesCount, 5);
    expect(last.errorMessage, isNotNull);
    expect(last.errorMessage!.toLowerCase(), isNot(contains('dioexception')));
    await bloc.close();
  });

  test('successful like syncs counters from API', () async {
    final repo = repoWith({
      'success': true,
      'data': {
        'submission_id': 1,
        'liked': true,
        'likes_count': 9,
        'views_count': 12,
        'shares_count': 3,
      },
    });
    final bloc = ContestFeedBloc(
      ContestFeedState(items: [sample(likes: 5, liked: false)]),
      repository: repo,
    );
    bloc.add(const ContestFeedToggleLikeEvent(1));
    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<ContestFeedState>(
          (s) =>
              s.items.single.isLiked == true &&
              s.items.single.likesCount == 9 &&
              s.items.single.viewsCount == 12 &&
              s.items.single.sharesCount == 3 &&
              !s.likingIds.contains(1),
        ),
      ),
    );
    await bloc.close();
  });

  test('share records backend first and exposes share_url', () async {
    final repo = repoWith({
      'success': true,
      'data': {
        'submission_id': 1,
        'liked': false,
        'likes_count': 5,
        'shares_count': 4,
        'share_url': 'https://example.test/share/1',
      },
    });
    final bloc = ContestFeedBloc(
      ContestFeedState(items: [sample(shares: 1)]),
      repository: repo,
    );
    bloc.add(const ContestFeedShareEvent(submissionId: 1));
    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<ContestFeedState>(
          (s) =>
              s.pendingShareUrl == 'https://example.test/share/1' &&
              s.items.single.sharesCount == 4 &&
              !s.sharingIds.contains(1),
        ),
      ),
    );
    expect(captured.single.path, 'contests/submissions/1/share');
    await bloc.close();
  });

  test('sort change reloads with likes filter', () async {
    final repo = repoWith({
      'success': true,
      'data': <dynamic>[],
      'meta': {
        'current_page': 1,
        'next_page': null,
        'per_page': 20,
        'total': 0,
      },
    });
    final bloc = ContestFeedBloc(const ContestFeedState(), repository: repo);
    bloc.add(const ContestFeedSortChangedEvent('likes'));
    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<ContestFeedState>(
          (s) =>
              s.sort == 'likes' &&
              !s.isLoading &&
              captured.isNotEmpty &&
              captured.last.queryParameters['sort'] == 'likes',
        ),
      ),
    );
    await bloc.close();
  });

  test('404 like removes unavailable submission', () async {
    final repo = ContestRepository(
      dio: _scriptedDio(
        onRequest: (options) {
          captured.add(options);
          throw DioException(
            requestOptions: options,
            response: Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 404,
              data: {'success': false, 'message': 'Missing'},
            ),
            type: DioExceptionType.badResponse,
          );
        },
      ),
    );
    final bloc = ContestFeedBloc(
      ContestFeedState(items: [sample(), sample(id: 2)]),
      repository: repo,
    );
    bloc.add(const ContestFeedToggleLikeEvent(1));
    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<ContestFeedState>(
          (s) =>
              s.items.map((e) => e.id).toList().toString() == '[2]' &&
              !s.likingIds.contains(1),
        ),
      ),
    );
    await bloc.close();
  });

  test('record view uses interact endpoint once', () async {
    final repo = repoWith({
      'success': true,
      'data': {
        'submission_id': 1,
        'liked': false,
        'views_count': 11,
        'likes_count': 5,
        'shares_count': 1,
      },
    });
    final bloc = ContestFeedBloc(
      ContestFeedState(items: [sample(views: 10)]),
      repository: repo,
    );
    bloc.add(const ContestFeedRecordViewEvent(1));
    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<ContestFeedState>(
          (s) => s.viewedIds.contains(1) && s.items.single.viewsCount == 11,
        ),
      ),
    );
    bloc.add(const ContestFeedRecordViewEvent(1));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(captured.where((o) => o.path.contains('/interact')).length, 1);
    await bloc.close();
  });
}

Dio _scriptedDio({
  required Map<String, dynamic> Function(RequestOptions options) onRequest,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        try {
          final body = onRequest(options);
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: body,
            ),
          );
        } on DioException catch (e) {
          handler.reject(e);
        }
      },
    ),
  );
  return dio;
}
