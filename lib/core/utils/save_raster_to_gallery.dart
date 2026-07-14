import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:toastification/toastification.dart';

import '../../localization/app_localization.dart';
import 'app_toast.dart';

/// Photo album used for QR codes, exports, and background-removed images.
const String kMusamimukGalleryAlbum = 'Musamimuk';

String _sanitizeFileStem(String raw) {
  var s = raw.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  if (s.length > 80) s = s.substring(0, 80);
  return s.isEmpty ? 'musami_image' : s;
}

/// Saves [bytes] to the device photo library, shows a location toast, and opens
/// the gallery app so the user can view the saved image immediately.
Future<bool> saveRasterToGalleryAndOpen(
  BuildContext context, {
  required Uint8List bytes,
  String fileBaseName = 'musami_image',
}) async {
  File? tmp;
  try {
    var allowed = await Gal.hasAccess(toAlbum: true);
    if (!allowed) {
      allowed = await Gal.requestAccess(toAlbum: true);
    }
    if (!allowed) {
      if (context.mounted) {
        showAppToast(
          AppLocalization.translate('msg_save_to_gallery_denied'),
          type: ToastificationType.warning,
        );
      }
      return false;
    }

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final stem = '${_sanitizeFileStem(fileBaseName)}_$stamp';
    tmp = File('${dir.path}/$stem.png');
    await tmp.writeAsBytes(bytes);

    await Gal.putImage(tmp.path, album: kMusamimukGalleryAlbum);

    if (context.mounted) {
      showAppToast(
        AppLocalization.translate('msg_saved_to_gallery_with_location')
            .replaceAll('{album}', kMusamimukGalleryAlbum),
        type: ToastificationType.success,
        autoCloseDuration: const Duration(seconds: 4),
      );
    }

    await Gal.open();
    return true;
  } on GalException catch (e) {
    if (context.mounted) {
      showAppToast(e.toString(), type: ToastificationType.error);
    }
    return false;
  } catch (_) {
    if (context.mounted) {
      showAppToast(
        AppLocalization.translate('msg_export_failed'),
        type: ToastificationType.error,
      );
    }
    return false;
  } finally {
    try {
      if (tmp != null && await tmp.exists()) {
        await tmp.delete();
      }
    } catch (_) {}
  }
}
