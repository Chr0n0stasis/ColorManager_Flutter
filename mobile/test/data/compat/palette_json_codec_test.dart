import 'package:flutter_test/flutter_test.dart';
import 'package:color_manager_mobile/data/compat/palette_json_codec.dart';
import 'package:color_manager_mobile/domain/color_entry.dart';
import 'package:color_manager_mobile/domain/palette.dart';

void main() {
  group('PaletteJsonCodec', () {
    const codec = PaletteJsonCodec();

    test('decodes desktop-compatible JSON structure', () {
      const input = '''
{
  "name": "demo",
  "colors": [
    {"name": "A", "hex": "#112233"},
    {"name": "B", "rgb": [255, 0, 127]}
  ]
}
''';

      final palette = codec.decode(input, fallbackName: 'fallback');

      expect(palette.name, 'demo');
      expect(palette.colors.length, 2);
      expect(palette.colors[0].hexCode, '#112233');
      expect(palette.colors[1].hexCode, '#FF007F');
    });

    test('encodes desktop-compatible JSON structure', () {
      final palette = Palette(
        name: 'export',
        colors: [
          ColorEntry(name: 'Color 1', hexCode: '#AABBCC'),
          ColorEntry(name: 'Color 2', hexCode: '#010203'),
        ],
      );

      final output = codec.encode(palette);
      expect(output.contains('"name": "export"'), isTrue);
      expect(output.contains('"hex": "#AABBCC"'), isTrue);
      expect(output.contains('"hex": "#010203"'), isTrue);
    });
  });
}
