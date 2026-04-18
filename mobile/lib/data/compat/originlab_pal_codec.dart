import 'dart:typed_data';

import '../../domain/color_entry.dart';
import '../../domain/palette.dart';

class OriginlabPalCodec {
  const OriginlabPalCodec();

  Palette decode(
    Uint8List data, {
    required String fallbackName,
    String sourceFormat = 'pal',
    String sourceGroup = 'materials',
    String? sourcePath,
  }) {
    if (data.length < 24 || !_match(data, 0, 'RIFF') || !_match(data, 8, 'PAL ')) {
      throw const FormatException('Unsupported PAL format.');
    }

    if (!_match(data, 12, 'data')) {
      throw const FormatException('PAL data chunk is missing.');
    }

    final chunkSize = _uint32LE(data, 16);
    final payloadStart = 20;
    final payloadEnd = payloadStart + chunkSize;
    if (payloadEnd > data.length || payloadStart + 4 > data.length) {
      throw const FormatException('Invalid PAL payload length.');
    }

    final version = _uint16LE(data, payloadStart);
    final count = _uint16LE(data, payloadStart + 2);
    if (version != 0x0300) {
      throw FormatException('Unsupported PAL version: $version');
    }

    final colors = <ColorEntry>[];
    var offset = payloadStart + 4;

    for (var index = 0; index < count; index += 1) {
      if (offset + 4 > payloadEnd) {
        break;
      }
      final blue = data[offset];
      final green = data[offset + 1];
      final red = data[offset + 2];
      final hexCode = ColorEntry.rgbToHex(red, green, blue);
      colors.add(ColorEntry(name: 'Color ${index + 1}', hexCode: hexCode));
      offset += 4;
    }

    return Palette(
      name: fallbackName,
      colors: colors,
      sourceFormat: sourceFormat,
      sourceGroup: sourceGroup,
      sourcePath: sourcePath,
    );
  }

  Uint8List encodeGradient(Palette palette, {int steps = 256}) {
    final rgbValues = palette.colors.map((entry) => entry.rgb).toList(growable: false);
    if (rgbValues.isEmpty) {
      return Uint8List(0);
    }

    final gradient = <List<int>>[];
    if (rgbValues.length == 1) {
      for (var index = 0; index < steps; index += 1) {
        gradient.add(rgbValues.first);
      }
    } else {
      for (var index = 0; index < steps; index += 1) {
        final position = index / (steps - 1);
        final scaled = position * (rgbValues.length - 1);
        final leftIndex = scaled.floor();
        final rightIndex = (leftIndex + 1).clamp(0, rgbValues.length - 1);
        final ratio = scaled - leftIndex;
        final left = rgbValues[leftIndex];
        final right = rgbValues[rightIndex];
        gradient.add([
          (left[0] + (right[0] - left[0]) * ratio).round(),
          (left[1] + (right[1] - left[1]) * ratio).round(),
          (left[2] + (right[2] - left[2]) * ratio).round(),
        ]);
      }
    }

    final payload = BytesBuilder();
    payload.add(_uint16LE(0x0300));
    payload.add(_uint16LE(gradient.length));
    for (final rgb in gradient) {
      payload.add([rgb[2], rgb[1], rgb[0], 0x00]);
    }

    final payloadBytes = payload.toBytes();
    final dataChunk = BytesBuilder();
    dataChunk.add('data'.codeUnits);
    dataChunk.add(_uint32LE(payloadBytes.length));
    dataChunk.add(payloadBytes);
    final dataChunkBytes = dataChunk.toBytes();

    final riffPayload = BytesBuilder();
    riffPayload.add('PAL '.codeUnits);
    riffPayload.add(dataChunkBytes);
    final riffPayloadBytes = riffPayload.toBytes();

    final out = BytesBuilder();
    out.add('RIFF'.codeUnits);
    out.add(_uint32LE(riffPayloadBytes.length));
    out.add(riffPayloadBytes);
    return out.toBytes();
  }

  bool _match(Uint8List data, int offset, String text) {
    final bytes = text.codeUnits;
    if (offset + bytes.length > data.length) {
      return false;
    }
    for (var i = 0; i < bytes.length; i += 1) {
      if (data[offset + i] != bytes[i]) {
        return false;
      }
    }
    return true;
  }

  int _uint16LE(Uint8List data, int offset) {
    return data[offset] | (data[offset + 1] << 8);
  }

  int _uint32LE(Uint8List data, int offset) {
    return data[offset] |
        (data[offset + 1] << 8) |
        (data[offset + 2] << 16) |
        (data[offset + 3] << 24);
  }

  Uint8List _uint16LE(int value) {
    final bytes = ByteData(2);
    bytes.setUint16(0, value, Endian.little);
    return bytes.buffer.asUint8List();
  }

  Uint8List _uint32LE(int value) {
    final bytes = ByteData(4);
    bytes.setUint32(0, value, Endian.little);
    return bytes.buffer.asUint8List();
  }
}
