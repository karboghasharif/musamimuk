import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Output format chosen in the save dialog (server upload).
enum DesignExportFileType { png, jpg, pdf }

/// Values confirmed in the save dialog before upload.
class DesignSaveFormResult {
  const DesignSaveFormResult({
    required this.title,
    required this.visibility,
    required this.fileType,
    required this.width,
    required this.height,
    required this.quality,
  });

  final String title;
  final String visibility;
  final DesignExportFileType fileType;
  final int width;
  final int height;
  final int quality;
}

/// Editor raster pixels map to PDF points at 72 pt/in (standard PDF unit).
const double _kPdfPointsPerEditorPixel = 72.0 / 96.0;

extension DesignExportFileTypeX on DesignExportFileType {
  String get uploadFilename => switch (this) {
        DesignExportFileType.png => 'design.png',
        DesignExportFileType.jpg => 'design.jpg',
        DesignExportFileType.pdf => 'design.pdf',
      };

  String get fileExtension => switch (this) {
        DesignExportFileType.png => '.png',
        DesignExportFileType.jpg => '.jpg',
        DesignExportFileType.pdf => '.pdf',
      };

  String get mimeType => switch (this) {
        DesignExportFileType.png => 'image/png',
        DesignExportFileType.jpg => 'image/jpeg',
        DesignExportFileType.pdf => 'application/pdf',
      };

  String filenameFromTitle(String title) {
    var safe = title.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    if (safe.isEmpty) safe = 'design';
    if (safe.length > 80) safe = safe.substring(0, 80);
    return '$safe$fileExtension';
  }
}

PdfPageFormat _pdfPageFormatForCanvas(int widthPx, int heightPx) {
  final w = widthPx.clamp(16, 8192).toDouble();
  final h = heightPx.clamp(16, 8192).toDouble();
  return PdfPageFormat(
    w * _kPdfPointsPerEditorPixel,
    h * _kPdfPointsPerEditorPixel,
    marginLeft: 0,
    marginTop: 0,
    marginRight: 0,
    marginBottom: 0,
  );
}

Future<Uint8List> _encodePdfFromRaster(
  img.Image raster,
  int widthPx,
  int heightPx,
) async {
  final pngBytes = Uint8List.fromList(img.encodePng(raster));
  final pageFormat = _pdfPageFormatForCanvas(widthPx, heightPx);
  final pageW = pageFormat.width;
  final pageH = pageFormat.height;

  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      margin: pw.EdgeInsets.zero,
      build: (context) {
        return pw.SizedBox(
          width: pageW,
          height: pageH,
          child: pw.Image(
            pw.MemoryImage(pngBytes),
            fit: pw.BoxFit.fill,
          ),
        );
      },
    ),
  );
  return doc.save();
}

/// Resize and encode editor PNG bytes for upload, gallery, or share.
Future<Uint8List?> encodeDesignForUpload(
  Uint8List raw, {
  required int width,
  required int height,
  required DesignExportFileType type,
  required int jpgQuality,
}) async {
  final decoded = img.decodeImage(raw);
  if (decoded == null) return null;

  final w = width.clamp(16, 8192);
  final h = height.clamp(16, 8192);
  final resized = img.copyResize(
    decoded,
    width: w,
    height: h,
    interpolation: img.Interpolation.cubic,
  );

  switch (type) {
    case DesignExportFileType.png:
      return Uint8List.fromList(img.encodePng(resized));
    case DesignExportFileType.jpg:
      final q = jpgQuality.clamp(1, 100);
      return Uint8List.fromList(img.encodeJpg(resized, quality: q));
    case DesignExportFileType.pdf:
      return _encodePdfFromRaster(resized, w, h);
  }
}
