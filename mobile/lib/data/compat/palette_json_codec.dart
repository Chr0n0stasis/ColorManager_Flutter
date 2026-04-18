import 'dart:convert';

import '../../domain/color_entry.dart';
import '../../domain/palette.dart';

class PaletteJsonCodec {
  const PaletteJsonCodec();

  Palette decode(
    String jsonText, {
    String? fallbackName,
    String sourceGroup = 'materials',
    String sourceFormat = 'json',
    String? sourcePath,
  }) {
    final dynamic payload = jsonDecode(jsonText);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('JSON payload must be an object.');
    }

    final colors = <ColorEntry>[];
    final items = payload['colors'];
    if (items is List) {
      for (final item in items) {
        if (item is! Map) {
          continue;
        }

        final rawName = item['name']?.toString().trim();
        final colorName = (rawName == null || rawName.isEmpty)
            ? 'Color ${colors.length + 1}'
            : rawName;

        String? hex;
        final rawHex = item['hex']?.toString().trim();
        if (rawHex != null && rawHex.isNotEmpty) {
          hex = rawHex;
        } else {
          final rgb = item['rgb'];
          if (rgb is List && rgb.length >= 3) {
            final red = int.tryParse(rgb[0].toString());
            final green = int.tryParse(rgb[1].toString());
            final blue = int.tryParse(rgb[2].toString());
            if (red != null && green != null && blue != null) {
              hex = ColorEntry.rgbToHex(red, green, blue);
            }
          }
        }

        if (hex == null) {
          continue;
        }

        colors.add(ColorEntry(name: colorName, hexCode: hex));
      }
    }

    final rawName = payload['name']?.toString().trim();
    final paletteName = (rawName == null || rawName.isEmpty)
        ? (fallbackName ?? 'Untitled')
        : rawName;

    return Palette(
      name: paletteName,
      colors: colors,
      sourceGroup: sourceGroup,
      sourceFormat: sourceFormat,
      sourcePath: sourcePath,
    );
  }

  String encode(Palette palette) {
    final payload = <String, Object?>{
      'name': palette.name,
      'colors': palette.colors
          .map((color) => <String, String>{
                'name': color.name,
                'hex': color.hexCode,
              })
          .toList(growable: false),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }
}
