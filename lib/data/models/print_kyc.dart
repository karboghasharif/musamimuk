/// Document kind constants aligned with API `App\Support\PrintKyc`.
class PrintKyc {
  PrintKyc._();

  static const maxBytes = 5 * 1024 * 1024;
  static const allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf', 'webp'];

  static const shopCommercialRegistration = 'commercial_registration';
  static const shopNationalId = 'national_id';
  static const shopOwnerId = 'owner_id';
  static const shopIbanCertificate = 'iban_certificate';
  static const shopVatCertificate = 'vat_certificate';
  static const shopPhoto = 'shop_photo';

  static const riderNationalId = 'national_id';
  static const riderDriverLicense = 'driver_license';
  static const riderVehicleRegistration = 'vehicle_registration';
  static const riderIbanCertificate = 'iban_certificate';
  static const riderSelfieWithId = 'selfie_with_id';

  static const shopRequiredKinds = [
    shopCommercialRegistration,
    shopNationalId,
    shopIbanCertificate,
  ];

  static const shopOptionalKinds = [
    shopVatCertificate,
    shopPhoto,
  ];

  static const riderRequiredKinds = [
    riderNationalId,
    riderDriverLicense,
    riderIbanCertificate,
  ];

  static const riderOptionalKinds = [
    riderSelfieWithId,
  ];

  static String labelKey(String kind) => 'lbl_print_doc_$kind';
}

class PrintPickedDoc {
  const PrintPickedDoc({
    required this.kind,
    required this.path,
    required this.name,
    required this.bytes,
  });

  final String kind;
  final String path;
  final String name;
  final int bytes;

  bool get withinLimit => bytes <= PrintKyc.maxBytes;

  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot >= name.length - 1) {
      final p = path.lastIndexOf('.');
      if (p < 0 || p >= path.length - 1) return '';
      return path.substring(p + 1).toLowerCase();
    }
    return name.substring(dot + 1).toLowerCase();
  }

  bool get isImage =>
      const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension);

  bool get isPdf => extension == 'pdf';
}

class PrintDocument {
  const PrintDocument({
    required this.id,
    required this.kind,
    this.filePath,
    this.fileUrl,
    this.status = 'uploaded',
    this.uploadedAt,
  });

  final int id;
  final String kind;
  final String? filePath;
  final String? fileUrl;
  final String status;
  final String? uploadedAt;

  String get extension {
    for (final raw in [filePath, fileUrl, kind]) {
      if (raw == null || raw.isEmpty) continue;
      final cleaned = raw.split('?').first;
      final dot = cleaned.lastIndexOf('.');
      if (dot >= 0 && dot < cleaned.length - 1) {
        return cleaned.substring(dot + 1).toLowerCase();
      }
    }
    return '';
  }

  bool get isImage =>
      const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension);

  bool get isPdf => extension == 'pdf';

  factory PrintDocument.fromJson(Map<String, dynamic> json) {
    return PrintDocument(
      id: _asInt(json['id']) ?? 0,
      kind: json['kind']?.toString() ?? 'document',
      filePath: json['file_path']?.toString(),
      fileUrl: json['file_url']?.toString(),
      status: json['status']?.toString() ?? 'uploaded',
      uploadedAt: json['uploaded_at']?.toString(),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
