import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../network/api_utils.dart';

/// Share helpers for contest submission feed items.
class ContestFeedShare {
  ContestFeedShare._();

  static String shareUrl({
    required int contestId,
    required int submissionId,
  }) {
    final origin = apiSiteOrigin();
    return '$origin/contests/$contestId/submissions/$submissionId';
  }

  static String shareMessage({
    required String contestTitle,
    required String submitterName,
    required String url,
  }) {
    return 'Check out this design by $submitterName in "$contestTitle" on Musamimuk.\n$url';
  }

  static Future<void> shareNative({
    required String message,
    String? subject,
  }) async {
    await Share.share(message, subject: subject);
  }

  static Future<void> copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
  }
}
