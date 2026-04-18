import 'package:flutter_test/flutter_test.dart';
import 'package:color_manager_mobile/data/compat/palette_csv_codec.dart';
import 'package:color_manager_mobile/domain/color_entry.dart';
import 'package:color_manager_mobile/domain/palette.dart';

void main() {
  group('PaletteCsvCodec', () {
    const codec = PaletteCsvCodec();

    test('decodes name,hex CSV', () {
      const input = 'name,hex\nA,#112233\nB,#445566\n';
      final palette = codec.decode(input, fallbackName: 'demo');

      expect(palette.name, 'demo');
      expect(palette.colors.length, 2);
      expect(palette.colors[0].name, 'A');
      expect(palette.colors[1].hexCode, '#445566');
    });

    test('decodes r,g,b fallback columns', () {
      const input = 'name,r,g,b\nmix,15,31,255\n';
      final palette = codec.decode(input, fallbackName: 'rgb');

      expect(palette.colors.length, 1);
      expect(palette.colors.first.hexCode, '#0F1FFF');
    });

    test('encodes desktop-compatible header', () {
      final palette = Palette(
        name: 'export',
        colors: [ColorEntry(name: 'A', hexCode: '#AABBCC')],
      );

      final output = codec.encode(palette);
      expect(output.startsWith('name,hex\n'), isTrue);
      expect(output.contains('A,#AABBCC'), isTrue);
    });
  });
}
