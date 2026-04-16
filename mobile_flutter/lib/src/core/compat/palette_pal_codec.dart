import 'dart:typed_data';

import '../models/color_entry.dart';
import '../models/palette.dart';
import 'hex_utils.dart';

class PalettePalCodec {
  const PalettePalCodec();

  Palette decodeBytes(
    List<int> bytes, {
    required String fallbackName,
    String? sourcePath,
    String sourceGroup = 'materials',
  }) {
    final data = Uint8List.fromList(bytes);
    if (data.length < 24) {
      throw const FormatException('Unsupported PAL format');
    }
    if (!_equalsAscii(data, 0, 'RIFF') || !_equalsAscii(data, 8, 'PAL ')) {
      throw const FormatException('Unsupported PAL format');
    }
    if (!_equalsAscii(data, 12, 'data')) {
      throw const FormatException('Missing PAL data chunk');
    }

    final chunkSize = ByteData.sublistView(data, 16, 20).getUint32(0, Endian.little);
    final payloadStart = 20;
    final payloadEnd = payloadStart + chunkSize;
    if (payloadEnd > data.length || chunkSize < 4) {
      throw const FormatException('Corrupted PAL payload');
    }
    final payload = Uint8List.sublistView(data, payloadStart, payloadEnd);

    final version = ByteData.sublistView(payload, 0, 2).getUint16(0, Endian.little);
    if (version != 0x0300) {
      throw const FormatException('Unsupported PAL version');
    }
    final colorCount = ByteData.sublistView(payload, 2, 4).getUint16(0, Endian.little);

    final colors = <ColorEntry>[];
    var offset = 4;
    for (var index = 0; index < colorCount; index++) {
      if (offset + 4 > payload.length) {
        break;
      }
      final blue = payload[offset];
      final green = payload[offset + 1];
      final red = payload[offset + 2];
      colors.add(
        ColorEntry(
          name: 'Color ${index + 1}',
          hexCode: rgbToHex(red, green, blue),
        ),
      );
      offset += 4;
    }

    return Palette(
      name: fallbackName,
      colors: colors,
      sourcePath: sourcePath,
      sourceFormat: 'pal',
      sourceGroup: sourceGroup,
    );
  }

  List<int> encodeOriginLabBytes(Palette palette, {int steps = 256}) {
    final rgbValues = palette.colors.map((color) => color.rgb).toList();
    if (rgbValues.isEmpty) {
      return <int>[];
    }

    final gradient = <List<int>>[];
    if (rgbValues.length == 1) {
      for (var index = 0; index < steps; index++) {
        gradient.add(List<int>.from(rgbValues.first));
      }
    } else {
      for (var index = 0; index < steps; index++) {
        final position = index / (steps - 1);
        final scaled = position * (rgbValues.length - 1);
        final leftIndex = scaled.floor();
        final rightIndex = (leftIndex + 1).clamp(0, rgbValues.length - 1);
        final ratio = scaled - leftIndex;

        final left = rgbValues[leftIndex];
        final right = rgbValues[rightIndex];
        gradient.add(<int>[
          (left[0] + (right[0] - left[0]) * ratio).round(),
          (left[1] + (right[1] - left[1]) * ratio).round(),
          (left[2] + (right[2] - left[2]) * ratio).round(),
        ]);
      }
    }

    final paletteData = BytesBuilder();
    paletteData.add(_uint16Le(0x0300));
    paletteData.add(_uint16Le(gradient.length));
    for (final rgb in gradient) {
      paletteData.add(<int>[rgb[2], rgb[1], rgb[0], 0]);
    }

    final payload = paletteData.toBytes();
    final dataChunk = BytesBuilder()
      ..add('data'.codeUnits)
      ..add(_uint32Le(payload.length))
      ..add(payload);

    final riffPayload = BytesBuilder()
      ..add('PAL '.codeUnits)
      ..add(dataChunk.toBytes());

    final riffBytes = riffPayload.toBytes();
    final out = BytesBuilder()
      ..add('RIFF'.codeUnits)
      ..add(_uint32Le(riffBytes.length))
      ..add(riffBytes);
    return out.toBytes();
  }

  bool _equalsAscii(Uint8List data, int offset, String text) {
    if (offset + text.length > data.length) {
      return false;
    }
    for (var index = 0; index < text.length; index++) {
      if (data[offset + index] != text.codeUnitAt(index)) {
        return false;
      }
    }
    return true;
  }

  List<int> _uint16Le(int value) {
    final data = ByteData(2)..setUint16(0, value, Endian.little);
    return data.buffer.asUint8List();
  }

  List<int> _uint32Le(int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.little);
    return data.buffer.asUint8List();
  }
}
