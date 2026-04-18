import 'package:flutter_test/flutter_test.dart';

import '../../../lib/data/compat/originlab_pal_codec.dart';
import '../../../lib/domain/color_entry.dart';
import '../../../lib/domain/palette.dart';

void main() {
  group('OriginlabPalCodec', () {
    const codec = OriginlabPalCodec();

    test('encodes gradient and decodes standard PAL payload', () {
      final palette = Palette(
        name: 'PAL Source',
        colors: [
          ColorEntry(name: 'Start', hexCode: '#000000'),
          ColorEntry(name: 'End', hexCode: '#FFFFFF'),
        ],
      );

      final bytes = codec.encodeGradient(palette, steps: 4);
      final decoded = codec.decode(bytes, fallbackName: 'DecodedPAL');

      expect(decoded.name, 'DecodedPAL');
      expect(decoded.colors.length, 4);
      expect(decoded.colors.first.hexCode, '#000000');
      expect(decoded.colors.last.hexCode, '#FFFFFF');
    });
  });
}
