import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

/// This class is used in the [gridgallery_pic_item_widget] screen.\\ ignore_for_file: must_be_immutable\\ ignore_for_file: must_be_immutable
class GridgalleryPicItemModel {
  GridgalleryPicItemModel({
    this.galleryPicOne,
    this.gallerypic,
    this.icon,
    this.id,
  }) {
    galleryPicOne = galleryPicOne ?? ImageConstant.imgGallerySvgrepoCom;
    gallerypic = gallerypic ?? "Gallery Pic";
    id = id ?? "";
  }
  String? galleryPicOne;
  String? gallerypic;
  IconData? icon;
  String? id;
}
