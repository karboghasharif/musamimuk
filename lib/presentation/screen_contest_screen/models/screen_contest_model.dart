import 'package:equatable/equatable.dart';
import 'certificatedesign_item_model.dart';

/// This class defines the variables used in the [screen_contest_screen],/// and is typically used to hold data that is passed between different parts of the application.// ignore_for_file: must_be_immutable// ignore_for_file: must_be_immutable
class ScreenContestModel extends Equatable {
  const ScreenContestModel({
    this.openContestItemList = const [],
    this.closedContestItemList = const [],
  });
  final List<CertificatedesignItemModel> openContestItemList;
  final List<CertificatedesignItemModel> closedContestItemList;
  ScreenContestModel copyWith({
    List<CertificatedesignItemModel>? openContestItemList,
    List<CertificatedesignItemModel>? closedContestItemList,
  }) {
    return ScreenContestModel(
      openContestItemList: openContestItemList ?? this.openContestItemList,
      closedContestItemList:
          closedContestItemList ?? this.closedContestItemList,
    );
  }

  @override
  List<Object?> get props => [openContestItemList, closedContestItemList];
}
