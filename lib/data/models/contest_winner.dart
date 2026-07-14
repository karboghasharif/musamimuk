import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/media_item.dart';

/// Winner row from `GET /public/contests/{id}/winners`.
class ContestWinner {
  const ContestWinner({
    required this.position,
    this.prizeAmount,
    this.prizeCurrency,
    this.prizeLabel,
    this.winnerName,
    this.design,
    this.submissionId,
    this.thumbnailUrl,
  });

  final int position;
  final double? prizeAmount;
  final String? prizeCurrency;
  final String? prizeLabel;
  final String? winnerName;
  final MediaItem? design;
  final int? submissionId;
  final String? thumbnailUrl;

  String get imageUrl {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) return thumbnailUrl!;
    return design?.fileUrl ?? '';
  }

  String prizeDisplay() {
    if (prizeLabel != null && prizeLabel!.trim().isNotEmpty) {
      return prizeLabel!.trim();
    }
    if (prizeAmount != null) {
      final cur = (prizeCurrency ?? '').trim();
      final v = prizeAmount! == prizeAmount!.roundToDouble()
          ? prizeAmount!.toInt().toString()
          : prizeAmount.toString();
      return cur.isEmpty ? v : '$cur $v';
    }
    return '';
  }

  factory ContestWinner.fromJson(Map<String, dynamic> json) {
    final submissionRaw = json['submission'];
    final submission = submissionRaw is Map
        ? submissionRaw.cast<String, dynamic>()
        : null;
    final designRaw =
        json['design'] ?? submission?['design'] ?? submission;
    MediaItem? design;
    if (designRaw is Map) {
      design = MediaItem.fromJson(designRaw.cast<String, dynamic>());
    }
    final userRaw = json['user'] ?? submission?['user'];
    final amountRaw = json['prize_amount'] ?? json['prize']?['amount'];
    double? amount;
    if (amountRaw is num) {
      amount = amountRaw.toDouble();
    } else if (amountRaw != null) {
      amount = double.tryParse(amountRaw.toString());
    }
    return ContestWinner(
      position: apiParseInt(
        json['position'] ?? submission?['position'] ?? json['rank'],
        fallback: 0,
      ),
      prizeAmount: amount,
      prizeCurrency:
          json['prize_currency']?.toString() ?? json['prize']?['currency']?.toString(),
      prizeLabel: json['prize_label']?.toString() ?? json['prize']?['label']?.toString(),
      winnerName: json['winner_name']?.toString() ??
          (userRaw is Map
              ? userRaw['name']?.toString()
              : json['submitter_name']?.toString()),
      design: design,
      submissionId: json['submission_id'] == null
          ? (submission?['id'] == null
              ? null
              : apiParseInt(submission!['id']))
          : apiParseInt(json['submission_id']),
      thumbnailUrl: json['thumbnail_url']?.toString() ??
          submission?['thumbnail_url']?.toString(),
    );
  }
}
