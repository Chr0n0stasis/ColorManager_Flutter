import 'package:flutter_test/flutter_test.dart';

import '../../../lib/data/compat/palette_ase_codec.dart';
import '../../../lib/domain/color_entry.dart';
import '../../../lib/domain/palette.dart';

void main() {
  group('PaletteAseCodec', () {
    const codec = PaletteAseCodec();

    test('round-trips RGB colors', () {
      final source = Palette(
        name: 'ASE Source',
        colors: [
          ColorEntry(name: 'Deep', hexCode: '#102030'),
          ColorEntry(name: 'Light', hexCode: '#F0E0D0'),
        ],
      );

      final bytes = codec.encode(source);
      final decoded = codec.decode(bytes, fallbackName: 'Fallback');

      expect(decoded.name, 'Fallback');
      expect(decoded.colors.length, 2);
      expect(decoded.colors[0].name, 'Deep');
      expect(decoded.colors[0].hexCode, '#102030');
      expect(decoded.colors[1].name, 'Light');
      expect(decoded.colors[1].hexCode, '#F0E0D0');
    });
  });
}
