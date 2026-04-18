import 'dart:convert';

import 'package:color_manager_mobile/color_manager_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Palette compatibility', () {
    final basePalette = Palette(
      name: 'Demo Palette',
      colors: <ColorEntry>[
        ColorEntry(name: 'Primary', hexCode: '#1D4ED8'),
        ColorEntry(name: 'Accent', hexCode: '#F97316'),
      ],
    );

    test('JSON codec keeps compatibility fields', () {
      const codec = PaletteJsonCodec();
      final encoded =
          codec.encodeString(basePalette, pretty: true, ensureAscii: true);
      final decoded = codec.decodeString(encoded, fallbackName: 'fallback');

      expect(decoded.name, equals(basePalette.name));
      expect(decoded.colors.length, equals(2));
      expect(decoded.colors.first.hexCode, equals('#1D4ED8'));
      expect(decoded.colors.last.hexCode, equals('#F97316'));
    });

    test('JSON ascii output escapes non-ascii text', () {
      const codec = PaletteJsonCodec();
      final nonAsciiName = 'Color ${String.fromCharCode(0x4E2D)}';
      final palette = Palette(
        name: 'N',
        colors: <ColorEntry>[
          ColorEntry(name: nonAsciiName, hexCode: '#112233')
        ],
      );

      final encoded =
          codec.encodeString(palette, pretty: false, ensureAscii: true);
      expect(encoded.contains('\\u4E2D'), isTrue);
    });

    test('CSV codec supports name+hex and rgb fallback', () {
      const codec = PaletteCsvCodec();
      const csv = 'name,hex,r,g,b\nA,#ABCDEF,,,\nB,,10,20,30\n';
      final decoded = codec.decodeString(csv, fallbackName: 'file');

      expect(decoded.colors.length, equals(2));
      expect(decoded.colors[0].hexCode, equals('#ABCDEF'));
      expect(decoded.colors[1].hexCode, equals('#0A141E'));
    });

    test('ASE codec roundtrip keeps color count and hex values', () {
      const codec = PaletteAseCodec();
      final bytes = codec.encodeBytes(basePalette);
      final decoded = codec.decodeBytes(bytes, fallbackName: 'fallback');

      expect(decoded.colors.length, equals(basePalette.colors.length));
      expect(decoded.colors[0].hexCode, equals('#1D4ED8'));
      expect(decoded.colors[1].hexCode, equals('#F97316'));
    });

    test('PAL codec writes OriginLab payload readable by decoder', () {
      const codec = PalettePalCodec();
      final bytes = codec.encodeOriginLabBytes(basePalette, steps: 16);
      final decoded = codec.decodeBytes(bytes, fallbackName: 'demo');

      expect(decoded.colors.length, equals(16));
      expect(decoded.colors.first.hexCode, equals('#1D4ED8'));
      expect(decoded.colors.last.hexCode, equals('#F97316'));
    });

    test('GPL codec roundtrip keeps names and hex', () {
      const codec = PaletteGplCodec();
      final bytes = codec.encodeBytes(basePalette);
      final decoded = codec.decodeBytes(bytes, fallbackName: 'fallback');

      expect(decoded.name, equals(basePalette.name));
      expect(decoded.colors.length, equals(basePalette.colors.length));
      expect(decoded.colors.first.name, equals('Primary'));
      expect(decoded.colors.first.hexCode, equals('#1D4ED8'));
      expect(decoded.colors.last.hexCode, equals('#F97316'));
    });

    test('CPT codec exports interpolated stops and decodes first stop', () {
      const codec = PaletteCptCodec();
      final encoded = codec.encodeBytes(basePalette);
      final decoded = codec.decodeBytes(encoded, fallbackName: 'fallback');

      expect(decoded.colors, isNotEmpty);
      expect(decoded.colors.first.hexCode, equals('#1D4ED8'));
    });

    test('Router dispatches extensions without creating new format', () {
      final router = PaletteCodecRouter();
      final jsonBytes =
          utf8.encode('{"name":"P","colors":[{"name":"C","hex":"#445566"}]}');
      final decoded = router.decode(
        extension: '.json',
        bytes: jsonBytes,
        fallbackName: 'fallback',
      );

      expect(decoded.name, equals('P'));
      final gplBytes = router.encode(extension: '.gpl', palette: basePalette);
      final cptBytes = router.encode(extension: '.cpt', palette: basePalette);

      expect(gplBytes, isNotEmpty);
      expect(cptBytes, isNotEmpty);
    });

    test('ASE/JSON/CSV export includes upstream attribution suffix', () {
      const jsonCodec = PaletteJsonCodec();
      const csvCodec = PaletteCsvCodec();
      const aseCodec = PaletteAseCodec();

      final jsonText =
          jsonCodec.encodeString(basePalette, pretty: false, ensureAscii: true);
      final csvText = csvCodec.encodeString(basePalette);
      final aseDecoded = aseCodec.decodeBytes(
        aseCodec.encodeBytes(basePalette),
        fallbackName: 'fallback',
      );

      expect(jsonText.contains('Primary$exportNameSuffix'), isTrue);
      expect(csvText.contains('Primary$exportNameSuffix,#1D4ED8'), isTrue);
      expect(aseDecoded.colors.first.name.endsWith(exportNameSuffix), isTrue);
    });
  });
}
