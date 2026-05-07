import 'package:flutter/material.dart';
import '../../core/app_export.dart';

/// Back/arrow control: only the image is tappable (not a full-width strip).
/// The [margin] left/top/bottom offset the icon; large right margins are ignored
/// (they were previously used as a layout hack and inflated the hit target).
class AppbarLeadingImage extends StatelessWidget {
  const AppbarLeadingImage({
    super.key,
    this.imagePath,
    this.margin,
    this.onTap,
  });

  final String? imagePath;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final resolved = margin?.resolve(Directionality.of(context));
    final pad = EdgeInsets.only(
      left: resolved?.left ?? 0,
      top: resolved?.top ?? 0,
      bottom: resolved?.bottom ?? 0,
    );

    Widget child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => NavigatorService.goBack(),
        child: CustomImageView(
          imagePath: imagePath!,
          height: 16.v,
          width: 20.h,
          fit: BoxFit.contain,
        ),
      ),
    );

    if (pad.left > 0 || pad.top > 0 || pad.bottom > 0) {
      child = Padding(padding: pad, child: child);
    }

    return Align(
      alignment: Alignment.center,
      child: child,
    );
  }
}
