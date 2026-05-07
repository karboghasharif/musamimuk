import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/screen_6_add_png_images_model.dart';
import '../models/staggeredmosque_item_model.dart';
part 'screen_6_add_png_images_event.dart';
part 'screen_6_add_png_images_state.dart';

/// A bloc that manages the state of a Screen6AddPngImages according to the event that is dispatched to it.
class Screen6AddPngImagesBloc
    extends Bloc<Screen6AddPngImagesEvent, Screen6AddPngImagesState> {
  Screen6AddPngImagesBloc(super.initialState) {
    on<Screen6AddPngImagesInitialEvent>(_onInitialize);
  }
  List<StaggeredmosqueItemModel> fillStaggeredmosqueItemList() {
    return [
      StaggeredmosqueItemModel(mosque: ImageConstant.imgMosque1),
      StaggeredmosqueItemModel(mosque: ImageConstant.imgCaligraphy1),
      StaggeredmosqueItemModel(mosque: ImageConstant.imgDeal1)
    ];
  }

  _onInitialize(
    Screen6AddPngImagesInitialEvent event,
    Emitter<Screen6AddPngImagesState> emit,
  ) async {
    emit(state.copyWith(
      searchController: TextEditingController(),
    ));
    emit(state.copyWith(
        screen6AddPngImagesModelObj:
            state.screen6AddPngImagesModelObj?.copyWith(
      staggeredmosqueItemList: fillStaggeredmosqueItemList(),
    )));
  }
}
