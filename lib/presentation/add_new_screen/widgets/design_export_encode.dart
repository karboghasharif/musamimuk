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

extension DesignExportFileTypeX on DesignExportFileType {
  String get uploadFilename => switch (this) {
        DesignExportFileType.png => 'design.png',
        DesignExportFileType.jpg => 'design.jpg',
        DesignExportFileType.pdf => 'design.pdf',
      };
}

/// Resize and encode editor PNG bytes for upload.
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
      final raster = Uint8List.fromList(img.encodePng(resized));
      final doc = pw.Document();
      final image = pw.MemoryImage(raster);
      final pageW = w * 72 / 96;
      final pageH = h * 72 / 96;
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(pageW, pageH),
          build: (ctx) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
      return doc.save();
  }
}
