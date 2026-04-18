import '../models/palette.dart';
import 'palette_ase_codec.dart';
import 'palette_cpt_codec.dart';
import 'palette_csv_codec.dart';
import 'palette_gpl_codec.dart';
import 'palette_json_codec.dart';
import 'palette_pal_codec.dart';

class PaletteCodecRouter {
  PaletteCodecRouter({
    PaletteAseCodec? ase,
    PaletteCsvCodec? csv,
    PaletteCptCodec? cpt,
    PaletteGplCodec? gpl,
    PaletteJsonCodec? json,
    PalettePalCodec? pal,
  })  : _ase = ase ?? const PaletteAseCodec(),
        _csv = csv ?? const PaletteCsvCodec(),
      _cpt = cpt ?? const PaletteCptCodec(),
        _gpl = gpl ?? const PaletteGplCodec(),
        _json = json ?? const PaletteJsonCodec(),
        _pal = pal ?? const PalettePalCodec();

  final PaletteAseCodec _ase;
  final PaletteCsvCodec _csv;
  final PaletteCptCodec _cpt;
  final PaletteGplCodec _gpl;
  final PaletteJsonCodec _json;
  final PalettePalCodec _pal;

  Palette decode({
    required String extension,
    required List<int> bytes,
    required String fallbackName,
    String? sourcePath,
    String sourceGroup = 'materials',
  }) {
    final normalized = _normalizeExtension(extension);
    switch (normalized) {
      case '.json':
        return _json.decodeBytes(
          bytes,
          fallbackName: fallbackName,
          sourcePath: sourcePath,
          sourceGroup: sourceGroup,
        );
      case '.csv':
        return _csv.decodeBytes(
          bytes,
          fallbackName: fallbackName,
          sourcePath: sourcePath,
          sourceGroup: sourceGroup,
        );
      case '.gpl':
        return _gpl.decodeBytes(
          bytes,
          fallbackName: fallbackName,
          sourcePath: sourcePath,
          sourceGroup: sourceGroup,
        );
      case '.cpt':
        return _cpt.decodeBytes(
          bytes,
          fallbackName: fallbackName,
          sourcePath: sourcePath,
          sourceGroup: sourceGroup,
        );
      case '.ase':
        return _ase.decodeBytes(
          bytes,
          fallbackName: fallbackName,
          sourcePath: sourcePath,
          sourceGroup: sourceGroup,
        );
      case '.pal':
        return _pal.decodeBytes(
          bytes,
          fallbackName: fallbackName,
          sourcePath: sourcePath,
          sourceGroup: sourceGroup,
        );
      default:
        throw FormatException('Unsupported file type: $extension');
    }
  }

  List<int> encode({
    required String extension,
    required Palette palette,
  }) {
    final normalized = _normalizeExtension(extension);
    switch (normalized) {
      case '.json':
        return _json.encodeBytes(palette, pretty: true, ensureAscii: true);
      case '.csv':
        return _csv.encodeBytes(palette);
      case '.gpl':
        return _gpl.encodeBytes(palette);
      case '.cpt':
        return _cpt.encodeBytes(palette);
      case '.ase':
        return _ase.encodeBytes(palette);
      case '.pal':
        return _pal.encodeOriginLabBytes(palette);
      default:
        throw FormatException('Unsupported output file type: $extension');
    }
  }

  String _normalizeExtension(String value) {
    final lower = value.trim().toLowerCase();
    return lower.startsWith('.') ? lower : '.$lower';
  }
}
