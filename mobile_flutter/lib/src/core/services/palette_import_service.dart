import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../compat/palette_codec_router.dart';
import '../models/color_entry.dart';
import '../models/extraction_profile.dart';
import '../models/import_source_kind.dart';
import '../models/palette.dart';
import 'palette_color_sampler.dart';
import 'palette_generation_service.dart';

class PaletteImportResult {
  const PaletteImportResult({
    required this.palette,
    required this.fileName,
    required this.extension,
    required this.sourceKind,
    required this.sourceBytes,
    required this.extractionProfile,
    this.previewBytes,
  });

  final Palette palette;
  final String fileName;
  final String extension;
  final ImportSourceKind sourceKind;
  final Uint8List sourceBytes;
  final Uint8List? previewBytes;
  final ExtractionProfile extractionProfile;
}

class PaletteReextractResult {
  const PaletteReextractResult({
    required this.palette,
    required this.extractionProfile,
    this.previewBytes,
  });

  final Palette palette;
  final ExtractionProfile extractionProfile;
  final Uint8List? previewBytes;
}

class PaletteImportService {
  PaletteImportService({
    PaletteCodecRouter? router,
    PaletteColorSampler? colorSampler,
    PaletteGenerationService? generationService,
    ImagePicker? imagePicker,
  })  : _router = router ?? PaletteCodecRouter(),
        _colorSampler = colorSampler ?? const PaletteColorSampler(),
        _generationService =
            generationService ?? const PaletteGenerationService(),
        _imagePicker = imagePicker ?? ImagePicker();

  final PaletteCodecRouter _router;
  final PaletteColorSampler _colorSampler;
  final PaletteGenerationService _generationService;
  final ImagePicker _imagePicker;

  static const List<String> _paletteExtensions = <String>[
    'json',
    'csv',
    'gpl',
    'cpt',
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

  List<String> get supportedExportExtensions => const <String>[
        '.json',
        '.csv',
        '.gpl',
        '.cpt',
        '.ase',
        '.pal',
      ];

  bool get canCaptureFromCamera {
    if (kIsWeb) {
      return false;
    }
    if (Platform.isIOS) {
      return false;
    }
    return Platform.isAndroid;
  }

  String get cameraCaptureDisabledReason {
    if (kIsWeb) {
      return 'Web 环境不支持相机取色。';
    }
    if (Platform.isIOS) {
      return '当前 iOS 主工程未启用相机权限声明，已临时禁用相机取色以避免崩溃。';
    }
    return '当前平台不支持相机取色。';
  }

  Future<PaletteImportResult?> pickAndImport({
    ExtractionProfile? profile,
  }) async {
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
    final sourceKind = _resolveSourceKind(extension);
    final preferredProfile = _normalizeProfile(
        profile ?? ExtractionProfile.defaultsForSource(sourceKind), sourceKind);

    final extracted = await _extractFromSource(
      fileName: platformFile.name,
      sourceBytes: Uint8List.fromList(bytes),
      sourceKind: sourceKind,
      extension: extension,
      extractionProfile: preferredProfile,
      sourcePath: platformFile.path,
    );

    return PaletteImportResult(
      palette: extracted.palette,
      fileName: platformFile.name,
      extension: extension,
      sourceKind: sourceKind,
      sourceBytes: Uint8List.fromList(bytes),
      previewBytes: extracted.previewBytes,
      extractionProfile: extracted.extractionProfile,
    );
  }

  Future<PaletteImportResult?> captureFromCamera({
    ExtractionProfile? profile,
  }) async {
    if (!canCaptureFromCamera) {
      throw UnsupportedError(cameraCaptureDisabledReason);
    }

    XFile? captured;
    try {
      captured = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
        maxWidth: 4096,
        requestFullMetadata: false,
      );
    } on MissingPluginException catch (error) {
      throw UnsupportedError('相机插件不可用: $error');
    } on PlatformException catch (error) {
      throw UnsupportedError('相机调用失败: ${error.message ?? error.code}');
    }

    if (captured == null) {
      return null;
    }

    final bytes = await captured.readAsBytes();
    if (bytes.isEmpty) {
      throw const FileSystemException('Unable to read camera image bytes.');
    }

    final fileName = path.basename(captured.path).trim().isEmpty
        ? 'camera_capture.jpg'
        : path.basename(captured.path);
    final extension = _normalizeExtension(fileName);
    final sourceKind = ImportSourceKind.camera;
    final preferredProfile = _normalizeProfile(
      profile ??
          const ExtractionProfile(
            mode: ExtractionMode.cameraFrame,
            sampleCount: 16,
          ),
      sourceKind,
    );

    final extracted = await _extractFromSource(
      fileName: fileName,
      sourceBytes: Uint8List.fromList(bytes),
      sourceKind: sourceKind,
      extension: extension,
      extractionProfile: preferredProfile,
      sourcePath: captured.path,
    );

    return PaletteImportResult(
      palette: extracted.palette,
      fileName: fileName,
      extension: extension,
      sourceKind: sourceKind,
      sourceBytes: Uint8List.fromList(bytes),
      previewBytes: extracted.previewBytes,
      extractionProfile: extracted.extractionProfile,
    );
  }

