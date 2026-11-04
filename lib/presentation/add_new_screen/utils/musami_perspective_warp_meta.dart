/// Meta keys for perspective-quad warp on image [WidgetLayer]s.
const String kMusamiWarpSourceMetaKey = 'musamiWarpSource';
const String kMusamiWarpOriginalNetworkUrlMetaKey =
    'musamiWarpOriginalNetworkUrl';
const String kMusamiWarpOriginalAssetPathMetaKey =
    'musamiWarpOriginalAssetPath';
const String kMusamiWarpQuadMetaKey = 'musamiWarpQuad';

/// Values for [kMusamiWarpSourceMetaKey].
const String kMusamiWarpSourceOriginal = 'original';
const String kMusamiWarpSourceWarped = 'warped';

/// Preview decode: longest edge (device-independent pixels before warp).
const int kMusamiWarpPreviewMaxEdge = 768;

/// Apply decode / output: longest edge cap for mid Android.
const int kMusamiWarpFullMaxEdge = 2048;

bool musamiMetaIsPerspectiveWarped(Map<String, dynamic>? meta) {
  return meta?[kMusamiWarpSourceMetaKey]?.toString() ==
      kMusamiWarpSourceWarped;
}

/// Normalized quad corners as 8 doubles: tlX,tlY, trX,trY, brX,brY, blX,blY in 0–1.
List<double>? musamiParseWarpQuad(dynamic raw) {
  if (raw is! List || raw.length != 8) return null;
  final out = <double>[];
  for (final e in raw) {
    if (e is! num) return null;
    out.add(e.toDouble().clamp(0.0, 1.0));
  }
  return out;
}

List<double> musamiDefaultWarpQuad() => const [
      0.0,
      0.0,
      1.0,
      0.0,
      1.0,
      1.0,
      0.0,
      1.0,
    ];
