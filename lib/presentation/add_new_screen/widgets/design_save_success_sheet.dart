import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/app_toast.dart';
import 'design_export_encode.dart';

/// Appended caption when sharing an exported design (hashtag + Play Store link).
const String musamiDesignSharePromotionText =
    '#MUSAMIMUK\nhttps://play.google.com/store/apps/details?id=com.musamimuk.app';

String? _sanitizePreferredGalleryBase(String? name) {
  if (name == null || name.trim().isEmpty) return null;
  var s = name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  if (s.length > 80) s = s.substring(0, 80);
  if (s.isEmpty) return null;
  return s;
}

/// Saves raster bytes to the device gallery using a temp file + [Gal.putImage].
///
/// When [quietSuccess] is true, no success toast (used for auto-save after upload).
Future<void> saveExportedDesignToGallery(
  BuildContext context, {
  required Uint8List bytes,
  required DesignExportFileType exportFileType,
  bool quietSuccess = false,
  String? preferredBaseName,
}) async {
  if (exportFileType == DesignExportFileType.pdf) {
    await saveExportedDesignPdf(
      context,
      bytes: bytes,
      preferredBaseName: preferredBaseName,
      quietSuccess: quietSuccess,
    );
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
    final ext = exportFileType.fileExtension;
    final safe = _sanitizePreferredGalleryBase(preferredBaseName);
    final stem = safe == null ? 'musami_gal_$stamp' : '${safe}_$stamp';
    tmp = File('${dir.path}/$stem$ext');
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

/// Opens the system share sheet so the user can save or send a PDF export.
Future<void> saveExportedDesignPdf(
  BuildContext context, {
  required Uint8List bytes,
  String? preferredBaseName,
  bool quietSuccess = false,
}) async {
  await shareExportedDesignBytes(
    context,
    bytes: bytes,
    exportFileType: DesignExportFileType.pdf,
    preferredBaseName: preferredBaseName,
    includePromotionText: false,
    quietSuccess: quietSuccess,
  );
}

/// Opens the platform share sheet for exported design bytes (PNG, JPG, or PDF).
Future<void> shareExportedDesignBytes(
  BuildContext context, {
  required Uint8List bytes,
  required DesignExportFileType exportFileType,
  String? preferredBaseName,
  bool includePromotionText = true,
  bool quietSuccess = false,
}) async {
  File? tmp;
  try {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final safe = _sanitizePreferredGalleryBase(preferredBaseName);
    final filename = safe == null
        ? 'musami_design_$stamp${exportFileType.fileExtension}'
        : exportFileType.filenameFromTitle(safe);
    tmp = File('${dir.path}/$filename');
    await tmp.writeAsBytes(bytes);

    await Share.shareXFiles(
      [
        XFile(
          tmp.path,
          mimeType: exportFileType.mimeType,
          name: filename,
        ),
      ],
      subject: preferredBaseName?.trim().isNotEmpty == true
          ? preferredBaseName!.trim()
          : 'lbl_share_design'.tr,
      text: includePromotionText ? musamiDesignSharePromotionText : null,
    );

    if (!quietSuccess && context.mounted && exportFileType == DesignExportFileType.pdf) {
      showAppToast(
        'msg_export_pdf_ready'.tr,
        type: ToastificationType.success,
      );
    }
  } catch (_) {
    if (!context.mounted) return;
    showAppToast('msg_share_failed'.tr, type: ToastificationType.error);
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
