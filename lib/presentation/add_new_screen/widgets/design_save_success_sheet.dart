import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/app_toast.dart';
import 'design_export_encode.dart';

/// Saves raster bytes to the device gallery using a temp file + [Gal.putImage].
///
/// When [quietSuccess] is true, no success toast (used for auto-save after upload).
Future<void> saveExportedDesignToGallery(
  BuildContext context, {
  required Uint8List bytes,
  required DesignExportFileType exportFileType,
  bool quietSuccess = false,
}) async {
  if (exportFileType == DesignExportFileType.pdf) {
    if (!quietSuccess && context.mounted) {
      showAppToast(
        'msg_gallery_raster_only'.tr,
        type: ToastificationType.warning,
      );
    }
    return;
  }

  File? tmp;
  try {
    var allowed = await Gal.hasAccess(toAlbum: true);
    if (!allowed) {
      allowed = await Gal.requestAccess(toAlbum: true);
    }
    if (!allowed) {
      if (!quietSuccess && context.mounted) {
        showAppToast(
          'msg_save_to_gallery_denied'.tr,
          type: ToastificationType.warning,
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final ext =
        exportFileType == DesignExportFileType.png ? '.png' : '.jpg';
    tmp = File('${dir.path}/musami_gal_$stamp$ext');
    await tmp.writeAsBytes(bytes);

    await Gal.putImage(tmp.path, album: 'Musamimuk');

    if (!quietSuccess && context.mounted) {
      showAppToast(
        'msg_saved_to_gallery'.tr,
        type: ToastificationType.success,
      );
    }
  } on GalException catch (e) {
    if (context.mounted) {
      showAppToast(e.toString(), type: ToastificationType.error);
    }
  } catch (_) {
    if (context.mounted) {
      showAppToast(
        'msg_export_failed'.tr,
        type: ToastificationType.error,
      );
    }
  } finally {
    try {
      if (tmp != null && await tmp.exists()) {
        await tmp.delete();
      }
    } catch (_) {}
  }
}

/// Minimal success dialog: check icon, message, OK only.
Future<void> showDesignSaveSuccessDialog(BuildContext context) async {
  if (!context.mounted) return;
  final loc = MaterialLocalizations.of(context);

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    useRootNavigator: true,
    builder: (dialogContext) {
      final cs = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        icon: Icon(
          Icons.check_circle_rounded,
          color: cs.primary,
          size: 48,
        ),
        title: Text(
          'msg_design_saved_success'.tr,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(loc.okButtonLabel),
          ),
        ],
      );
    },
  );
}
