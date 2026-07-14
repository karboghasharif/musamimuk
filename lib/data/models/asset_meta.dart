/// Catalog meta from `GET /assets/meta`.
class AssetMeta {
  const AssetMeta({
    required this.types,
    this.statuses = const [],
    this.sortOptions = const [],
  });

  final List<String> types;
  final List<String> statuses;
  final List<String> sortOptions;

  factory AssetMeta.fromJson(Map<String, dynamic> json) {
    List<String> readStringList(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .map((e) {
            if (e is String) return e.trim();
            if (e is Map) {
              final slug = e['slug'] ?? e['type'] ?? e['key'] ?? e['name'];
              return slug?.toString().trim() ?? '';
            }
            return e.toString().trim();
          })
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    }

    return AssetMeta(
      types: readStringList(json['types']),
      statuses: readStringList(json['statuses']),
      sortOptions: readStringList(json['sort'] ?? json['sort_options']),
    );
  }

  static const fallbackTypes = ['shape', 'png', 'logo'];
}