  Future<String> backupFavoriteSource({
    required String fileName,
    required Uint8List sourceBytes,
    String? extension,
  }) async {
    final baseDir = await _resolveExportBaseDirectory();
    final favoriteDir =
        Directory(path.join(baseDir.path, 'ColorManager', 'favorate'));
    await favoriteDir.create(recursive: true);

    final baseName = _sanitizeFileName(path.basenameWithoutExtension(fileName));
    final ext = _normalizeFavoriteExtension(fileName, extension);
    final backupName = '${DateTime.now().millisecondsSinceEpoch}_$baseName$ext';
    final output = File(path.join(favoriteDir.path, backupName));
    await output.writeAsBytes(sourceBytes, flush: true);
    return backupName;
  }

  Future<void> removeFavoriteBackup(String? backupName) async {
    if (backupName == null || backupName.trim().isEmpty) {
      return;
    }

    final baseDir = await _resolveExportBaseDirectory();
    final target = File(
      path.join(baseDir.path, 'ColorManager', 'favorate', backupName),
    );
    if (await target.exists()) {
      await target.delete();
    }
  }

  Future<Palette> decodeFile({
    required String fileName,
    required List<int> bytes,
    String? sourcePath,
  }) async {
    final extension = _normalizeExtension(fileName);
    final sourceKind = _resolveSourceKind(extension);
    final extracted = await _extractFromSource(
      fileName: fileName,
      sourceBytes: Uint8List.fromList(bytes),
      sourceKind: sourceKind,
      extension: extension,
      extractionProfile: _normalizeProfile(
        ExtractionProfile.defaultsForSource(sourceKind),
        sourceKind,
      ),
      sourcePath: sourcePath,
    );
    return extracted.palette;
  }

  Future<PaletteReextractResult> reextract({
    required String fileName,
    required String extension,
    required ImportSourceKind sourceKind,
    required Uint8List sourceBytes,
    required ExtractionProfile extractionProfile,
    String? sourcePath,
  }) async {
    final normalized = _normalizeExtension(extension);
    final extracted = await _extractFromSource(
      fileName: fileName,
      sourceBytes: sourceBytes,
      sourceKind: sourceKind,
      extension: normalized,
      extractionProfile: _normalizeProfile(extractionProfile, sourceKind),
      sourcePath: sourcePath,
    );
    return PaletteReextractResult(
      palette: extracted.palette,
      extractionProfile: extracted.extractionProfile,
      previewBytes: extracted.previewBytes,
    );
  }

  Future<File> exportToContainerFile({
    required Palette palette,
    required String extension,
    bool sortByLightness = false,
    bool exportAsHeatmapGradient = false,
    int heatmapSteps = 32,
  }) async {
    final normalizedExtension = extension.startsWith('.')
        ? extension.toLowerCase()
        : '.${extension.toLowerCase()}';

    var outputPalette = palette;
    if (sortByLightness) {
      outputPalette = Palette(
        name: outputPalette.name,
        colors: _generationService.sortByLightness(outputPalette.colors),
        sourcePath: outputPalette.sourcePath,
        sourceFormat: outputPalette.sourceFormat,
        sourceGroup: outputPalette.sourceGroup,
        metadata: outputPalette.metadata,
      );
    }

    if (exportAsHeatmapGradient && outputPalette.colors.isNotEmpty) {
      final generated = _generationService.interpolateFromAnchors(
        outputPalette.colors,
        steps: heatmapSteps.clamp(2, 512),
        namePrefix: 'Heatmap',
      );
      outputPalette = Palette(
        name: '${outputPalette.name} Heatmap',
        colors: generated,
        sourcePath: outputPalette.sourcePath,
        sourceFormat: outputPalette.sourceFormat,
        sourceGroup: outputPalette.sourceGroup,
        metadata: outputPalette.metadata,
      );
    }

    final bytes = _router.encode(
      extension: normalizedExtension,
      palette: outputPalette,
    );

    final baseDir = await _resolveExportBaseDirectory();
    final exportDirectory =
        Directory(path.join(baseDir.path, 'ColorManager', 'exports'));
    await exportDirectory.create(recursive: true);

    final safeName = _sanitizeFileName(
      outputPalette.name.trim().isEmpty ? 'palette' : outputPalette.name,
    );

    final output = File(
      path.join(exportDirectory.path, '$safeName$normalizedExtension'),
    );
    await output.writeAsBytes(bytes, flush: true);
    return output;
  }

