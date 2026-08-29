import 'package:flutter/material.dart';

/// Source categories shown when the user opens Online Assets.
enum OnlineAssetProvider {
  unsplash,
  pexels,
  pixabay,
  iconify,
  artic,
  metMuseum,
  colormind,
  colourLovers,
  dummyImage,
  emojiHub,
  iconHorse,
  icons8,
  lottieLibrary,
  lordicon,
  phpNoise,
}

extension OnlineAssetProviderX on OnlineAssetProvider {
  String get id => name;

  String get titleKey => switch (this) {
    OnlineAssetProvider.unsplash => 'lbl_oa_unsplash',
    OnlineAssetProvider.pexels => 'lbl_oa_pexels',
    OnlineAssetProvider.pixabay => 'lbl_oa_pixabay',
    OnlineAssetProvider.iconify => 'lbl_oa_iconify',
    OnlineAssetProvider.artic => 'lbl_oa_artic',
    OnlineAssetProvider.colormind => 'lbl_oa_colormind',
    OnlineAssetProvider.colourLovers => 'lbl_oa_colourlovers',
    OnlineAssetProvider.dummyImage => 'lbl_oa_dummyimage',
    OnlineAssetProvider.emojiHub => 'lbl_oa_emojihub',
    OnlineAssetProvider.iconHorse => 'lbl_oa_iconhorse',
    OnlineAssetProvider.icons8 => 'lbl_oa_icons8',
    OnlineAssetProvider.lottieLibrary => 'lbl_oa_lottie_library',
    OnlineAssetProvider.lordicon => 'lbl_oa_lordicon',
    OnlineAssetProvider.metMuseum => 'lbl_oa_met',
    OnlineAssetProvider.phpNoise => 'lbl_oa_phpnoise',
  };

  String get subtitleKey => switch (this) {
    OnlineAssetProvider.unsplash => 'lbl_oa_unsplash_sub',
    OnlineAssetProvider.pexels => 'lbl_oa_pexels_sub',
    OnlineAssetProvider.pixabay => 'lbl_oa_pixabay_sub',
    OnlineAssetProvider.iconify => 'lbl_oa_iconify_sub',
    OnlineAssetProvider.artic => 'lbl_oa_artic_sub',
    OnlineAssetProvider.colormind => 'lbl_oa_colormind_sub',
    OnlineAssetProvider.colourLovers => 'lbl_oa_colourlovers_sub',
    OnlineAssetProvider.dummyImage => 'lbl_oa_dummyimage_sub',
    OnlineAssetProvider.emojiHub => 'lbl_oa_emojihub_sub',
    OnlineAssetProvider.iconHorse => 'lbl_oa_iconhorse_sub',
    OnlineAssetProvider.icons8 => 'lbl_oa_icons8_sub',
    OnlineAssetProvider.lottieLibrary => 'lbl_oa_lottie_library_sub',
    OnlineAssetProvider.lordicon => 'lbl_oa_lordicon_sub',
    OnlineAssetProvider.metMuseum => 'lbl_oa_met_sub',
    OnlineAssetProvider.phpNoise => 'lbl_oa_phpnoise_sub',
  };

  IconData get icon => switch (this) {
    OnlineAssetProvider.unsplash => Icons.photo_library_outlined,
    OnlineAssetProvider.pexels => Icons.camera_alt_outlined,
    OnlineAssetProvider.pixabay => Icons.collections_outlined,
    OnlineAssetProvider.iconify => Icons.category_outlined,
    OnlineAssetProvider.artic => Icons.museum_outlined,
    OnlineAssetProvider.colormind => Icons.palette_outlined,
    OnlineAssetProvider.colourLovers => Icons.color_lens_outlined,
    OnlineAssetProvider.dummyImage => Icons.image_outlined,
    OnlineAssetProvider.emojiHub => Icons.emoji_emotions_outlined,
    OnlineAssetProvider.iconHorse => Icons.language_outlined,
    OnlineAssetProvider.icons8 => Icons.apps_outlined,
    OnlineAssetProvider.lottieLibrary => Icons.motion_photos_on_outlined,
    OnlineAssetProvider.lordicon => Icons.animation_outlined,
    OnlineAssetProvider.metMuseum => Icons.account_balance_outlined,
    OnlineAssetProvider.phpNoise => Icons.grain_outlined,
  };
}

/// How an [OnlineAssetItem] should be applied on the editor canvas.
enum OnlineAssetApplyKind {
  /// Downloadable raster/network image → [WidgetLayer] via MediaItem.
  image,

  /// Unicode emoji / short text → [TextLayer].
  emojiText,

  /// Lottie JSON animation → [WidgetLayer] with Lottie player.
  lottie,

  /// SVG icon (Iconify) → [WidgetLayer] with SvgPicture.network.
  svg,

  /// Solid / palette colors — still delivered as an image URL when possible.
  paletteImage,
}

class OnlineAssetItem {
  const OnlineAssetItem({
    required this.id,
    required this.title,
    required this.provider,
    required this.applyKind,
    this.imageUrl,
    this.thumbUrl,
    this.lottieUrl,
    this.svgUrl,
    this.emoji,
    this.colors,
    this.width,
    this.height,
    this.attribution,
    this.downloadLocation,
  });

  final String id;
  final String title;
  final OnlineAssetProvider provider;
  final OnlineAssetApplyKind applyKind;

  final String? imageUrl;
  final String? thumbUrl;
  final String? lottieUrl;
  final String? svgUrl;
  final String? emoji;

  /// RGB or hex colors for palette providers.
  final List<Color>? colors;

  final int? width;
  final int? height;
  final String? attribution;

  /// Unsplash `download_location` — ping via backend when the photo is used.
  final String? downloadLocation;

  int get mediaId => id.hashCode & 0x7fffffff;

  String? get previewUrl => thumbUrl ?? imageUrl ?? svgUrl;
}

sealed class OnlineAssetListResult {}

class OnlineAssetListSuccess extends OnlineAssetListResult {
  OnlineAssetListSuccess(this.items, {this.hasMore = false, this.nextPage});

  final List<OnlineAssetItem> items;
  final bool hasMore;
  final int? nextPage;
}

class OnlineAssetListFailure extends OnlineAssetListResult {
  OnlineAssetListFailure(this.message);
  final String message;
}
