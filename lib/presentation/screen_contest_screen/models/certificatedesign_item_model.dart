
import '../../../data/models/contest_countdown.dart';

class CertificatedesignItemModel {
  CertificatedesignItemModel({
    this.certificateText,
    this.designsText,
    this.image,
    this.id,
    this.contestJson,
    this.showResultAnnounced = false,
    this.status,
    this.countdown,
    this.prizeText,
    this.participantsCount,
    this.submissionsCount,
    this.categoryName,
    this.dateRange,
    this.primaryAction,
    this.hasJoined = false,
  });

  String? certificateText;
  String? designsText;
  String? image;
  String? id;
  Map<String, dynamic>? contestJson;
  bool showResultAnnounced;
  String? status;
  ContestCountdown? countdown;
  String? prizeText;
  int? participantsCount;
  int? submissionsCount;
  String? categoryName;
  String? dateRange;
  String? primaryAction;
  bool hasJoined;
}
