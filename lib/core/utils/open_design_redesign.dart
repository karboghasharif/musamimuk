import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../data/models/design_persistence_models.dart';
import '../../data/services/design_redesign_service.dart';
import '../app_export.dart';
import '../network/api_client.dart';
import 'app_toast.dart';
import 'design_state_history.dart';

/// Loads a saved design from the authenticated redesign endpoint and opens it.
Future<void> openDesignForRedesign(
  BuildContext context, {
  required int designId,
  bool cloneBeforeOpening = false,
}) async {
  if (!SessionManager.instance.requireAuthenticated()) return;

  _showRedesignLoading(context);
  try {
    final loadResult = await DesignRedesignService().prepare(
      sourceDesignId: designId,
      cloneBeforeOpening: cloneBeforeOpening,
    );
    final RedesignDesign design;
    switch (loadResult) {
      case PrepareRedesignSuccess(design: final loadedDesign):
        design = loadedDesign;
      case PrepareRedesignFailure(:final message):
        if (!context.mounted) return;
        _closeRedesignLoading(context);
        showAppToast(message, type: ToastificationType.error);
        return;
    }

    final bytes = await _downloadPreview(design.fileUrl);
    if (!context.mounted) return;
    _closeRedesignLoading(context);
    if (bytes == null || bytes.isEmpty) {
      showAppToast(
        'msg_redesign_load_failed'.tr,
        type: ToastificationType.error,
      );
      return;
    }

    final canvasSize = await _resolveCanvasSize(design, bytes);
    if (!context.mounted) return;
    final importHistory = musamiTryParseDesignImportHistory(
      design.designDataJson,
    );
    final hasEditableHistory = importHistory != null;
    if (!hasEditableHistory) {
      showAppToast(
        'This design has no editable layer history. The preview will open as a flat image.',
        type: ToastificationType.info,
      );
    }

    await NavigatorService.pushNamed(
      AppRoutes.screen3AddNewScreen,
      arguments: <String, dynamic>{
        'width': canvasSize.width,
        'height': canvasSize.height,
        'unit': 'px',
        'presetName': design.name.trim().isNotEmpty
            ? design.name.trim()
            : 'lbl_redesign'.tr,
        'designId': design.id,
        'designVisibility': design.visibility,
        'generatedAssetIds': design.generatedAssets
            .map((asset) => asset.id)
            .toList(growable: false),
        if (!hasEditableHistory) 'backgroundImageBytes': bytes,
        if (hasEditableHistory) 'designHistoryJson': design.designDataJson,
      },
    );
  } catch (_) {
    if (!context.mounted) return;
    _closeRedesignLoading(context);
    showAppToast(
      'Design could not be opened. Please try again.',
      type: ToastificationType.error,
    );
  }
}

Future<Uint8List?> _downloadPreview(String url) async {
  final normalized = url.trim();
  if (normalized.isEmpty) return null;
  try {
    final response = await ApiClient().dio.get<List<int>>(
      normalized,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    final data = response.data;
    return data == null || data.isEmpty ? null : Uint8List.fromList(data);
  } catch (_) {
    return null;
  }
}

Future<Size> _resolveCanvasSize(RedesignDesign design, Uint8List bytes) async {
  final width = design.width;
  final height = design.height;
  if (width != null && width > 0 && height != null && height > 0) {
    return Size(width.toDouble(), height.toDouble());
  }
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final size = Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
    frame.image.dispose();
    codec.dispose();
    return size;
  } catch (_) {
    return const Size(1080, 1080);
  }
}

void _showRedesignLoading(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}

void _closeRedesignLoading(BuildContext context) {
  if (!context.mounted) return;
  final navigator = Navigator.of(context, rootNavigator: true);
  if (navigator.canPop()) navigator.pop();
}
