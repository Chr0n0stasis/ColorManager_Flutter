import 'dart:math' as math;

import '../compat/hex_utils.dart';
import '../models/color_entry.dart';

enum PaletteGenerationKind {
  twoColorGradient,
  analogous,
  complementary,
  toWhite,
}

enum WhiteTemperature {
  warm,
  neutral,
  cool,
}

class PaletteGenerationService {
  const PaletteGenerationService();

  List<ColorEntry> generate({
    required PaletteGenerationKind kind,
    required String baseHex,
    required String secondaryHex,
    required int steps,
    required WhiteTemperature whiteTemperature,
  }) {
    switch (kind) {
      case PaletteGenerationKind.twoColorGradient:
        return generateTwoColorGradient(
          startHex: baseHex,
          endHex: secondaryHex,
          steps: steps,
        );
      case PaletteGenerationKind.analogous:
        return generateAnalogous(baseHex: baseHex, count: math.max(5, steps));
      case PaletteGenerationKind.complementary:
        return generateComplementary(baseHex: baseHex, steps: steps);
      case PaletteGenerationKind.toWhite:
        return generateToWhite(
          baseHex: baseHex,
          steps: steps,
          temperature: whiteTemperature,
        );
    }
  }

  List<ColorEntry> sortByLightness(
    List<ColorEntry> colors, {
    bool descending = false,
  }) {
    final sorted = List<ColorEntry>.from(colors);
    sorted.sort((a, b) {
      final left = _relativeLuminance(a.rgb);
      final right = _relativeLuminance(b.rgb);
      return descending ? right.compareTo(left) : left.compareTo(right);
    });
    return sorted;
  }

  List<ColorEntry> generateTwoColorGradient({
    required String startHex,
    required String endHex,
    required int steps,
  }) {
    final left = _normalizeRgb(startHex);
    final right = _normalizeRgb(endHex);
    return _interpolateList(
      anchors: <List<int>>[left, right],
      steps: steps,
      namePrefix: 'Gradient',
    );
  }

  List<ColorEntry> generateHeatmap({
    required String baseHex,
    required int steps,
  }) {
    final base = _normalizeRgb(baseHex);
    final anchors = <List<int>>[
      _scaleRgb(base, 0.42),
      _scaleRgb(base, 0.66),
      base,
      _liftToWhite(base, 0.28),
      _liftToWhite(base, 0.52),
      _liftToWhite(base, 0.72),
    ];
    return _interpolateList(
      anchors: anchors,
      steps: steps,
      namePrefix: 'Heat',
    );
  }

  List<ColorEntry> generateAnalogous({
    required String baseHex,
    int count = 7,
  }) {
    final rgb = _normalizeRgb(baseHex);
    final hsv = _rgbToHsv(rgb[0], rgb[1], rgb[2]);
    final hue = hsv[0];
    final sat = hsv[1];
    final val = hsv[2];

    final result = <ColorEntry>[];
    final size = math.max(3, count);
    for (var i = 0; i < size; i++) {
      final t = size == 1 ? 0.0 : (i / (size - 1));
      final shiftedHue = (hue - 30.0 + t * 60.0) % 360.0;
      final shifted = _hsvToRgb(shiftedHue, sat, val);
      result.add(
        ColorEntry(
          name: 'Analogous ${i + 1}',
          hexCode: rgbToHex(shifted[0], shifted[1], shifted[2]),
        ),
      );
    }
    return result;
  }

  List<ColorEntry> generateComplementary({
    required String baseHex,
    required int steps,
  }) {
    final rgb = _normalizeRgb(baseHex);
    final hsv = _rgbToHsv(rgb[0], rgb[1], rgb[2]);
    final complementHue = (hsv[0] + 180.0) % 360.0;
    final complement = _hsvToRgb(complementHue, hsv[1], hsv[2]);
    return _interpolateList(
      anchors: <List<int>>[rgb, complement],
      steps: steps,
      namePrefix: 'Complement',
    );
  }

  List<ColorEntry> generateToWhite({
    required String baseHex,
    required int steps,
    required WhiteTemperature temperature,
  }) {
    final from = _normalizeRgb(baseHex);
    final to = switch (temperature) {
      WhiteTemperature.warm => <int>[255, 244, 229],
      WhiteTemperature.neutral => <int>[255, 255, 255],
      WhiteTemperature.cool => <int>[240, 247, 255],
    };
    return _interpolateList(
      anchors: <List<int>>[from, to],
      steps: steps,
      namePrefix: 'ToWhite',
    );
  }

