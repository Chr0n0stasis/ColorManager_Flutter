import 'import_source_kind.dart';

enum ExtractionMode {
  wholeFile,
  selectedPage,
  visibleRange,
  boxRange,
  eyeDropper,
  cameraFrame,
}

class ExtractionProfile {
  const ExtractionProfile({
    required this.mode,
    required this.sampleCount,
    this.pageIndex = 1,
    this.visibleRangeFactor = 0.7,
    this.boxLeft = 0.2,
    this.boxTop = 0.2,
    this.boxWidth = 0.6,
    this.boxHeight = 0.6,
    this.eyeDropperX = 0.5,
    this.eyeDropperY = 0.5,
  });

  final ExtractionMode mode;
  final int sampleCount;
  final int pageIndex;
  final double visibleRangeFactor;
  final double boxLeft;
  final double boxTop;
  final double boxWidth;
  final double boxHeight;
  final double eyeDropperX;
  final double eyeDropperY;

  static ExtractionProfile defaultsForSource(ImportSourceKind sourceKind) {
    if (sourceKind == ImportSourceKind.pdf) {
      return const ExtractionProfile(
        mode: ExtractionMode.selectedPage,
        sampleCount: 16,
        pageIndex: 1,
      );
    }
    if (sourceKind == ImportSourceKind.image) {
      return const ExtractionProfile(
        mode: ExtractionMode.wholeFile,
        sampleCount: 16,
      );
    }
    return const ExtractionProfile(
      mode: ExtractionMode.wholeFile,
      sampleCount: 16,
    );
  }

  ExtractionProfile copyWith({
    ExtractionMode? mode,
    int? sampleCount,
    int? pageIndex,
    double? visibleRangeFactor,
    double? boxLeft,
    double? boxTop,
    double? boxWidth,
    double? boxHeight,
    double? eyeDropperX,
    double? eyeDropperY,
  }) {
    return ExtractionProfile(
      mode: mode ?? this.mode,
      sampleCount: sampleCount ?? this.sampleCount,
      pageIndex: pageIndex ?? this.pageIndex,
      visibleRangeFactor: visibleRangeFactor ?? this.visibleRangeFactor,
      boxLeft: boxLeft ?? this.boxLeft,
      boxTop: boxTop ?? this.boxTop,
      boxWidth: boxWidth ?? this.boxWidth,
      boxHeight: boxHeight ?? this.boxHeight,
      eyeDropperX: eyeDropperX ?? this.eyeDropperX,
      eyeDropperY: eyeDropperY ?? this.eyeDropperY,
    );
  }
}