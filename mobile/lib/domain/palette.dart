import 'color_entry.dart';

class Palette {
  Palette({
    required this.name,
    required this.colors,
    this.sourceGroup = 'materials',
    this.sourceFormat = 'unknown',
    this.sourcePath,
    Map<String, Object?>? metadata,
  }) : metadata = metadata ?? <String, Object?>{};

  final String name;
  final List<ColorEntry> colors;
  final String sourceGroup;
  final String sourceFormat;
  final String? sourcePath;
  final Map<String, Object?> metadata;

  List<ColorEntry> get previewColors {
    if (colors.length <= 5) {
      return List<ColorEntry>.unmodifiable(colors);
    }
    return List<ColorEntry>.unmodifiable(colors.take(5));
  }

  Palette copyWith({
    String? name,
    List<ColorEntry>? colors,
    String? sourceGroup,
    String? sourceFormat,
    String? sourcePath,
    Map<String, Object?>? metadata,
  }) {
    return Palette(
      name: name ?? this.name,
      colors: colors ?? this.colors,
      sourceGroup: sourceGroup ?? this.sourceGroup,
      sourceFormat: sourceFormat ?? this.sourceFormat,
      sourcePath: sourcePath ?? this.sourcePath,
      metadata: metadata ?? this.metadata,
    );
  }
}