  List<ColorEntry> interpolateFromAnchors(
    List<ColorEntry> anchors, {
    required int steps,
    String namePrefix = 'Interpolated',
  }) {
    final rgbAnchors = anchors.map((item) => item.rgb).toList(growable: false);
    return _interpolateList(
      anchors: rgbAnchors,
      steps: steps,
      namePrefix: namePrefix,
    );
  }

  List<ColorEntry> _interpolateList({
    required List<List<int>> anchors,
    required int steps,
    required String namePrefix,
  }) {
    if (anchors.isEmpty) {
      return const <ColorEntry>[];
    }
    if (anchors.length == 1) {
      return <ColorEntry>[
        ColorEntry(
          name: '$namePrefix 1',
          hexCode:
              rgbToHex(anchors.first[0], anchors.first[1], anchors.first[2]),
        ),
      ];
    }

    final result = <ColorEntry>[];
    final size = math.max(2, steps);
    final segmentCount = anchors.length - 1;
    for (var i = 0; i < size; i++) {
      final progress = size == 1 ? 0.0 : (i / (size - 1));
      final scaled = progress * segmentCount;
      final segmentIndex = scaled.floor().clamp(0, segmentCount - 1);
      final localT = (scaled - segmentIndex).clamp(0.0, 1.0);
      final left = anchors[segmentIndex];
      final right = anchors[segmentIndex + 1];
      final red = _lerpChannel(left[0], right[0], localT);
      final green = _lerpChannel(left[1], right[1], localT);
      final blue = _lerpChannel(left[2], right[2], localT);
      result.add(
        ColorEntry(
          name: '$namePrefix ${i + 1}',
          hexCode: rgbToHex(red, green, blue),
        ),
      );
    }
    return result;
  }

  List<int> _normalizeRgb(String hex) {
    final normalized = normalizeHex(hex).replaceFirst('#', '');
    return <int>[
      int.parse(normalized.substring(0, 2), radix: 16),
      int.parse(normalized.substring(2, 4), radix: 16),
      int.parse(normalized.substring(4, 6), radix: 16),
    ];
  }

  int _lerpChannel(int left, int right, double t) {
    return (left + (right - left) * t).round().clamp(0, 255);
  }

  List<int> _scaleRgb(List<int> rgb, double factor) {
    final f = factor.clamp(0.0, 1.0);
    return <int>[
      (rgb[0] * f).round().clamp(0, 255),
      (rgb[1] * f).round().clamp(0, 255),
      (rgb[2] * f).round().clamp(0, 255),
    ];
  }

  List<int> _liftToWhite(List<int> rgb, double amount) {
    final a = amount.clamp(0.0, 1.0);
    return <int>[
      _lerpChannel(rgb[0], 255, a),
      _lerpChannel(rgb[1], 255, a),
      _lerpChannel(rgb[2], 255, a),
    ];
  }

  double _relativeLuminance(List<int> rgb) {
    final r = rgb[0] / 255.0;
    final g = rgb[1] / 255.0;
    final b = rgb[2] / 255.0;
    return (0.2126 * r) + (0.7152 * g) + (0.0722 * b);
  }

  List<double> _rgbToHsv(int r, int g, int b) {
    final red = r / 255.0;
    final green = g / 255.0;
    final blue = b / 255.0;
    final maxChannel = math.max(red, math.max(green, blue));
    final minChannel = math.min(red, math.min(green, blue));
    final delta = maxChannel - minChannel;

    var hue = 0.0;
    if (delta != 0) {
      if (maxChannel == red) {
        hue = 60.0 * (((green - blue) / delta) % 6.0);
      } else if (maxChannel == green) {
        hue = 60.0 * (((blue - red) / delta) + 2.0);
      } else {
        hue = 60.0 * (((red - green) / delta) + 4.0);
      }
    }
    if (hue < 0) {
      hue += 360.0;
    }

    final saturation = maxChannel == 0 ? 0.0 : delta / maxChannel;
    final value = maxChannel;
    return <double>[hue, saturation, value];
  }

  List<int> _hsvToRgb(double hue, double saturation, double value) {
    final c = value * saturation;
    final x = c * (1 - (((hue / 60.0) % 2) - 1).abs());
    final m = value - c;

    var red = 0.0;
    var green = 0.0;
    var blue = 0.0;

    if (hue < 60) {
      red = c;
      green = x;
    } else if (hue < 120) {
      red = x;
      green = c;
    } else if (hue < 180) {
      green = c;
      blue = x;
    } else if (hue < 240) {
      green = x;
      blue = c;
    } else if (hue < 300) {
      red = x;
      blue = c;
    } else {
      red = c;
      blue = x;
    }

    return <int>[
      ((red + m) * 255).round().clamp(0, 255),
      ((green + m) * 255).round().clamp(0, 255),
      ((blue + m) * 255).round().clamp(0, 255),
    ];
  }
}
