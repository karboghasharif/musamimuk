import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// App-wide toast notifications via [toastification].
/// Requires [ToastificationWrapper] around [MaterialApp] (see `main.dart`).
void showAppToast(
  String message, {
  ToastificationType type = ToastificationType.info,
  Duration autoCloseDuration = const Duration(seconds: 3),
  ToastificationStyle style = ToastificationStyle.flat,
}) {
  toastification.show(
    type: type,
    style: style,
    title: Text(message, maxLines: 6, overflow: TextOverflow.ellipsis),
    autoCloseDuration: autoCloseDuration,
  );
}
