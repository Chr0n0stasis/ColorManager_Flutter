import 'package:color_manager_mobile/color_manager_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaletteGenerationService', () {
    const service = PaletteGenerationService();

    test('two-color gradient returns configured size', () {
      final colors = service.generateTwoColorGradient(
        startHex: '#000000',
        endHex: '#FFFFFF',
        steps: 9,
      );

      expect(colors.length, equals(9));
      expect(colors.first.hexCode, equals('#000000'));
      expect(colors.last.hexCode, equals('#FFFFFF'));
    });

    test('complementary generation includes contrast endpoint', () {
      final colors = service.generateComplementary(
        baseHex: '#336699',
        steps: 6,
      );

      expect(colors.length, equals(6));
      expect(colors.first.hexCode, equals('#336699'));
      expect(colors.last.hexCode, isNot(equals('#336699')));
    });

    test('lightness sort orders from dark to bright', () {
      final sorted = service.sortByLightness(<ColorEntry>[
        ColorEntry(name: 'white', hexCode: '#FFFFFF'),
        ColorEntry(name: 'mid', hexCode: '#777777'),
        ColorEntry(name: 'black', hexCode: '#000000'),
      ]);

      expect(sorted[0].hexCode, equals('#000000'));
      expect(sorted[2].hexCode, equals('#FFFFFF'));
    });
  });
}
