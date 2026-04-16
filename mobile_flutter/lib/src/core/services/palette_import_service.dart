import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:printing/printing.dart';

import '../compat/palette_codec_router.dart';
import '../models/palette.dart';
import 'palette_color_sampler.dart';

enum ImportedSourceKind {
  palette,
  image,
  pdf,
}

class PaletteImportResult {
  const PaletteImportResult({
    required this.palette,
    required this.fileName,
    required this.extension,
    required this.sourceKind,
  });

  final Palette palette;
  final String fileName;
  final String extension;
  final ImportedSourceKind sourceKind;
}

class PaletteImportService {
  PaletteImportService({
    PaletteCodecRouter? router,
    PaletteColorSampler? colorSampler,
  })  : _router = router ?? PaletteCodecRouter(),
        _colorSampler = colorSampler ?? const PaletteColorSampler();

  final PaletteCodecRouter _router;
  final PaletteColorSampler _colorSampler;

  static const List<String> _paletteExtensions = <String>[
    'json',
    'csv',
    'gpl',
    'ase',
    'pal',
  ];

  static const List<String> _imageExtensions = <String>[
    'png',
    'jpg',
    'jpeg',
    'webp',
    'bmp',
  ];

  static const List<String> _pdfExtensions = <String>['pdf'];

  List<String> get supportedImportExtensions => <String>[
        ..._paletteExtensions,
        ..._imageExtensions,
        ..._pdfExtensions,
      ];

  Future<PaletteImportResult?> pickAndImport() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      withData: true,
      allowedExtensions: supportedImportExtensions,
    );

    if (picked == null || picked.files.isEmpty) {
      return null;
    }

    final platformFile = picked.files.single;
    final bytes = await _resolveFileBytes(platformFile);
    if (bytes == null || bytes.isEmpty) {
      throw const FileSystemException('Unable to read selected file bytes.');
    }

    final extension = _normalizeExtension(platformFile.name);
    final palette = await decodeFile(
      fileName: platformFile.name,
      bytes: bytes,
      sourcePath: platformFile.path,
    );

    return PaletteImportResult(
      palette: palette,
      fileName: platformFile.name,
      extension: extension,
      sourceKind: _resolveSourceKind(extension),
    );
  }

  Future<Palette> decodeFile({
    required String fileName,
    required List<int> bytes,
    String? sourcePath,
  }) async {
    final extension = _normalizeExtension(fileName);
    final fallbackName = _fallbackName(fileName);

    if (_paletteExtensions.contains(extension.replaceFirst('.', ''))) {
      return _router.decode(
        extension: extension,
        bytes: bytes,
        fallbackName: fallbackName,
        sourcePath: sourcePath,
      );
    }

    if (_imageExtensions.contains(extension.replaceFirst('.', ''))) {
      return _colorSampler.sampleFromImageBytes(
        bytes,
        fallbackName: fallbackName,
        sourcePath: sourcePath,
        sourceFormat: 'image',
      );
    }

    if (_pdfExtensions.contains(extension.replaceFirst('.', ''))) {
      return _decodePdfAsPalette(
        bytes: bytes,
        fallbackName: fallbackName,
        sourcePath: sourcePath,
      );
    }

    throw FormatException('Unsupported file type: $extension');
  }

  Future<File> exportToTempFile({
    required Palette palette,
    required String extension,
  }) async {
    final normalizedExtension = extension.startsWith('.')
        ? extension.toLowerCase()
        : '.${extension.toLowerCase()}';

    final bytes = _router.encode(
      extension: normalizedExtension,
      palette: palette,
    );

    final exportDirectory = Directory(
      path.join(Directory.systemTemp.path, 'color_manager_exports'),
    );
    await exportDirectory.create(recursive: true);

    final safeName = _sanitizeFileName(
      palette.name.trim().isEmpty ? 'palette' : palette.name,
    );

    final output = File(
      path.join(exportDirectory.path, '$safeName$normalizedExtension'),
    );
    await output.writeAsBytes(bytes, flush: true);
    return output;
  }

  Future<Palette> _decodePdfAsPalette({
    required List<int> bytes,
    required String fallbackName,
    String? sourcePath,
  }) async {
    await for (final page in Printing.raster(
      Uint8List.fromList(bytes),
      pages: const <int>[0],
      dpi: 96,
    )) {
      final pngBytes = await page.toPng();
      if (pngBytes == null || pngBytes.isEmpty) {
        continue;
      }

      return _colorSampler.sampleFromImageBytes(
        pngBytes,
        fallbackName: fallbackName,
        sourcePath: sourcePath,
        sourceFormat: 'pdf',
      );
    }

    throw const FormatException('Failed to rasterize PDF for color extraction.');
  }

  Future<List<int>?> _resolveFileBytes(PlatformFile file) async {
    if (file.bytes != null) {
      return file.bytes!;
    }

    final filePath = file.path;
    if (filePath == null || filePath.isEmpty) {
      return null;
    }

    final diskFile = File(filePath);
    if (!await diskFile.exists()) {
      return null;
    }

    return diskFile.readAsBytes();
  }

  ImportedSourceKind _resolveSourceKind(String extension) {
    final normalized = extension.replaceFirst('.', '');
    if (_pdfExtensions.contains(normalized)) {
      return ImportedSourceKind.pdf;
    }
    if (_imageExtensions.contains(normalized)) {
      return ImportedSourceKind.image;
    }
    return ImportedSourceKind.palette;
  }

  String _normalizeExtension(String fileName) {
    final ext = path.extension(fileName).trim().toLowerCase();
    if (ext.isEmpty) {
      throw const FormatException('Selected file has no extension.');
    }
    return ext;
  }

  String _fallbackName(String fileName) {
    final name = path.basenameWithoutExtension(fileName).trim();
    return name.isEmpty ? 'Imported Palette' : name;
  }

  String _sanitizeFileName(String value) {
    final sanitized = value.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    return sanitized.isEmpty ? 'palette' : sanitized;
  }
}
