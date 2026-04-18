import 'dart:convert';
import 'dart:typed_data';

import '../branding/upstream_branding.dart';
import '../models/color_entry.dart';
import '../models/palette.dart';
import 'hex_utils.dart';

class PaletteAseCodec {
  const PaletteAseCodec();

  Palette decodeBytes(
    List<int> bytes, {
    required String fallbackName,
    String? sourcePath,
    String sourceGroup = 'materials',
  }) {
    if (bytes.length < 12) {
      throw const FormatException('Invalid ASE content');
    }

    final data = Uint8List.fromList(bytes);
    final signature = ascii.decode(data.sublist(0, 4), allowInvalid: true);
    if (signature != 'ASEF') {
      throw const FormatException('Invalid ASE signature');
    }

    final headerReader = _BigEndianReader(data, startOffset: 4);
    headerReader.readUint16();
    headerReader.readUint16();
    headerReader.readUint32();

    var offset = 12;
    var paletteName = fallbackName;
    final colors = <ColorEntry>[];

    while (offset + 6 <= data.length) {
      final blockHeader = _BigEndianReader(data, startOffset: offset);
      final blockType = blockHeader.readUint16();
      final blockLength = blockHeader.readUint32();
      final blockStart = offset + 6;
      final blockEnd = blockStart + blockLength;
      if (blockEnd > data.length) {
        break;
      }

      final blockData = Uint8List.sublistView(data, blockStart, blockEnd);
      offset = blockEnd;

      if (blockType == 0xC001) {
        final reader = _BigEndianReader(blockData);
        final groupName = reader.readUtf16String();
        if (groupName.isNotEmpty) {
          paletteName = groupName;
        }
        continue;
      }

      if (blockType != 0x0001) {
        continue;
      }

      final reader = _BigEndianReader(blockData);
      final colorName = reader.readUtf16String();
      if (reader.remaining < 4) {
        continue;
      }
      final model = reader.readAscii(4).trim();

      String? hexCode;
      if (model == 'RGB' && reader.remaining >= 12) {
        final red = (clamp01(reader.readFloat32()) * 255).round();
        final green = (clamp01(reader.readFloat32()) * 255).round();
        final blue = (clamp01(reader.readFloat32()) * 255).round();
        hexCode = rgbToHex(red, green, blue);
      } else if (model == 'GRAY' && reader.remaining >= 4) {
        final gray = (clamp01(reader.readFloat32()) * 255).round();
        hexCode = rgbToHex(gray, gray, gray);
      } else if (model == 'CMYK' && reader.remaining >= 16) {
        final c = reader.readFloat32();
        final m = reader.readFloat32();
        final y = reader.readFloat32();
        final k = reader.readFloat32();
        hexCode = cmykToHex(c, m, y, k);
      }

      if (hexCode == null) {
        continue;
      }

      colors.add(
        ColorEntry(
          name: colorName.isEmpty ? 'Color ${colors.length + 1}' : colorName,
          hexCode: hexCode,
        ),
      );
    }

    return Palette(
      name: paletteName,
      colors: colors,
      sourcePath: sourcePath,
      sourceFormat: 'ase',
      sourceGroup: sourceGroup,
    );
  }

  List<int> encodeBytes(Palette palette) {
    final blocks = <int>[];

    for (var index = 0; index < palette.colors.length; index++) {
      final color = palette.colors[index];
      final name = buildExportColorName(color.name, index + 1);
      final encodedName = _encodeUtf16Be('$name\u0000');
      final payload = <int>[]
        ..addAll(_uint16Be(name.runes.length + 1))
        ..addAll(encodedName)
        ..addAll(ascii.encode('RGB '));

      final rgb = color.rgb;
      payload
        ..addAll(_float32Be(rgb[0] / 255.0))
        ..addAll(_float32Be(rgb[1] / 255.0))
        ..addAll(_float32Be(rgb[2] / 255.0))
        ..addAll(_uint16Be(0));

      blocks
        ..addAll(_uint16Be(0x0001))
        ..addAll(_uint32Be(payload.length))
        ..addAll(payload);
    }

    return <int>[]
      ..addAll(ascii.encode('ASEF'))
      ..addAll(_uint16Be(1))
      ..addAll(_uint16Be(0))
      ..addAll(_uint32Be(palette.colors.length))
      ..addAll(blocks);
  }

  double clamp01(double value) {
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }

  String cmykToHex(double c, double m, double y, double k) {
    final red = (255 * (1 - clamp01(c)) * (1 - clamp01(k))).round();
    final green = (255 * (1 - clamp01(m)) * (1 - clamp01(k))).round();
    final blue = (255 * (1 - clamp01(y)) * (1 - clamp01(k))).round();
    return rgbToHex(red, green, blue);
  }

  List<int> _uint16Be(int value) {
    final data = ByteData(2)..setUint16(0, value, Endian.big);
    return data.buffer.asUint8List();
  }

  List<int> _uint32Be(int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.big);
    return data.buffer.asUint8List();
  }

  List<int> _float32Be(double value) {
    final data = ByteData(4)..setFloat32(0, value, Endian.big);
    return data.buffer.asUint8List();
  }

  List<int> _encodeUtf16Be(String text) {
    final codeUnits = text.codeUnits;
    final data = ByteData(codeUnits.length * 2);
    for (var index = 0; index < codeUnits.length; index++) {
      data.setUint16(index * 2, codeUnits[index], Endian.big);
    }
    return data.buffer.asUint8List();
  }
}

class _BigEndianReader {
  _BigEndianReader(this.data, {int startOffset = 0}) : _offset = startOffset;

  final Uint8List data;
  int _offset;

  int get remaining => data.length - _offset;

  int readUint16() {
    final value = ByteData.sublistView(data, _offset, _offset + 2)
        .getUint16(0, Endian.big);
    _offset += 2;
    return value;
  }

  int readUint32() {
    final value = ByteData.sublistView(data, _offset, _offset + 4)
        .getUint32(0, Endian.big);
    _offset += 4;
    return value;
  }

  double readFloat32() {
    final value = ByteData.sublistView(data, _offset, _offset + 4)
        .getFloat32(0, Endian.big);
    _offset += 4;
    return value;
  }

  String readAscii(int length) {
    final value = ascii.decode(
      data.sublist(_offset, _offset + length),
      allowInvalid: true,
    );
    _offset += length;
    return value;
  }

  String readUtf16String() {
    final charCount = readUint16();
    final byteLength = charCount * 2;
    if (remaining < byteLength) {
      _offset = data.length;
      return '';
    }

    final rawBytes = Uint8List.sublistView(data, _offset, _offset + byteLength);
    _offset += byteLength;

    final rawData = ByteData.sublistView(rawBytes);
    final codeUnits = <int>[];
    for (var index = 0; index + 1 < rawBytes.length; index += 2) {
      codeUnits.add(rawData.getUint16(index, Endian.big));
    }

    final text = String.fromCharCodes(codeUnits);
    return text.replaceAll(String.fromCharCode(0), '');
  }
}
