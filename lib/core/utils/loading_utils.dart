import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../design_system/app_components.dart';
import '../design_system/app_design_tokens.dart';

/// Waits until [isLoading] returns false on [bloc], with a safety timeout.
Future<void> waitForBlocLoadingComplete<S>(
  BlocBase<S> bloc, {
  required bool Function(S state) isLoading,
  Duration timeout = const Duration(seconds: 45),
}) async {
  if (!isLoading(bloc.state)) return;
  try {
    await bloc.stream
        .map(isLoading)
        .firstWhere((loading) => !loading)
        .timeout(timeout);
  } on TimeoutException {
    // Let RefreshIndicator / UI recover even if the bloc never cleared loading.
  }
}

/// Runs [task] while showing a modal loading dialog; always dismisses the dialog.
Future<T?> runWithLoadingDialog<T>(
  BuildContext context,
  Future<T> Function() task, {
  String? message,
  bool useRootNavigator = true,
}) async {
  if (!context.mounted) return null;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: useRootNavigator,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message ?? 'Loading…',
                style: Theme.of(dialogContext).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  try {
    return await task();
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: useRootNavigator).pop();
    }
  }
}

/// Full-screen or in-layout blocking loader overlay.
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.absorbPointers = true,
  });

  final bool isLoading;
  final Widget child;
  final String? message;
  final bool absorbPointers;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: absorbPointers,
              child: ColoredBox(
                color: AppDs.surfaceBase.withValues(alpha: 0.72),
                child: AppLoadingBlock(message: message),
              ),
            ),
          ),
      ],
    );
  }
}
