import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/data/models/contest_submission.dart';
import 'package:musamimuk/data/repositories/contest_repository.dart';

void main() {
  group('ContestSubmission.fromJson', () {
    test('parses nested feed payload with comments and counters', () {
      final submission = ContestSubmission.fromJson({
        'id': 1,
        'contest_id': 2,
        'design_id': 10,
        'status': 'approved',
        'comments': 'My entry',
        'likes_count': 5,
        'views_count': 20,
        'shares_count': 2,
        'is_featured': false,
        'position': null,
        'created_at': '2026-07-19T10:00:00Z',
        'design': {
          'id': 10,
          'name': 'Design name',
          'file_url': 'https://cdn.example/design.png',
          'status': 'published',
          'is_active': true,
        },
        'user': {'id': 4, 'name': 'Designer'},
        'contest': {'id': 2, 'name': 'Contest name'},
      });

      expect(submission.id, 1);
      expect(submission.contestId, 2);
      expect(submission.designId, 10);
      expect(submission.comments, 'My entry');
      expect(submission.displayComments, 'My entry');
      expect(submission.likesCount, 5);
      expect(submission.viewsCount, 20);
      expect(submission.sharesCount, 2);
      expect(submission.isFeatured, isFalse);
      expect(submission.position, isNull);
      expect(submission.designerName, 'Designer');
      expect(submission.contestDisplayName, 'Contest name');
      expect(submission.imageUrl, 'https://cdn.example/design.png');
      expect(submission.designSummary?.name, 'Design name');
      expect(submission.userSummary?.id, 4);
      expect(submission.contestSummary?.id, 2);
    });

    test('handles nullable nested data safely', () {
      final submission = ContestSubmission.fromJson({
        'id': 9,
        'contest_id': 3,
        'design': null,
        'user': null,
        'contest': null,
        'likes_count': null,
        'views_count': null,
        'shares_count': null,
        'is_liked': null,
        'comments': null,
        'description': null,
      });

      expect(submission.id, 9);
      expect(submission.design, isNull);
      expect(submission.userSummary, isNull);
      expect(submission.contestSummary, isNull);
      expect(submission.likesCount, isNull);
      expect(submission.viewsCount, isNull);
      expect(submission.displayComments, isEmpty);
      expect(submission.imageUrl, isEmpty);
    });

    test('applyInteraction syncs counters from API', () {
      const base = ContestSubmission(
        id: 1,
        contestId: 2,
        likesCount: 5,
        viewsCount: 10,
        sharesCount: 1,
        isLiked: false,
      );
      final next = base.applyInteraction(
        const ContestInteractionState(
          submissionId: 1,
          liked: true,
          likesCount: 6,
          viewsCount: 11,
          sharesCount: 2,
          shareUrl: 'https://example.test/share/1',
        ),
      );
      expect(next.isLiked, isTrue);
      expect(next.likesCount, 6);
      expect(next.viewsCount, 11);
      expect(next.sharesCount, 2);
    });
  });

  group('ContestRepository feed and interactions', () {
    late List<RequestOptions> captured;

    setUp(() {
      captured = [];
      ContestRepository.resetInstanceForTest();
    });

    tearDown(ContestRepository.resetInstanceForTest);

    ContestRepository repoReturning(
      Map<String, dynamic> body, {
      int status = 200,
    }) {
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

    test('feed parses list + meta and sends filter query params', () async {
      final repo = repoReturning({
        'success': true,
        'message': 'Submissions loaded',
        'data': [
          {
            'id': 1,
            'contest_id': 2,
            'design_id': 10,
            'status': 'approved',
            'comments': 'My entry',
            'likes_count': 5,
            'views_count': 20,
            'shares_count': 2,
            'design': {
              'id': 10,
              'name': 'Design name',
              'file_url': 'https://cdn.example/a.png',
            },
            'user': {'id': 4, 'name': 'Designer'},
            'contest': {'id': 2, 'name': 'Contest name'},
          },
        ],
        'meta': {
          'current_page': 1,
          'next_page': 2,
          'previous_page': null,
          'per_page': 20,
          'limit': 20,
          'total': 50,
        },
      });

      final result = await repo.feedSubmissions(
        page: 1,
        perPage: 20,
        contestId: 2,
        featured: true,
        sort: 'likes',
      );

      expect(result, isA<ContestSubmissionsResult>());
      final success = result as ContestSubmissionsResult;
      expect(success.submissions, hasLength(1));
      expect(success.page?.hasMore, isTrue);
      expect(success.page?.nextPage, 2);
      expect(captured.single.path, 'public/contests/submissions/feed');
      expect(captured.single.queryParameters['sort'], 'likes');
      expect(captured.single.queryParameters['contest_id'], '2');
      expect(captured.single.queryParameters['featured'], '1');
      expect(captured.single.headers['Authorization'], isNull);
    });

    test('pagination loads additional pages via next_page', () async {
      final repo = repoReturning({
        'success': true,
        'data': [
          {
            'id': 2,
            'contest_id': 2,
            'likes_count': 1,
            'design': {'id': 11, 'file_url': 'https://cdn.example/b.png'},
          },
        ],
        'meta': {
          'current_page': 2,
          'next_page': null,
          'previous_page': 1,
          'per_page': 20,
          'total': 21,
        },
      });
      final result = await repo.feedSubmissions(page: 2, sort: 'recent');
      final success = result as ContestSubmissionsResult;
      expect(success.submissions.single.id, 2);
      expect(success.page?.hasMore, isFalse);
      expect(captured.single.queryParameters['page'], '2');
      expect(captured.single.queryParameters['sort'], 'recent');
    });

    test('like returns authoritative counters', () async {
      final repo = repoReturning({
        'success': true,
        'data': {
          'submission_id': 1,
          'liked': true,
          'views_count': 20,
          'likes_count': 6,
          'shares_count': 2,
        },
      });
      final result = await repo.likeSubmission(1);
      final ok = result as ContestInteractionResult;
      expect(ok.isLiked, isTrue);
      expect(ok.likesCount, 6);
      expect(ok.viewsCount, 20);
      expect(ok.sharesCount, 2);
      expect(captured.single.method, 'POST');
      expect(captured.single.path, 'contests/submissions/1/like');
    });

    test('unlike uses DELETE and liked=false', () async {
      final repo = repoReturning({
        'success': true,
        'data': {
          'submission_id': 1,
          'liked': false,
          'likes_count': 5,
          'views_count': 20,
          'shares_count': 2,
        },
      });
      final result = await repo.unlikeSubmission(1);
      final ok = result as ContestInteractionResult;
      expect(ok.isLiked, isFalse);
      expect(ok.likesCount, 5);
      expect(captured.single.method, 'DELETE');
    });

    test('share records channel/source and returns share_url', () async {
      final repo = repoReturning({
        'success': true,
        'data': {
          'submission_id': 1,
          'liked': false,
          'views_count': 20,
          'likes_count': 6,
          'shares_count': 3,
          'share_url': 'https://example.test/s/1',
        },
      });
      final result = await repo.recordSubmissionShare(
        1,
        channel: 'whatsapp',
        source: 'contest_feed',
      );
      final ok = result as ContestInteractionResult;
      expect(ok.shareUrl, 'https://example.test/s/1');
      expect(ok.sharesCount, 3);
      expect(captured.single.path, 'contests/submissions/1/share');
      expect(captured.single.data['channel'], 'whatsapp');
      expect(captured.single.data['source'], 'contest_feed');
    });

    test('interact view action posts expected body', () async {
      final repo = repoReturning({
        'success': true,
        'data': {
          'submission_id': 1,
          'liked': false,
          'views_count': 21,
          'likes_count': 5,
          'shares_count': 2,
        },
      });
      final result = await repo.interactSubmission(1, action: 'view');
      final ok = result as ContestInteractionResult;
      expect(ok.viewsCount, 21);
      expect(captured.single.path, 'contests/submissions/1/interact');
      expect(captured.single.data['action'], 'view');
    });

    test(
      '422 and 429 map to ContestFailure without DioException text',
      () async {
        for (final status in [422, 429]) {
          captured.clear();
          final repo = repoReturning({
            'success': false,
            'message': status == 422 ? 'Invalid action' : 'Slow down',
          }, status: status);
          final result = await repo.likeSubmission(1);
          expect(result, isA<ContestFailure>());
          final failure = result as ContestFailure;
          expect(failure.statusCode, status);
          expect(
            failure.message.toLowerCase(),
            isNot(contains('dioexception')),
          );
        }
      },
    );

    test('404 interact exposes statusCode for UI hide', () async {
      final repo = repoReturning({
        'success': false,
        'message': 'Gone',
      }, status: 404);
      final result = await repo.interactSubmission(99, action: 'view');
      expect(result, isA<ContestFailure>());
      expect((result as ContestFailure).statusCode, 404);
    });
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