  Future<File> exportToTempFile({
    required Palette palette,
    required String extension,
  }) {
    return exportToContainerFile(
      palette: palette,
      extension: extension,
      sortByLightness: false,
      exportAsHeatmapGradient: false,
    );
  }

  Future<_ExtractedPayload> _extractFromSource({
    required String fileName,
    required Uint8List sourceBytes,
    required ImportSourceKind sourceKind,
    required String extension,
    required ExtractionProfile extractionProfile,
    String? sourcePath,
  }) async {
    final fallbackName = _fallbackName(fileName);

    if (sourceKind == ImportSourceKind.palette) {
      return _ExtractedPayload(
        palette: _router.decode(
          extension: extension,
          bytes: sourceBytes,
          fallbackName: fallbackName,
          sourcePath: sourcePath,
        ),
        extractionProfile: extractionProfile.copyWith(
          mode: ExtractionMode.wholeFile,
          sampleCount: extractionProfile.sampleCount.clamp(1, 256),
        ),
      );
    }

    final normalizedProfile = _normalizeProfile(extractionProfile, sourceKind);
    final previewBytes = sourceKind == ImportSourceKind.pdf
        ? await _rasterPdfPage(
            bytes: sourceBytes,
            pageIndex: normalizedProfile.pageIndex,
          )
        : sourceBytes;

    final sourceFormat = switch (sourceKind) {
      ImportSourceKind.pdf => 'pdf',
      ImportSourceKind.camera => 'camera',
      _ => 'image',
    };

    if (normalizedProfile.mode == ExtractionMode.eyeDropper) {
      final picked = _colorSampler.pickColorAt(
        previewBytes,
        normalizedX: normalizedProfile.eyeDropperX,
        normalizedY: normalizedProfile.eyeDropperY,
        name: 'Eyedropper',
      );
      return _ExtractedPayload(
        palette: Palette(
          name: fallbackName,
          colors: <ColorEntry>[picked],
          sourcePath: sourcePath,
          sourceFormat: sourceFormat,
          sourceGroup: 'materials',
        ),
        previewBytes: previewBytes,
        extractionProfile: normalizedProfile,
      );
    }

    final sampledBytes = _resolveSamplingBytes(
      previewBytes,
      mode: normalizedProfile.mode,
      visibleRangeFactor: normalizedProfile.visibleRangeFactor,
      boxLeft: normalizedProfile.boxLeft,
      boxTop: normalizedProfile.boxTop,
      boxWidth: normalizedProfile.boxWidth,
      boxHeight: normalizedProfile.boxHeight,
    );

    return _ExtractedPayload(
      palette: _colorSampler.sampleFromImageBytes(
        sampledBytes,
        fallbackName: fallbackName,
        sourcePath: sourcePath,
        sourceFormat: sourceFormat,
        sourceGroup: 'materials',
        maxColorsOverride: normalizedProfile.sampleCount,
      ),
      previewBytes: previewBytes,
      extractionProfile: normalizedProfile,
    );
  }

  Future<Uint8List> _rasterPdfPage({
    required Uint8List bytes,
    required int pageIndex,
  }) async {
    final page = math.max(1, pageIndex);
    final rasterPage = await _rasterFirstAvailablePage(bytes, page);
    if (rasterPage != null) {
      return rasterPage;
    }

    if (page != 1) {
      final fallbackPage = await _rasterFirstAvailablePage(bytes, 1);
      if (fallbackPage != null) {
        return fallbackPage;
      }
    }

    throw const FormatException(
        'Failed to rasterize PDF for color extraction.');
  }

  Future<Uint8List?> _rasterFirstAvailablePage(
      Uint8List bytes, int pageIndex) async {
    await for (final page in Printing.raster(
      bytes,
      pages: <int>[pageIndex - 1],
      dpi: 120,
    )) {
      final pngBytes = await page.toPng();
      if (pngBytes != null && pngBytes.isNotEmpty) {
        return pngBytes;
      }
    }
    return null;
  }

