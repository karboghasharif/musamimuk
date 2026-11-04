import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/presentation/add_new_screen/utils/musami_design_pack_border_frame.dart';

void main() {
  test('pairs border ↔ corner asset filenames', () {
    expect(
      musamiPairedBorderAssetPath(
        'assets/assets/borders/files/border-1.svg',
      ),
      'assets/assets/borders/files/corner-1.svg',
    );
    expect(
      musamiPairedBorderAssetPath(
        'assets/assets/borders/files/corner-classic-borders-cl-01.svg',
      ),
      'assets/assets/borders/files/border-classic-borders-cl-01.svg',
    );
  });

  test('detects corner filenames', () {
    expect(
      musamiAssetPathLooksLikeCorner(
        'assets/assets/borders/files/corner-12.svg',
      ),
      isTrue,
    );
    expect(
      musamiAssetPathLooksLikeCorner(
        'assets/assets/borders/files/border-12.svg',
      ),
      isFalse,
    );
  });

  test('canvas frame meta detection', () {
    expect(
      musamiMetaIsCanvasBorderFrame({
        'musamiLayerKind': 'design_pack_border',
        kMusamiBorderModeMetaKey: kMusamiBorderModeCanvasFrame,
      }),
      isTrue,
    );
    expect(
      musamiMetaIsCanvasBorderFrame({
        'musamiLayerKind': 'design_pack_shape',
      }),
      isFalse,
    );
  });

  test('motif size clamps to min/max', () {
    expect(musamiBorderMotifSize(const Size(100, 100)), kMusamiBorderMotifMin);
    expect(
      musamiBorderMotifSize(const Size(4000, 4000)),
      kMusamiBorderMotifMax,
    );
    final mid = musamiBorderMotifSize(const Size(800, 800));
    expect(mid, greaterThan(kMusamiBorderMotifMin));
    expect(mid, lessThan(kMusamiBorderMotifMax));
  });

  test('thickness slider maps to motif size', () {
    final thin = musamiBorderMotifSizeFromThickness(const Size(1080, 1920), 1);
    final thick = musamiBorderMotifSizeFromThickness(const Size(1080, 1920), 12);
    expect(thick, greaterThan(thin));
  });

  test('sync frame meta size writes width/height/aspect', () {
    final meta = <String, dynamic>{};
    musamiSyncCanvasBorderFrameMetaSize(meta, width: 800, aspect: 1.5);
    expect(meta['musamiFrameWidth'], 800);
    expect(meta['musamiFrameHeight'], 1200);
    expect(meta['musamiAspect'], 1.5);
  });
}
