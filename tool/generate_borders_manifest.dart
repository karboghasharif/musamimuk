// One-shot / CI helper: regenerate borders JSON index for Flutter assets.
// Run: dart run tool/generate_borders_manifest.dart
import 'dart:convert';
import 'dart:io';

void main() {
  final root = Directory('assets/assets/borders');
  final filesDir = Directory('${root.path}/files');
  final thumbsDir = Directory('${root.path}/thumbs');
  if (!filesDir.existsSync()) {
    stderr.writeln('Missing ${filesDir.path}');
    exit(1);
  }
  final thumbs = <String>{};
  if (thumbsDir.existsSync()) {
    for (final e in thumbsDir.listSync()) {
      if (e is File) thumbs.add(e.uri.pathSegments.last);
    }
  }
  final items = <Map<String, dynamic>>[];
  final files = filesDir
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last)
      .where((n) => !n.startsWith('.'))
      .toList()
    ..sort();
  for (final name in files) {
    final stem = name.contains('.')
        ? name.substring(0, name.lastIndexOf('.'))
        : name;
    String? thumb;
    for (final ext in const ['.png', '.jpg', '.jpeg', '.webp']) {
      final cand = 'thumb.$stem$ext';
      if (thumbs.contains(cand)) {
        thumb = 'thumbs/$cand';
        break;
      }
    }
    items.add({
      'id': stem,
      'file': 'files/$name',
      'name': stem.replaceAll('-', ' '),
      if (thumb != null) 'thumb': thumb,
    });
  }
  final out = {
    'version': 1,
    'root': 'assets/assets/borders',
    'count': items.length,
    'items': items,
  };
  final outFile = File('${root.path}/borders-manifest.json');
  outFile.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(out)}\n');
  stdout.writeln(
    'Wrote ${outFile.path} (${items.length} items, '
    '${items.where((e) => e.containsKey('thumb')).length} thumbs)',
  );
}
