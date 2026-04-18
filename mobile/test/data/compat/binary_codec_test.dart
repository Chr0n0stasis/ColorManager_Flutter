import 'package:flutter_test/flutter_test.dart';
import 'package:color_manager_mobile/data/compat/originlab_pal_codec.dart';
import 'package:color_manager_mobile/data/compat/palette_ase_codec.dart';
import 'package:color_manager_mobile/domain/color_entry.dart';
import 'package:color_manager_mobile/domain/palette.dart';

void main() {
  group('Binary compatibility codecs', () {
    test('ASE codec round-trip keeps names and hex colors', () {
      const aseCodec = PaletteAseCodec();
      final palette = Palette(
        name: 'ase',
        colors: [
          ColorEntry(name: 'A', hexCode: '#112233'),
          ColorEntry(name: 'B', hexCode: '#ABCDEF'),
        ],
      );

      final bytes = aseCodec.encode(palette);
      final decoded = aseCodec.decode(bytes, fallbackName: 'fallback');

      expect(decoded.colors.length, 2);
      expect(decoded.colors[0].name, 'A');
      expect(decoded.colors[1].hexCode, '#ABCDEF');
    });

    test('PAL codec decode and gradient encode are structurally valid', () {
      const palCodec = OriginlabPalCodec();
      final palette = Palette(
        name: 'pal',
        colors: [
          ColorEntry(name: 'Start', hexCode: '#000000'),
          ColorEntry(name: 'End', hexCode: '#FFFFFF'),
        ],
      );

      final bytes = palCodec.encodeGradient(palette, steps: 16);
      final decoded = palCodec.decode(bytes, fallbackName: 'decoded');

      expect(decoded.colors.length, 16);
      expect(decoded.colors.first.hexCode, '#000000');
      expect(decoded.colors.last.hexCode, '#FFFFFF');
    });
  });
}
