import 'dart:typed_data';

import '../../domain/color_entry.dart';
import '../../domain/palette.dart';

class PaletteAseCodec {
  const PaletteAseCodec();

  Palette decode(
    Uint8List data, {
    required String fallbackName,
    String sourceFormat = 'ase',
    String sourceGroup = 'materials',
    String? sourcePath,
  }) {
    if (data.length < 12 || !_matchSignature(data, 0, 'ASEF')) {
      throw const FormatException('Invalid ASE signature.');
    }

    var offset = 12;
    var paletteName = fallbackName;
    final colors = <ColorEntry>[];

    while (offset + 6 <= data.length) {
      final blockType = _readUint16BE(data, offset);
      final blockLength = _readUint32BE(data, offset + 2);
      final blockStart = offset + 6;
      final blockEnd = blockStart + blockLength;

      if (blockEnd > data.length) {
        break;
      }

      if (blockType == 0xC001) {
        final parsed = _readUtf16String(data, blockStart);
        if (parsed.value.isNotEmpty) {
          paletteName = parsed.value;
        }
      }

      if (blockType == 0x0001) {
        final nameResult = _readUtf16String(data, blockStart);
        var cursor = nameResult.nextOffset;
        if (cursor + 4 > blockEnd) {
          offset = blockEnd;
          continue;
        }

        final model = String.fromCharCodes(data.sublist(cursor, cursor + 4)).trim();
        cursor += 4;

        String? hexCode;
        if (model == 'RGB' && cursor + 12 <= blockEnd) {
          final red = (_readFloat32BE(data, cursor) * 255).round();
          final green = (_readFloat32BE(data, cursor + 4) * 255).round();
          final blue = (_readFloat32BE(data, cursor + 8) * 255).round();
          hexCode = ColorEntry.rgbToHex(red, green, blue);
        } else if (model == 'GRAY' && cursor + 4 <= blockEnd) {
          final value = (_readFloat32BE(data, cursor) * 255).round();
          hexCode = ColorEntry.rgbToHex(value, value, value);
        } else if (model == 'CMYK' && cursor + 16 <= blockEnd) {
          final c = _readFloat32BE(data, cursor);
          final m = _readFloat32BE(data, cursor + 4);
          final y = _readFloat32BE(data, cursor + 8);
          final k = _readFloat32BE(data, cursor + 12);
          final red = (255 * (1 - c) * (1 - k)).round();
          final green = (255 * (1 - m) * (1 - k)).round();
          final blue = (255 * (1 - y) * (1 - k)).round();
          hexCode = ColorEntry.rgbToHex(red, green, blue);
        }

        if (hexCode != null) {
          final name = nameResult.value.isNotEmpty ? nameResult.value : 'Color ${colors.length + 1}';
          colors.add(ColorEntry(name: name, hexCode: hexCode));
        }
      }

      offset = blockEnd;
    }

    return Palette(
      name: paletteName,
      colors: colors,
      sourceFormat: sourceFormat,
      sourceGroup: sourceGroup,
      sourcePath: sourcePath,
    );
  }

  Uint8List encode(Palette palette) {
    final blocks = <Uint8List>[];

    for (var index = 0; index < palette.colors.length; index += 1) {
      final color = palette.colors[index];
      final name = color.name.isEmpty ? 'Color ${index + 1}' : color.name;
      final nameUnits = name.codeUnits;
      final encodedName = BytesBuilder();
      encodedName.add(_uint16BE(nameUnits.length + 1));
      for (final unit in nameUnits) {
        encodedName.add(_uint16BE(unit));
      }
      encodedName.add(const [0x00, 0x00]);

      final rgb = color.rgb;
      final payload = BytesBuilder();
      payload.add(encodedName.toBytes());
      payload.add('RGB '.codeUnits);
      payload.add(_float32BE(rgb[0] / 255));
      payload.add(_float32BE(rgb[1] / 255));
      payload.add(_float32BE(rgb[2] / 255));
      payload.add(_uint16BE(0));

      final payloadBytes = payload.toBytes();
      final block = BytesBuilder();
      block.add(_uint16BE(0x0001));
      block.add(_uint32BE(payloadBytes.length));
      block.add(payloadBytes);
      blocks.add(block.toBytes());
    }

    final out = BytesBuilder();
    out.add('ASEF'.codeUnits);
    out.add(_uint16BE(1));
    out.add(_uint16BE(0));
    out.add(_uint32BE(blocks.length));

    for (final block in blocks) {
      out.add(block);
    }

    return out.toBytes();
  }

  bool _matchSignature(Uint8List data, int offset, String signature) {
    final expected = signature.codeUnits;
    if (offset + expected.length > data.length) {
      return false;
    }
    for (var i = 0; i < expected.length; i += 1) {
      if (data[offset + i] != expected[i]) {
        return false;
      }
    }
    return true;
  }

  _Utf16Result _readUtf16String(Uint8List data, int offset) {
    if (offset + 2 > data.length) {
      return const _Utf16Result('', 0);
    }

    final codeUnitCount = _readUint16BE(data, offset);
    final payloadStart = offset + 2;
    final payloadLength = codeUnitCount * 2;
    final payloadEnd = payloadStart + payloadLength;

    if (payloadEnd > data.length) {
      return const _Utf16Result('', 0);
    }

    final units = <int>[];
    for (var cursor = payloadStart; cursor < payloadEnd; cursor += 2) {
      units.add(_readUint16BE(data, cursor));
    }

    if (units.isNotEmpty && units.last == 0) {
      units.removeLast();
    }

    return _Utf16Result(String.fromCharCodes(units), payloadEnd);
  }

  int _readUint16BE(Uint8List data, int offset) {
    return (data[offset] << 8) | data[offset + 1];
  }

  int _readUint32BE(Uint8List data, int offset) {
    return (data[offset] << 24) |
        (data[offset + 1] << 16) |
        (data[offset + 2] << 8) |
        data[offset + 3];
  }

  double _readFloat32BE(Uint8List data, int offset) {
    final byteData = ByteData.sublistView(data, offset, offset + 4);
    return byteData.getFloat32(0, Endian.big);
  }

  Uint8List _uint16BE(int value) {
    final bytes = ByteData(2);
    bytes.setUint16(0, value, Endian.big);
    return bytes.buffer.asUint8List();
  }

  Uint8List _uint32BE(int value) {
    final bytes = ByteData(4);
    bytes.setUint32(0, value, Endian.big);
    return bytes.buffer.asUint8List();
  }

  Uint8List _float32BE(double value) {
    final bytes = ByteData(4);
    bytes.setFloat32(0, value, Endian.big);
    return bytes.buffer.asUint8List();
  }
}

class _Utf16Result {
  const _Utf16Result(this.value, this.nextOffset);

  final String value;
  final int nextOffset;
}
