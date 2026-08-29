import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Share helpers for contest submission feed items.
///
/// Production share links must come from the backend `share_url` field.
class ContestFeedShare {
  ContestFeedShare._();

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
