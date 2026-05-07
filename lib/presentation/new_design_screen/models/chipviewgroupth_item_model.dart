import 'package:equatable/equatable.dart';
// This class is used in the [chipviewgroupth_item_widget] screen.// ignore_for_file: must_be_immutable// ignore_for_file: must_be_immutable

class ChipviewgroupthItemModel extends Equatable {
  ChipviewgroupthItemModel({this.groupthirty, this.isSelected}) {
    groupthirty = groupthirty ?? "500";
    isSelected = isSelected ?? false;
  }
  String? groupthirty;
  bool? isSelected;
  ChipviewgroupthItemModel copyWith({
    String? groupthirty,
    bool? isSelected,
  }) {
    return ChipviewgroupthItemModel(
      groupthirty: groupthirty ?? this.groupthirty,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  List<Object?> get props => [groupthirty, isSelected];
}
