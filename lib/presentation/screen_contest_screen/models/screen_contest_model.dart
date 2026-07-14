import 'package:equatable/equatable.dart';
import 'certificatedesign_item_model.dart';

class ScreenContestModel extends Equatable {
  const ScreenContestModel({
    this.openContestItemList = const [],
    this.closedContestItemList = const [],
    this.contestItemList = const [],
  });

  final List<CertificatedesignItemModel> openContestItemList;
  final List<CertificatedesignItemModel> closedContestItemList;
  final List<CertificatedesignItemModel> contestItemList;

  ScreenContestModel copyWith({
    List<CertificatedesignItemModel>? openContestItemList,
    List<CertificatedesignItemModel>? closedContestItemList,
    List<CertificatedesignItemModel>? contestItemList,
  }) {
    return ScreenContestModel(
      openContestItemList: openContestItemList ?? this.openContestItemList,
      closedContestItemList:
          closedContestItemList ?? this.closedContestItemList,
      contestItemList: contestItemList ?? this.contestItemList,
    );
  }

  @override
  List<Object?> get props =>
      [openContestItemList, closedContestItemList, contestItemList];
}
