// ignore_for_file: must_be_immutable

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/design_system/app_design_tokens.dart';
import '../core/network/api_utils.dart';
import '../core/network/authenticated_image.dart';

extension ImageTypeExtension on String {
  ImageType get imageType {
    final value = trim();
    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('//') ||
        value.startsWith('/storage/') ||
        value.startsWith('storage/') ||
        value.startsWith('/public/storage/') ||
        value.startsWith('public/storage/')) {
      return ImageType.network;
    } else if (value.endsWith('.svg')) {
      return ImageType.svg;
    } else if (value.startsWith('file://')) {
      return ImageType.file;
    } else {
      return ImageType.png;
    }
  }
}

enum ImageType { svg, png, network, file, unknown }

class CustomImageView extends StatelessWidget {
  CustomImageView({
    super.key,
    this.imagePath,
    this.height,
    this.width,
    this.color,
    this.fit,
    this.alignment,
    this.onTap,
    this.radius,
    this.margin,
    this.border,
    this.placeHolder = 'assets/images/image_not_found.png',
  });
  String? imagePath;
  double? height;
  double? width;
  Color? color;
  BoxFit? fit;
  final String placeHolder;
  Alignment? alignment;
  VoidCallback? onTap;
  EdgeInsetsGeometry? margin;
  BorderRadius? radius;
  BoxBorder? border;
  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(alignment: alignment!, child: _buildWidget())
        : _buildWidget();
  }

  Widget _buildWidget() {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: InkWell(onTap: onTap, child: _buildCircleImage()),
    );
  }

  _buildCircleImage() {
    if (radius != null) {
      return ClipRRect(
        borderRadius: radius ?? BorderRadius.zero,
        child: _buildImageWithBorder(),
      );
    } else {
      return _buildImageWithBorder();
    }
  }

  _buildImageWithBorder() {
    if (border != null) {
      return Container(
        decoration: BoxDecoration(border: border, borderRadius: radius),
        child: _buildImageView(),
      );
    } else {
      return _buildImageView();
    }
  }

  Widget _buildImageView() {
    final path = imagePath?.trim();
    if (path != null && path.isNotEmpty) {
      switch (path.imageType) {
        case ImageType.svg:
          return SizedBox(
            height: height,
            width: width,
            child: SvgPicture.asset(
              path,
              height: height,
              width: width,
              fit: fit ?? BoxFit.contain,
              colorFilter: color != null
                  ? ColorFilter.mode(
                      color ?? Colors.transparent,
                      BlendMode.srcIn,
                    )
                  : null,
            ),
          );
        case ImageType.file:
          return Image.file(
            File(path),
            height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
            color: color,
          );
        case ImageType.network:
          final networkUrl = apiResolveMediaUrl(path);
          return CachedNetworkImage(
            height: height,
            width: width,
            fit: fit,
            imageUrl: networkUrl,
            httpHeaders: musamiAuthenticatedHeadersForUrl(networkUrl),
            cacheManager: MusamiImageCache.instance,
            color: color,
            fadeInDuration: AppDs.motionNormal,
            fadeOutDuration: AppDs.motionFast,
            placeholder: (context, url) => Container(
              height: height,
              width: width,
              color: AppDs.surfaceElevated,
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: height,
              width: width,
              color: AppDs.atelierInk,
              alignment: Alignment.center,
              child: Icon(
                Icons.broken_image_outlined,
                size: 28,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          );
        case ImageType.png:
        default:
          return Image.asset(
            path,
            height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
            color: color,
          );
      }
    }
    return const SizedBox();
  }
}
