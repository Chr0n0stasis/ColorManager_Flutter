import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../compat/hex_utils.dart';
import '../models/color_entry.dart';
import '../models/palette.dart';

class PaletteColorSampler {
  const PaletteColorSampler({
    this.maxColors = 16,
    this.maxDimension = 512,
  });

  final int maxColors;
  final int maxDimension;

  Palette sampleFromImageBytes(
    List<int> bytes, {
    required String fallbackName,
    String? sourcePath,
    String sourceFormat = 'image',
    String sourceGroup = 'materials',
    int? maxColorsOverride,
  }) {
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) {
      throw const FormatException('Unsupported image content.');
    }

    return sampleFromDecodedImage(
      decoded,
      fallbackName: fallbackName,
      sourcePath: sourcePath,
      sourceFormat: sourceFormat,
      sourceGroup: sourceGroup,
      maxColorsOverride: maxColorsOverride,
    );
  }

  Palette sampleFromDecodedImage(
    img.Image decoded, {
    required String fallbackName,
    String? sourcePath,
    String sourceFormat = 'image',
    String sourceGroup = 'materials',
    int? maxColorsOverride,
  }) {
    final effectiveMaxColors =
        (maxColorsOverride ?? maxColors).clamp(1, 256).toInt();

    final sampled = _resizeForSampling(decoded);
    final bins = <int, int>{};

    for (var y = 0; y < sampled.height; y += 1) {
      for (var x = 0; x < sampled.width; x += 1) {
        final pixel = sampled.getPixel(x, y);
        final alpha = clampChannel(pixel.a);
        if (alpha < 24) {
          continue;
        }

        final red = clampChannel(pixel.r);
        final green = clampChannel(pixel.g);
        final blue = clampChannel(pixel.b);
        final key = _toColorBin(red, green, blue);
        bins.update(key, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    if (bins.isEmpty) {
      throw const FormatException('No visible pixels were found in image.');
    }

    final sortedBins = bins.entries.toList(growable: false)
      ..sort((left, right) => right.value.compareTo(left.value));

    final colors = <ColorEntry>[];
    final seenHex = <String>{};
    for (final entry in sortedBins) {
      if (colors.length >= effectiveMaxColors) {
        break;
      }
      final color = _decodeColorBin(entry.key, colors.length + 1);
      if (seenHex.add(color.hexCode)) {
        colors.add(color);
      }
    }

    return Palette(
      name: fallbackName,
      colors: colors,
      sourcePath: sourcePath,
      sourceFormat: sourceFormat,
      sourceGroup: sourceGroup,
    );
  }

  ColorEntry pickColorAt(
    List<int> bytes, {
    required double normalizedX,
    required double normalizedY,
    String name = 'Picked Color',
  }) {
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) {
      throw const FormatException('Unsupported image content.');
    }

    final x = (normalizedX.clamp(0.0, 1.0) * (decoded.width - 1)).round();
    final y = (normalizedY.clamp(0.0, 1.0) * (decoded.height - 1)).round();
    final pixel = decoded.getPixel(x, y);
    final red = clampChannel(pixel.r);
    final green = clampChannel(pixel.g);
    final blue = clampChannel(pixel.b);

    return ColorEntry(
      name: name,
      hexCode: rgbToHex(red, green, blue),
    );
  }

  img.Image _resizeForSampling(img.Image source) {
    final longestEdge = math.max(source.width, source.height);
    if (longestEdge <= maxDimension) {
      return source;
    }

    final scale = maxDimension / longestEdge;
    final targetWidth = math.max(1, (source.width * scale).round());
    final targetHeight = math.max(1, (source.height * scale).round());

    return img.copyResize(
      source,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.average,
    );
  }

  int _toColorBin(int red, int green, int blue) {
    return ((red >> 3) << 10) | ((green >> 3) << 5) | (blue >> 3);
  }

  ColorEntry _decodeColorBin(int key, int index) {
    final red = clampChannel(((key >> 10) & 0x1F) * 8 + 4);
    final green = clampChannel(((key >> 5) & 0x1F) * 8 + 4);
    final blue = clampChannel((key & 0x1F) * 8 + 4);

    return ColorEntry(
      name: 'Extracted $index',
      hexCode: rgbToHex(red, green, blue),
    );
  }
}