  Uint8List _resolveSamplingBytes(
    Uint8List source, {
    required ExtractionMode mode,
    required double visibleRangeFactor,
    required double boxLeft,
    required double boxTop,
    required double boxWidth,
    required double boxHeight,
  }) {
    if (mode == ExtractionMode.wholeFile ||
        mode == ExtractionMode.selectedPage ||
        mode == ExtractionMode.cameraFrame) {
      return source;
    }

    final decoded = img.decodeImage(source);
    if (decoded == null) {
      return source;
    }

    if (mode == ExtractionMode.visibleRange) {
      final factor = visibleRangeFactor.clamp(0.1, 1.0);
      final targetWidth = math.max(1, (decoded.width * factor).round());
      final targetHeight = math.max(1, (decoded.height * factor).round());
      final left = ((decoded.width - targetWidth) / 2).round();
      final top = ((decoded.height - targetHeight) / 2).round();
      final cropped = img.copyCrop(
        decoded,
        x: left,
        y: top,
        width: targetWidth,
        height: targetHeight,
      );
      return Uint8List.fromList(img.encodePng(cropped));
    }

    if (mode == ExtractionMode.boxRange) {
      final left = (boxLeft.clamp(0.0, 1.0) * decoded.width).round();
      final top = (boxTop.clamp(0.0, 1.0) * decoded.height).round();
      final width = (boxWidth.clamp(0.05, 1.0) * decoded.width).round();
      final height = (boxHeight.clamp(0.05, 1.0) * decoded.height).round();
      final boundedLeft = left.clamp(0, decoded.width - 1);
      final boundedTop = top.clamp(0, decoded.height - 1);
      final boundedWidth = width.clamp(1, decoded.width - boundedLeft);
      final boundedHeight = height.clamp(1, decoded.height - boundedTop);
      final cropped = img.copyCrop(
        decoded,
        x: boundedLeft,
        y: boundedTop,
        width: boundedWidth,
        height: boundedHeight,
      );
      return Uint8List.fromList(img.encodePng(cropped));
    }

    return source;
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

  ImportSourceKind _resolveSourceKind(String extension) {
    final normalized = extension.replaceFirst('.', '');
    if (_pdfExtensions.contains(normalized)) {
      return ImportSourceKind.pdf;
    }
    if (_imageExtensions.contains(normalized)) {
      return ImportSourceKind.image;
    }
    return ImportSourceKind.palette;
  }

  ExtractionProfile _normalizeProfile(
    ExtractionProfile profile,
    ImportSourceKind sourceKind,
  ) {
    var mode = profile.mode;
    if (sourceKind == ImportSourceKind.palette) {
      mode = ExtractionMode.wholeFile;
    }
    if (sourceKind == ImportSourceKind.pdf &&
        mode == ExtractionMode.cameraFrame) {
      mode = ExtractionMode.selectedPage;
    }

    return profile.copyWith(
      mode: mode,
      sampleCount: profile.sampleCount.clamp(1, 256),
      pageIndex: math.max(1, profile.pageIndex),
      visibleRangeFactor: profile.visibleRangeFactor.clamp(0.1, 1.0),
      boxLeft: profile.boxLeft.clamp(0.0, 1.0),
      boxTop: profile.boxTop.clamp(0.0, 1.0),
      boxWidth: profile.boxWidth.clamp(0.05, 1.0),
      boxHeight: profile.boxHeight.clamp(0.05, 1.0),
      eyeDropperX: profile.eyeDropperX.clamp(0.0, 1.0),
      eyeDropperY: profile.eyeDropperY.clamp(0.0, 1.0),
    );
  }

  Future<Directory> _resolveExportBaseDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
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

  String _normalizeFavoriteExtension(String fileName, String? extension) {
    var ext = path.extension(fileName).trim().toLowerCase();
    if (ext.isNotEmpty) {
      return ext;
    }
    if (extension == null || extension.trim().isEmpty) {
      return '';
    }
    final normalized = extension.trim().toLowerCase();
    return normalized.startsWith('.') ? normalized : '.$normalized';
  }
}

class _ExtractedPayload {
  const _ExtractedPayload({
    required this.palette,
    required this.extractionProfile,
    this.previewBytes,
  });

  final Palette palette;
  final ExtractionProfile extractionProfile;
  final Uint8List? previewBytes;
}
