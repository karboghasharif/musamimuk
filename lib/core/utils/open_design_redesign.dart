import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../app_export.dart';
import '../network/api_client.dart';
import 'app_toast.dart';
import 'design_state_history.dart';

/// Opens [AddNewScreen] to redesign a saved design.
///
/// When `design_data` is present, uses pro_image_editor
/// [StateHistoryConfigs.initStateHistory] to restore editable layers.
/// Otherwise falls back to the flattened preview image as the canvas background.
Future<void> openDesignForRedesign(
  BuildContext context, {
  required String imageUrl,
  String? designName,
  String? designHistoryJson,
  int? width,
  int? height,
}) async {
  final url = imageUrl.trim();
  if (url.isEmpty) {
    showAppToast(
      'msg_redesign_image_missing'.tr,
      type: ToastificationType.warning,
    );
    return;
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 20.v),
            decoration: BoxDecoration(
              color: appTheme.blueGray90002,
              borderRadius: BorderRadius.circular(16.adaptSize),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                SizedBox(height: 14.v),
                Text(
                  'msg_opening_design_editor'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Uint8List? bytes;
  try {
    final response = await ApiClient().dio.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    final data = response.data;
    if (data != null && data.isNotEmpty) {
      bytes = Uint8List.fromList(data);
    }
  } catch (_) {
    bytes = null;
  }

  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).pop();
  }
  if (!context.mounted) return;

  if (bytes == null || bytes.isEmpty) {
    showAppToast(
      'msg_redesign_load_failed'.tr,
      type: ToastificationType.error,
    );
    return;
  }

  var canvasW = (width ?? 0).toDouble();
  var canvasH = (height ?? 0).toDouble();
  if (canvasW < 1 || canvasH < 1) {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      canvasW = frame.image.width.toDouble();
      canvasH = frame.image.height.toDouble();
      frame.image.dispose();
      codec.dispose();
    } catch (_) {
      canvasW = 1080;
      canvasH = 1080;
    }
  }

  final importHistory = musamiTryParseDesignImportHistory(designHistoryJson);
  final hasEditableHistory = importHistory != null;

  if (designHistoryJson != null &&
      designHistoryJson.trim().isNotEmpty &&
      !hasEditableHistory) {
    showAppToast(
      'msg_redesign_history_import_failed'.tr,
      type: ToastificationType.warning,
    );
  }

  NavigatorService.pushNamed(
    AppRoutes.screen3AddNewScreen,
    arguments: <String, dynamic>{
      'width': canvasW,
      'height': canvasH,
      'unit': 'px',
      'presetName': (designName?.trim().isNotEmpty == true)
          ? designName!.trim()
          : 'lbl_redesign'.tr,
      if (!hasEditableHistory) 'backgroundImageBytes': bytes,
      if (hasEditableHistory) 'designHistoryJson': designHistoryJson!.trim(),
    },
  );
}
