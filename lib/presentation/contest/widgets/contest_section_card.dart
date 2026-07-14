import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

/// Rounded container used across contest screens — delegates to [AppCard].
class ContestSectionCard extends StatelessWidget {
  const ContestSectionCard({
    super.key,
    required this.child,
    this.title,
    this.padding,
    this.margin,
  });

  final Widget child;
  final String? title;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: title,
      padding: padding,
      margin: margin,
      child: child,
    );
  }
}
