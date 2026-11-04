/// User-created folder for organizing My Designs (local drafts + cloud tags).
class DesignFolder {
  const DesignFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final int sortOrder;

  DesignFolder copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    int? sortOrder,
  }) {
    return DesignFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'sortOrder': sortOrder,
      };

  factory DesignFolder.fromJson(Map<String, dynamic> json) {
    return DesignFolder(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}
