import 'color_entry.dart';

class Palette {
  Palette({
    required this.name,
    required List<ColorEntry> colors,
    this.sourcePath,
    this.sourceFormat = 'unknown',
    this.sourceGroup = 'materials',
    Map<String, Object?> metadata = const <String, Object?>{},
  })  : colors = List<ColorEntry>.unmodifiable(colors),
        metadata = Map<String, Object?>.unmodifiable(metadata);

  final String name;
  final List<ColorEntry> colors;
  final String? sourcePath;
  final String sourceFormat;
  final String sourceGroup;
  final Map<String, Object?> metadata;

  List<ColorEntry> get previewColors {
    final upperBound = colors.length < 6 ? colors.length : 6;
    return colors.sublist(0, upperBound);
  }
}
