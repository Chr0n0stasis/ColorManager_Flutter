import 'package:color_manager_mobile/color_manager_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('PaletteColorSampler', () {
    test('extracts dominant colors from image bytes', () {
      final image = img.Image(width: 3, height: 1)
        ..setPixelRgb(0, 0, 255, 0, 0)
        ..setPixelRgb(1, 0, 0, 255, 0)
        ..setPixelRgb(2, 0, 0, 0, 255);

      final bytes = img.encodePng(image);
      final sampler = PaletteColorSampler(maxColors: 8);
      final palette = sampler.sampleFromImageBytes(
        bytes,
        fallbackName: 'sample',
      );

      expect(palette.name, 'sample');
      expect(palette.colors.length, greaterThanOrEqualTo(3));

      final hasRed = palette.colors.any((color) {
        final rgb = color.rgb;
        return rgb[0] > 220 && rgb[1] < 40 && rgb[2] < 40;
      });
      final hasGreen = palette.colors.any((color) {
        final rgb = color.rgb;
        return rgb[1] > 220 && rgb[0] < 40 && rgb[2] < 40;
      });
      final hasBlue = palette.colors.any((color) {
        final rgb = color.rgb;
        return rgb[2] > 220 && rgb[0] < 40 && rgb[1] < 40;
      });

      expect(hasRed, isTrue);
      expect(hasGreen, isTrue);
      expect(hasBlue, isTrue);
    });
  });
}
