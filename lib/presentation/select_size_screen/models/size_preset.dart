class SizePreset {
  const SizePreset({
    required this.name,
    required this.width,
    required this.height,
    required this.ratio,
    required this.category,
  });

  final String name;
  final double width;
  final double height;
  final String ratio;
  final String category;

  double get aspectRatio => (width <= 0 || height <= 0) ? 1.0 : width / height;
}

