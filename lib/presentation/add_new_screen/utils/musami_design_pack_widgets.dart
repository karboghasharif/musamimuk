import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Export / widgetLoader id prefix for offline pack layers.
const String kMusamiDesignPackIdPrefix = 'musami-design-pack:';

bool musamiIsDesignPackLayerKind(String? kind) {
  if (kind == null || kind.isEmpty) return false;
  return kind.startsWith('design_pack_');
}

Widget musamiDesignPackWidget({
  required String assetPath,
  required bool isSvg,
  double width = 180,
  double height = 180,
  Color? tint,
}) {
  if (isSvg) {
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.asset(
        assetPath,
        fit: BoxFit.contain,
        colorFilter: tint == null
            ? null
            : ColorFilter.mode(tint, BlendMode.srcIn),
        placeholderBuilder: (_) => const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
      ),
    );
  }
  return SizedBox(
    width: width,
    height: height,
    child: Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
    ),
  );
}
