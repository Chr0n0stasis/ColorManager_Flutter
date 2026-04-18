import '../../domain/color_entry.dart';
import '../../domain/palette.dart';

class PaletteCsvCodec {
  const PaletteCsvCodec();

  Palette decode(
    String csvText, {
    required String fallbackName,
    String sourceGroup = 'materials',
    String sourceFormat = 'csv',
    String? sourcePath,
  }) {
    final rows = csvText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map(_parseCsvLine)
        .where((row) => row.isNotEmpty)
        .toList(growable: false);

    if (rows.isEmpty) {
      return Palette(
        name: fallbackName,
        colors: const <ColorEntry>[],
        sourceGroup: sourceGroup,
        sourceFormat: sourceFormat,
        sourcePath: sourcePath,
      );
    }

    final header = rows.first.map((column) => column.trim().toLowerCase()).toList(growable: false);
    final body = rows.skip(1);

    final nameIndex = _indexOfAny(header, const ['name']);
    final hexIndex = _indexOfAny(header, const ['hex']);
    final redIndex = _indexOfAny(header, const ['r']);
    final greenIndex = _indexOfAny(header, const ['g']);
    final blueIndex = _indexOfAny(header, const ['b']);

    final colors = <ColorEntry>[];

    for (final row in body) {
      String? hex;
      if (hexIndex >= 0 && hexIndex < row.length) {
        final raw = row[hexIndex].trim();
        if (raw.isNotEmpty) {
          hex = raw;
        }
      }

      if (hex == null && redIndex >= 0 && greenIndex >= 0 && blueIndex >= 0) {
        if (redIndex < row.length && greenIndex < row.length && blueIndex < row.length) {
          final red = int.tryParse(row[redIndex].trim());
          final green = int.tryParse(row[greenIndex].trim());
          final blue = int.tryParse(row[blueIndex].trim());
          if (red != null && green != null && blue != null) {
            hex = ColorEntry.rgbToHex(red, green, blue);
          }
        }
      }

      if (hex == null) {
        continue;
      }

      var name = 'Color ${colors.length + 1}';
      if (nameIndex >= 0 && nameIndex < row.length) {
        final rawName = row[nameIndex].trim();
        if (rawName.isNotEmpty) {
          name = rawName;
        }
      }

      colors.add(ColorEntry(name: name, hexCode: hex));
    }

    return Palette(
      name: fallbackName,
      colors: colors,
      sourceGroup: sourceGroup,
      sourceFormat: sourceFormat,
      sourcePath: sourcePath,
    );
  }

  String encode(Palette palette) {
    final buffer = StringBuffer('name,hex\n');
    for (final color in palette.colors) {
      buffer
        ..write(_escapeCsv(color.name))
        ..write(',')
        ..write(_escapeCsv(color.hexCode))
        ..write('\n');
    }
    return buffer.toString();
  }

  int _indexOfAny(List<String> header, List<String> candidates) {
    for (var index = 0; index < header.length; index++) {
      if (candidates.contains(header[index])) {
        return index;
      }
    }
    return -1;
  }

  String _escapeCsv(String value) {
    if (!value.contains(',') && !value.contains('"') && !value.contains('\n')) {
      return value;
    }
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  List<String> _parseCsvLine(String line) {
    final values = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;

    for (var index = 0; index < line.length; index++) {
      final char = line[index];

      if (char == '"') {
        if (inQuotes && index + 1 < line.length && line[index + 1] == '"') {
          cell.write('"');
          index += 1;
          continue;
        }
        inQuotes = !inQuotes;
        continue;
      }

      if (char == ',' && !inQuotes) {
        values.add(cell.toString());
        cell.clear();
        continue;
      }

      cell.write(char);
    }

    values.add(cell.toString());
    return values;
  }
}
