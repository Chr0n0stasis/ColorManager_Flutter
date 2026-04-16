import 'dart:convert';

import '../models/color_entry.dart';
import '../models/palette.dart';
import 'hex_utils.dart';

class PaletteCsvCodec {
  const PaletteCsvCodec();

  Palette decodeString(
    String content, {
    required String fallbackName,
    String? sourcePath,
    String sourceGroup = 'materials',
  }) {
    final normalized = content.startsWith('\uFEFF')
        ? content.substring(1)
        : content;
    final lines = const LineSplitter()
        .convert(normalized)
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return Palette(
        name: fallbackName,
        colors: const <ColorEntry>[],
        sourcePath: sourcePath,
        sourceFormat: 'csv',
        sourceGroup: sourceGroup,
      );
    }

    final header = _parseRow(lines.first)
        .map((cell) => cell.trim().toLowerCase())
        .toList();

    final nameIndex = _findHeaderIndex(header, const ['name']);
    final hexIndex = _findHeaderIndex(header, const ['hex']);
    final redIndex = _findHeaderIndex(header, const ['r']);
    final greenIndex = _findHeaderIndex(header, const ['g']);
    final blueIndex = _findHeaderIndex(header, const ['b']);

    final colors = <ColorEntry>[];
    for (final line in lines.skip(1)) {
      final row = _parseRow(line);
      final name = _readCell(row, nameIndex);
      String? hex = _readCell(row, hexIndex);

      if (hex == null || hex.isEmpty) {
        final red = _toInt(_readCell(row, redIndex));
        final green = _toInt(_readCell(row, greenIndex));
        final blue = _toInt(_readCell(row, blueIndex));
        if (red != null && green != null && blue != null) {
          hex = rgbToHex(red, green, blue);
        }
      }

      if (hex == null || hex.isEmpty) {
        continue;
      }

      final colorName = name == null || name.isEmpty
          ? 'Color ${colors.length + 1}'
          : name;
      colors.add(
        ColorEntry(
          name: colorName,
          hexCode: normalizeHex(hex),
        ),
      );
    }

    return Palette(
      name: fallbackName,
      colors: colors,
      sourcePath: sourcePath,
      sourceFormat: 'csv',
      sourceGroup: sourceGroup,
    );
  }

  Palette decodeBytes(
    List<int> bytes, {
    required String fallbackName,
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

  String encodeString(Palette palette) {
    final buffer = StringBuffer();
    buffer.writeln('name,hex');
    for (final color in palette.colors) {
      buffer
        ..write(_escapeCell(color.name))
        ..write(',')
        ..writeln(_escapeCell(color.hexCode));
    }
    return buffer.toString();
  }

  List<int> encodeBytes(Palette palette) {
    return utf8.encode(encodeString(palette));
  }

  List<String> _parseRow(String line) {
    final cells = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var index = 0; index < line.length; index++) {
      final char = line[index];
      if (char == '"') {
        if (inQuotes && index + 1 < line.length && line[index + 1] == '"') {
          current.write('"');
          index += 1;
          continue;
        }
        inQuotes = !inQuotes;
        continue;
      }

      if (char == ',' && !inQuotes) {
        cells.add(current.toString());
        current = StringBuffer();
        continue;
      }
      current.write(char);
    }

    cells.add(current.toString());
    return cells;
  }

  int _findHeaderIndex(List<String> header, List<String> aliases) {
    for (final alias in aliases) {
      final index = header.indexOf(alias);
      if (index >= 0) {
        return index;
      }
    }
    return -1;
  }

  String? _readCell(List<String> row, int index) {
    if (index < 0 || index >= row.length) {
      return null;
    }
    return row[index].trim();
  }

  int? _toInt(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return int.tryParse(value);
  }

  String _escapeCell(String value) {
    final escaped = value.replaceAll('"', '""');
    final needsQuote = escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n') ||
        escaped.contains('\r');
    return needsQuote ? '"$escaped"' : escaped;
  }
}
