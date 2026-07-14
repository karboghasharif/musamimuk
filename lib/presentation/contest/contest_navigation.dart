import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/navigator_service.dart';
import '../../../routes/app_routes.dart';
import '../screen_contesttwo_screen/models/contest_detail_args.dart';

/// Deep-link helper for contest-related notifications.
class ContestNavigation {
  ContestNavigation._();

  static void openContestDetail(int contestId) {
    NavigatorService.pushNamed(
      AppRoutes.screenContesttwoScreen,
      arguments: ContestDetailArgs(contestId: contestId),
    );
  }

  static void openContestFeed() {
    NavigatorService.pushNamed(AppRoutes.contestFeedScreen);
  }

  static void openFromNotificationData(Map<String, dynamic> data) {
    final contestId = _parseContestId(data);
    if (contestId == null || contestId <= 0) return;
    final action = data['action']?.toString().toLowerCase() ?? '';
    if (action.contains('winner')) {
      NavigatorService.pushNamed(
        AppRoutes.contestWinnersScreen,
        arguments: contestId,
      );
      return;
    }
    if (action.contains('gallery') || action.contains('submission')) {
      NavigatorService.pushNamed(
        AppRoutes.contestGalleryScreen,
        arguments: contestId,
      );
      return;
    }
    if (action.contains('my_submission') || action.contains('submission_status')) {
      NavigatorService.pushNamed(
        AppRoutes.contestMySubmissionsScreen,
        arguments: contestId,
      );
      return;
    }
    openContestDetail(contestId);
  }

  static int? _parseContestId(Map<String, dynamic> data) {
    final raw = data['contest_id'] ?? data['contestId'] ?? data['id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }
}
