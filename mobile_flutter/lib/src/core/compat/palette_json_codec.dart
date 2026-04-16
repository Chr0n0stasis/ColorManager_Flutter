import 'dart:convert';

import '../models/color_entry.dart';
import '../models/palette.dart';
import 'hex_utils.dart';
import 'json_ascii_utils.dart';

class PaletteJsonCodec {
  const PaletteJsonCodec();

  Palette decodeString(
    String content, {
    String? fallbackName,
    String? sourcePath,
    String sourceGroup = 'materials',
  }) {
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid JSON payload for palette');
    }

    final name = (decoded['name']?.toString().trim().isNotEmpty ?? false)
        ? decoded['name'].toString().trim()
        : (fallbackName ?? 'palette');

    final colors = <ColorEntry>[];
    final rawColors = decoded['colors'];
    if (rawColors is List) {
      for (var index = 0; index < rawColors.length; index++) {
        final item = rawColors[index];
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final colorName = (item['name']?.toString().trim().isNotEmpty ?? false)
            ? item['name'].toString().trim()
            : 'Color ${colors.length + 1}';

        String? hexCode;
        final rawHex = item['hex'];
        if (rawHex != null && rawHex.toString().trim().isNotEmpty) {
          hexCode = normalizeHex(rawHex.toString());
        } else {
          final rgb = item['rgb'];
          if (rgb is List && rgb.length >= 3) {
            final red = _toInt(rgb[0]);
            final green = _toInt(rgb[1]);
            final blue = _toInt(rgb[2]);
            if (red != null && green != null && blue != null) {
              hexCode = rgbToHex(red, green, blue);
            }
          }
        }

        if (hexCode != null) {
          colors.add(ColorEntry(name: colorName, hexCode: hexCode));
        }
      }
    }

    return Palette(
      name: name,
      colors: colors,
      sourcePath: sourcePath,
      sourceFormat: 'json',
      sourceGroup: sourceGroup,
    );
  }

  Palette decodeBytes(
    List<int> bytes, {
    String? fallbackName,
    String? sourcePath,
    String sourceGroup = 'materials',
  }) {
    return decodeString(
      utf8.decode(bytes),
      fallbackName: fallbackName,
      sourcePath: sourcePath,
      sourceGroup: sourceGroup,
    );
  }

  String encodeString(
    Palette palette, {
    bool pretty = true,
    bool ensureAscii = true,
  }) {
    final payload = <String, Object?>{
      'name': palette.name,
      'colors': palette.colors
          .map((color) => <String, String>{
                'name': color.name,
                'hex': color.hexCode,
              })
          .toList(),
    };

    if (ensureAscii) {
      return encodeJsonWithAscii(payload, pretty: pretty);
    }
    return pretty
        ? const JsonEncoder.withIndent('  ').convert(payload)
        : jsonEncode(payload);
  }

  List<int> encodeBytes(
    Palette palette, {
    bool pretty = true,
    bool ensureAscii = true,
  }) {
    return utf8.encode(
      encodeString(palette, pretty: pretty, ensureAscii: ensureAscii),
    );
  }

  int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return int.tryParse(value?.toString() ?? '');
  }
}
