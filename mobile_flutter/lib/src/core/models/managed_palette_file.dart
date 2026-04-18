import 'dart:typed_data';

import 'extraction_profile.dart';
import 'import_source_kind.dart';
import 'palette.dart';

class ManagedPaletteFile {
  const ManagedPaletteFile({
    required this.id,
    required this.fileName,
    required this.extension,
    required this.sourceKind,
    required this.sourceBytes,
    required this.palette,
    required this.extractionProfile,
    required this.extractionRuns,
    required this.importedAt,
    this.previewBytes,
    this.isFavorite = false,
    this.savedProfile,
  });

  final String id;
  final String fileName;
  final String extension;
  final ImportSourceKind sourceKind;
  final Uint8List sourceBytes;
  final Uint8List? previewBytes;
  final Palette palette;
  final ExtractionProfile extractionProfile;
  final bool isFavorite;
  final int extractionRuns;
  final DateTime importedAt;
  final ExtractionProfile? savedProfile;

  ManagedPaletteFile copyWith({
    String? id,
    String? fileName,
    String? extension,
    ImportSourceKind? sourceKind,
    Uint8List? sourceBytes,
    Uint8List? previewBytes,
    Palette? palette,
    ExtractionProfile? extractionProfile,
    bool? isFavorite,
    int? extractionRuns,
    DateTime? importedAt,
    ExtractionProfile? savedProfile,
    bool clearPreview = false,
    bool clearSavedProfile = false,
  }) {
    return ManagedPaletteFile(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      extension: extension ?? this.extension,
      sourceKind: sourceKind ?? this.sourceKind,
      sourceBytes: sourceBytes ?? this.sourceBytes,
      previewBytes: clearPreview ? null : (previewBytes ?? this.previewBytes),
      palette: palette ?? this.palette,
      extractionProfile: extractionProfile ?? this.extractionProfile,
      isFavorite: isFavorite ?? this.isFavorite,
      extractionRuns: extractionRuns ?? this.extractionRuns,
      importedAt: importedAt ?? this.importedAt,
      savedProfile: clearSavedProfile ? null : (savedProfile ?? this.savedProfile),
    );
  }
}