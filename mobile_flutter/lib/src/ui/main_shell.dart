import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/branding/upstream_branding.dart';
import '../core/models/color_entry.dart';
import '../core/models/extraction_profile.dart';
import '../core/models/managed_palette_file.dart';
import '../core/models/palette.dart';
import '../core/services/palette_generation_service.dart';
import '../core/services/palette_import_service.dart';
import '../i18n/app_localizations.dart';
import 'layout_contract.dart';
import 'panels.dart';

enum WorkspacePage {
  management,
  preview,
  export,
  settings,
}

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.themeSeedColor,
    required this.onThemeSeedColorChanged,
    required this.useMaterialDynamicColor,
    required this.onUseMaterialDynamicColorChanged,
    required this.materialDynamicColorAvailable,
    required this.languagePreference,
    required this.onLanguagePreferenceChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final Color themeSeedColor;
  final ValueChanged<Color> onThemeSeedColorChanged;
  final bool useMaterialDynamicColor;
  final ValueChanged<bool> onUseMaterialDynamicColorChanged;
  final bool materialDynamicColorAvailable;
  final AppLanguagePreference languagePreference;
  final ValueChanged<AppLanguagePreference> onLanguagePreferenceChanged;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final PaletteImportService _importService = PaletteImportService();
  final PaletteGenerationService _generationService =
      const PaletteGenerationService();

  Timer? _statusRotationTimer;
  int _statusRotationIndex = 0;

  final List<ManagedPaletteFile> _files = <ManagedPaletteFile>[];
  final List<ColorEntry> _exportColors = <ColorEntry>[];
  final Set<String> _exportColorKeys = <String>{};

  ManagedPaletteFile? _selectedFile;
  String _searchText = '';
  bool _favoritesOnly = false;
  String? _statusMessage;
  bool _isBusy = false;

  int _activePageIndex = 0;

  PaletteChartMode _chartMode = PaletteChartMode.line;
  PalettePreviewVisionMode _previewVisionMode = PalettePreviewVisionMode.normal;
  PaletteMarkerShape _previewMarkerShape = PaletteMarkerShape.circle;
  int _previewSeriesCount = 5;
  int _previewGroupCount = 4;
  int _previewLineWidth = 2;
  int _previewMarkerSize = 5;
  int _previewAlphaPercent = 100;

  PaletteGenerationKind _generationKind =
      PaletteGenerationKind.twoColorGradient;
  WhiteTemperature _whiteTemperature = WhiteTemperature.neutral;
  String _baseHex = '#1D4ED8';
  String _secondaryHex = '#F97316';
  int _generationSteps = 5;

  bool _sortByLightness = false;
  bool _exportAsHeatmapGradient = false;
  int _heatmapSteps = 32;
  String _selectedExportExtension = '.json';
  String _exportFileName = 'Cart Palette';

  bool _autoThemeColor = true;

  int? _selectedExportColorIndex;
  bool _isPickingBaseColor = false;
  bool _isPickingSecondaryColor = false;

  bool _previewConfigExpanded = true;
  bool _previewResultExpanded = false;
  bool _previewEffectExpanded = false;

  bool _exportFormatExpanded = true;
  bool _exportGeneratorExpanded = true;
  bool _exportStrategyExpanded = false;
  bool _exportColorListExpanded = true;
  bool _exportPreviewExpanded = false;

  static const List<Color> _themeColorPresets = <Color>[
    Color(0xFF1D4ED8),
    Color(0xFF0F766E),
    Color(0xFFB45309),
    Color(0xFFBE123C),
    Color(0xFF6D28D9),
    Color(0xFF334155),
  ];

  @override
  void initState() {
    super.initState();
    final supported = _importService.supportedExportExtensions;
    if (supported.isNotEmpty) {
      _selectedExportExtension = supported.first;
    }
    _statusRotationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusRotationIndex = (_statusRotationIndex + 1) % 3;
      });
    });
  }

  @override
  void dispose() {
    _statusRotationTimer?.cancel();
    super.dispose();
  }

  AppLocalizations get _l10n => AppLocalizations.of(context);

  String _tr(
    String key, {
    Map<String, String> params = const <String, String>{},
  }) {
    return _l10n.tr(key, params: params);
  }

  String get _statusWatermarkMessage {
    final rotation = _statusRotationIndex % 3;
    if (rotation == 0) {
      return _tr(
        'Ver {version} | Author: {author} | {tagline}',
        params: <String, String>{
          'version': appVersion,
          'author': appAuthor,
          'tagline': _tr(appTagline),
        },
      );
    }
    if (rotation == 1) {
      return _tr(
        'Ver {version} | {message}',
        params: <String, String>{
          'version': appVersion,
          'message': _tr(antiResaleMessage),
        },
      );
    }
    return _tr(nonCommercialNotice);
  }

  List<ManagedPaletteFile> get _filteredFiles {
    final keyword = _searchText.trim().toLowerCase();
    return List<ManagedPaletteFile>.unmodifiable(
      _files.where((file) {
        if (_favoritesOnly && !file.isFavorite) {
          return false;
        }
        if (keyword.isEmpty) {
          return true;
        }
        return file.fileName.toLowerCase().contains(keyword) ||
            file.palette.name.toLowerCase().contains(keyword) ||
            file.palette.sourceFormat.toLowerCase().contains(keyword);
      }),
    );
  }

  List<ColorEntry> get _generatorColorCandidates {
    final map = <String, ColorEntry>{};
    for (final color in _exportColors) {
      map.putIfAbsent(color.hexCode.toUpperCase(), () => color);
    }
    for (final color in (_selectedFile?.palette.colors ?? <ColorEntry>[])) {
      map.putIfAbsent(color.hexCode.toUpperCase(), () => color);
    }
    return map.values.toList(growable: false);
  }

  bool _isColorInExport(ColorEntry color) {
    return _exportColorKeys.contains(_colorKey(color));
  }

  String _colorKey(ColorEntry color) {
    return '${color.name}|${color.hexCode}';
  }

  Future<void> _importFile() async {
    setState(() {
      _isBusy = true;
      _statusMessage = _tr('Importing file...');
    });

    try {
      final result = await _importService.pickAndImport();
      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _statusMessage = _tr('Import canceled.');
          _isBusy = false;
        });
        return;
      }

      setState(() {
        final record = ManagedPaletteFile(
          id: _makeRecordId(result.fileName),
          fileName: result.fileName,
          extension: result.extension,
          sourceKind: result.sourceKind,
          sourceBytes: result.sourceBytes,
          previewBytes: result.previewBytes,
          palette: result.palette,
          extractionProfile: result.extractionProfile,
          extractionRuns: 1,
          importedAt: DateTime.now(),
        );
        _files.insert(0, record);
        _selectedFile = record;
        _syncExportPaletteFromColors(record.palette.colors);
        _statusMessage = _tr(
          'Imported {fileName} ({count} colors).',
          params: <String, String>{
            'fileName': result.fileName,
            'count': result.palette.colors.length.toString(),
          },
        );
        _isBusy = false;
      });

      _applyAutoThemeSeedFromContext();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = _tr(
          'Import failed: {error}',
          params: <String, String>{'error': error.toString()},
        );
        _isBusy = false;
      });
    }
  }

  Future<void> _importFromCamera() async {
    if (!_importService.canCaptureFromCamera) {
      setState(() {
        _statusMessage = _tr(_importService.cameraCaptureDisabledReason);
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _statusMessage = _tr('Capturing camera frame...');
    });

    try {
      final result = await _importService.captureFromCamera();
      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _statusMessage = _tr('Camera capture canceled.');
          _isBusy = false;
        });
        return;
      }

      setState(() {
        final record = ManagedPaletteFile(
          id: _makeRecordId(result.fileName),
          fileName: result.fileName,
          extension: result.extension,
          sourceKind: result.sourceKind,
          sourceBytes: result.sourceBytes,
          previewBytes: result.previewBytes,
          palette: result.palette,
          extractionProfile: result.extractionProfile,
          extractionRuns: 1,
          importedAt: DateTime.now(),
        );
        _files.insert(0, record);
        _selectedFile = record;
        _syncExportPaletteFromColors(record.palette.colors);
        _statusMessage = _tr(
          'Captured camera frame ({count} colors).',
          params: <String, String>{
            'count': result.palette.colors.length.toString(),
          },
        );
        _isBusy = false;
      });

      _applyAutoThemeSeedFromContext();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _statusMessage = _tr(
          'Camera import failed: {error}',
          params: <String, String>{'error': error.toString()},
        );
      });
    }
  }

  void _selectFile(ManagedPaletteFile file) {
    setState(() {
      _selectedFile = file;
      _statusMessage = _tr(
        'Selected {paletteName} ({count} colors).',
        params: <String, String>{
          'paletteName': file.palette.name,
          'count': file.palette.colors.length.toString(),
        },
      );
    });
    _applyAutoThemeSeedFromContext();
  }

  void _updateSearchText(String value) {
    setState(() {
      _searchText = value;
    });
  }

  void _toggleFavoritesOnly(bool value) {
    setState(() {
      _favoritesOnly = value;
    });
  }

  Future<void> _toggleFileFavorite(ManagedPaletteFile file) async {
    if (_isBusy) {
      return;
    }

    setState(() {
      _isBusy = true;
      _statusMessage = file.isFavorite
          ? _tr('Removing favorite...')
          : _tr('Saving favorite backup...');
    });

    try {
      if (file.isFavorite) {
        await _importService.removeFavoriteBackup(file.favoriteBackupName);
        final updated = file.copyWith(
          isFavorite: false,
          clearFavoriteBackupName: true,
        );
        _replaceRecord(updated);
        setState(() {
          _statusMessage = _tr(
            'Removed {fileName} from favorites.',
            params: <String, String>{'fileName': updated.fileName},
          );
          _isBusy = false;
        });
        return;
      }

      final backupName = await _importService.backupFavoriteSource(
        fileName: file.fileName,
        extension: file.extension,
        sourceBytes: file.sourceBytes,
      );
      final updated = file.copyWith(
        isFavorite: true,
        favoriteBackupName: backupName,
      );
      _replaceRecord(updated);
      setState(() {
        _statusMessage = _tr(
          'Added {fileName} to favorites and backed up to favorate/{backupName}',
          params: <String, String>{
            'fileName': updated.fileName,
            'backupName': backupName,
          },
        );
        _isBusy = false;
      });
    } catch (error) {
      setState(() {
        _statusMessage = _tr(
          'Favorite backup failed: {error}',
          params: <String, String>{'error': error.toString()},
        );
        _isBusy = false;
      });
    }
  }

  void _toggleExportColor(ColorEntry color) {
    final key = _colorKey(color);
    setState(() {
      if (_exportColorKeys.remove(key)) {
        _exportColors.removeWhere((item) => _colorKey(item) == key);
        _statusMessage = _tr(
          'Removed {hexCode} from cart.',
          params: <String, String>{'hexCode': color.hexCode},
        );
      } else {
        _exportColorKeys.add(key);
        _exportColors.add(color);
        _statusMessage = _tr(
          'Added {hexCode} to cart.',
          params: <String, String>{'hexCode': color.hexCode},
        );
      }
      _selectedExportColorIndex = null;
    });
    _applyAutoThemeSeedFromContext();
  }

  void _removeExportColor(ColorEntry color) {
    final key = _colorKey(color);
    setState(() {
      _exportColorKeys.remove(key);
      _exportColors.removeWhere((item) => _colorKey(item) == key);
      _selectedExportColorIndex = null;
      _statusMessage = _tr(
        'Removed {hexCode} from cart.',
        params: <String, String>{'hexCode': color.hexCode},
      );
    });
    _applyAutoThemeSeedFromContext();
  }

  void _updateExportColor(int index, ColorEntry color) {
    if (index < 0 || index >= _exportColors.length) {
      return;
    }
    setState(() {
      _exportColors[index] = color;
      _rebuildExportKeys();
      _statusMessage = _tr(
        'Updated {name}.',
        params: <String, String>{'name': color.name},
      );
    });
    _applyAutoThemeSeedFromContext();
  }

  Future<void> _addManualExportColor() async {
    final nameController = TextEditingController();
    final hexController = TextEditingController(text: '#1D4ED8');

    final added = await showDialog<ColorEntry>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_tr('Add Color Manually')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: _tr('Name')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: hexController,
                decoration: InputDecoration(
                  labelText: _tr('HEX'),
                  hintText: _tr('#RRGGBB'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_tr('Cancel')),
            ),
            FilledButton(
              onPressed: () {
                final normalized = _normalizeHexInput(hexController.text);
                if (normalized == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_tr('Invalid HEX format, please input #RRGGBB')),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(
                  ColorEntry(
                    name: nameController.text.trim().isEmpty
                        ? 'Manual ${_exportColors.length + 1}'
                        : nameController.text.trim(),
                    hexCode: normalized,
                  ),
                );
              },
              child: Text(_tr('Add')),
            ),
          ],
        );
      },
    );

    if (added == null) {
      return;
    }

    setState(() {
      _exportColors.add(added);
      _rebuildExportKeys();
      _selectedExportColorIndex = _exportColors.length - 1;
      _statusMessage = _tr(
        'Added {hexCode} to cart.',
        params: <String, String>{'hexCode': added.hexCode},
      );
    });

    _applyAutoThemeSeedFromContext();
  }

  void _clearExportColors() {
    setState(() {
      _exportColorKeys.clear();
      _exportColors.clear();
      _selectedExportColorIndex = null;
      _isPickingBaseColor = false;
      _isPickingSecondaryColor = false;
      _statusMessage = _tr('Cart cleared.');
    });
  }

  void _selectExportColorIndex(int index) {
    if (index < 0 || index >= _exportColors.length) {
      return;
    }

    setState(() {
      final color = _exportColors[index];
      if (_isPickingBaseColor) {
        _baseHex = color.hexCode.toUpperCase();
        _selectedExportColorIndex = index;
        _isPickingBaseColor = false;
        _isPickingSecondaryColor = false;
        _statusMessage = _tr(
          'Base color set to {hexCode}.',
          params: <String, String>{'hexCode': color.hexCode},
        );
        return;
      }

      if (_isPickingSecondaryColor) {
        _secondaryHex = color.hexCode.toUpperCase();
        _selectedExportColorIndex = index;
        _isPickingSecondaryColor = false;
        _isPickingBaseColor = false;
        _statusMessage = _tr(
          'Secondary color set to {hexCode}.',
          params: <String, String>{'hexCode': color.hexCode},
        );
        return;
      }

      if (_selectedExportColorIndex == index) {
        _selectedExportColorIndex = null;
      } else {
        _selectedExportColorIndex = index;
      }
    });
  }

  void _toggleBaseColorPicking() {
    if (_exportColors.isEmpty) {
      setState(() {
        _statusMessage = _tr('Add colors to the export list first.');
      });
      return;
    }

    setState(() {
      final enabling = !_isPickingBaseColor;
      _isPickingBaseColor = enabling;
      if (enabling) {
        _isPickingSecondaryColor = false;
      }
      _statusMessage = _isPickingBaseColor
          ? _tr('Base color pick mode on: tap a color in the export list.')
          : _tr('Base color pick canceled.');
    });
  }

  void _toggleSecondaryColorPicking() {
    if (_exportColors.isEmpty) {
      setState(() {
        _statusMessage = _tr('Add colors to the export list first.');
      });
      return;
    }

    setState(() {
      final enabling = !_isPickingSecondaryColor;
      _isPickingSecondaryColor = enabling;
      if (enabling) {
        _isPickingBaseColor = false;
      }
      _statusMessage = _isPickingSecondaryColor
          ? _tr('Secondary color pick mode on: tap a color in the export list.')
          : _tr('Secondary color pick canceled.');
    });
  }

  void _useSelectedPaletteAsExportBase() {
    final current = _selectedFile;
    if (current == null) {
      setState(() {
        _statusMessage = _tr('Select a file first.');
      });
      return;
    }

    setState(() {
      _syncExportPaletteFromColors(current.palette.colors);
      _selectedExportColorIndex = null;
      _statusMessage = _tr('Loaded current file colors into export cart.');
    });
    _applyAutoThemeSeedFromContext();
  }

  String get _effectiveExportFileName {
    var rawName = _exportFileName.trim();
    if (rawName.isEmpty) {
      rawName = _selectedFile?.palette.name.trim() ?? '';
    }
    if (rawName.isEmpty) {
      rawName = 'Cart Palette';
    }

    for (final extension in _importService.supportedExportExtensions) {
      if (rawName.toLowerCase().endsWith(extension)) {
        rawName = rawName.substring(0, rawName.length - extension.length).trim();
        break;
      }
    }
    return rawName.isEmpty ? 'Cart Palette' : rawName;
  }

  PaletteExportPayload _buildCurrentExportPayload() {
    final palette = Palette(
      name: _effectiveExportFileName,
      colors: List<ColorEntry>.from(_exportColors),
      sourceFormat: _selectedExportExtension.replaceFirst('.', ''),
    );

    return _importService.buildExportPayload(
      palette: palette,
      extension: _selectedExportExtension,
      sortByLightness: _sortByLightness,
      exportAsHeatmapGradient: _exportAsHeatmapGradient,
      heatmapSteps: _heatmapSteps,
    );
  }

  Future<void> _exportPalette() async {
    final extension = _selectedExportExtension;
    if (_exportColors.isEmpty) {
      setState(() {
        _statusMessage = _tr('Cart is empty. Add colors before export.');
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _statusMessage = _tr(
        'Exporting {extension}...',
        params: <String, String>{'extension': extension},
      );
    });

    try {
      final palette = Palette(
        name: _effectiveExportFileName,
        colors: List<ColorEntry>.from(_exportColors),
        sourceFormat: extension.replaceFirst('.', ''),
      );

      final output = await _importService.exportToContainerFile(
        palette: palette,
        extension: extension,
        sortByLightness: _sortByLightness,
        exportAsHeatmapGradient: _exportAsHeatmapGradient,
        heatmapSteps: _heatmapSteps,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isBusy = false;
        _statusMessage = _tr(
          'Exported to {path}',
          params: <String, String>{'path': output.path},
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isBusy = false;
        _statusMessage = _tr(
          'Export failed: {error}',
          params: <String, String>{'error': error.toString()},
        );
      });
    }
  }

  void _updateExtractionProfile(ExtractionProfile profile) {
    final current = _selectedFile;
    if (current == null) {
      return;
    }
    _replaceRecord(current.copyWith(extractionProfile: profile));
    setState(() {});
  }

  Future<void> _reextractSelectedFile() async {
    final current = _selectedFile;
    if (current == null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _statusMessage = _tr('Re-extracting colors...');
    });

    try {
      final result = await _importService.reextract(
        fileName: current.fileName,
        extension: current.extension,
        sourceKind: current.sourceKind,
        sourceBytes: current.sourceBytes,
        extractionProfile: current.extractionProfile,
        sourcePath: current.palette.sourcePath,
      );
      if (!mounted) {
        return;
      }

      final updated = current.copyWith(
        palette: result.palette,
        previewBytes: result.previewBytes,
        extractionProfile: result.extractionProfile,
        extractionRuns: current.extractionRuns + 1,
      );
      _replaceRecord(updated);

      setState(() {
        _syncExportPaletteFromColors(updated.palette.colors);
        _selectedExportColorIndex = null;
        _isBusy = false;
        _statusMessage = _tr(
          'Re-extracted {count} colors from {fileName}.',
          params: <String, String>{
            'count': updated.palette.colors.length.toString(),
            'fileName': updated.fileName,
          },
        );
      });

      _applyAutoThemeSeedFromContext();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _statusMessage = _tr(
          'Re-extract failed: {error}',
          params: <String, String>{'error': error.toString()},
        );
      });
    }
  }

  void _saveCurrentProfile() {
    final current = _selectedFile;
    if (current == null) {
      return;
    }

    _replaceRecord(current.copyWith(savedProfile: current.extractionProfile));
    setState(() {
      _statusMessage = _tr(
        'Saved extraction profile for {fileName}.',
        params: <String, String>{'fileName': current.fileName},
      );
    });
  }

  Future<void> _applySavedProfile() async {
    final current = _selectedFile;
    if (current == null || current.savedProfile == null) {
      setState(() {
        _statusMessage = _tr('No saved profile for current file.');
      });
      return;
    }

    _replaceRecord(current.copyWith(extractionProfile: current.savedProfile));
    await _reextractSelectedFile();
  }

  void _setChartMode(PaletteChartMode mode) {
    setState(() {
      _chartMode = mode;
    });
  }

  void _setPreviewVisionMode(PalettePreviewVisionMode mode) {
    setState(() {
      _previewVisionMode = mode;
    });
  }

  void _setPreviewSeriesCount(double value) {
    setState(() {
      _previewSeriesCount = value.round().clamp(1, 24);
    });
  }

  void _setPreviewGroupCount(double value) {
    setState(() {
      _previewGroupCount = value.round().clamp(2, 48);
    });
  }

  void _setPreviewLineWidth(double value) {
    setState(() {
      _previewLineWidth = value.round().clamp(1, 8);
    });
  }

  void _setPreviewMarkerSize(double value) {
    setState(() {
      _previewMarkerSize = value.round().clamp(2, 18);
    });
  }

  void _setPreviewAlphaPercent(double value) {
    setState(() {
      _previewAlphaPercent = value.round().clamp(10, 100);
    });
  }

  void _setPreviewMarkerShape(PaletteMarkerShape value) {
    setState(() {
      _previewMarkerShape = value;
    });
  }

  void _setGenerationKind(PaletteGenerationKind value) {
    setState(() {
      _generationKind = value;
    });
  }

  void _setWhiteTemperature(WhiteTemperature value) {
    setState(() {
      _whiteTemperature = value;
    });
  }

  void _setBaseHex(String value) {
    setState(() {
      _baseHex = value;
      _isPickingBaseColor = false;
    });
  }

  void _setSecondaryHex(String value) {
    setState(() {
      _secondaryHex = value;
      _isPickingSecondaryColor = false;
    });
  }

  void _setGenerationSteps(double value) {
    setState(() {
      _generationSteps = value.round().clamp(2, 20);
    });
  }

  void _setSortByLightness(bool value) {
    setState(() {
      _sortByLightness = value;
    });
  }

  void _setExportAsHeatmapGradient(bool value) {
    setState(() {
      _exportAsHeatmapGradient = value;
    });
  }

  void _setHeatmapSteps(double value) {
    setState(() {
      _heatmapSteps = value.round().clamp(2, 512);
    });
  }

  void _setSelectedExportExtension(String? extension) {
    if (extension == null || extension.trim().isEmpty) {
      return;
    }
    setState(() {
      _selectedExportExtension = extension;
    });
  }

  void _setExportFileName(String value) {
    setState(() {
      _exportFileName = value;
    });
  }

  void _setExportColorListExpanded(bool expanded) {
    setState(() {
      _exportColorListExpanded = expanded;
      if (expanded) {
        _exportPreviewExpanded = false;
      }
    });
  }

  void _setExportPreviewExpanded(bool expanded) {
    setState(() {
      _exportPreviewExpanded = expanded;
      if (expanded) {
        _exportColorListExpanded = false;
      }
    });
  }

  void _generateAndReplace() {
    _generateColors(append: false);
  }

  void _generateAndAppend() {
    _generateColors(append: true);
  }

  void _generateColors({required bool append}) {
    try {
      final generated = _generationService.generate(
        kind: _generationKind,
        baseHex: _baseHex,
        secondaryHex: _secondaryHex,
        steps: _generationSteps,
        whiteTemperature: _whiteTemperature,
      );

      setState(() {
        if (!append) {
          _exportColors
            ..clear()
            ..addAll(generated);
        } else {
          _exportColors.addAll(generated);
        }
        _rebuildExportKeys();
        _selectedExportColorIndex = null;
        _statusMessage = append
            ? _tr(
                'Appended {count} generated colors.',
                params: <String, String>{
                  'count': generated.length.toString(),
                },
              )
            : _tr(
                'Replaced cart with {count} generated colors.',
                params: <String, String>{
                  'count': generated.length.toString(),
                },
              );
      });

      _applyAutoThemeSeedFromContext();
    } catch (error) {
      setState(() {
        _statusMessage = _tr(
          'Generate failed: {error}',
          params: <String, String>{'error': error.toString()},
        );
      });
    }
  }

  void _replaceRecord(ManagedPaletteFile updated) {
    final index = _files.indexWhere((item) => item.id == updated.id);
    if (index == -1) {
      return;
    }
    _files[index] = updated;
    if (_selectedFile?.id == updated.id) {
      _selectedFile = updated;
    }
  }

  void _syncExportPaletteFromColors(List<ColorEntry> colors) {
    _exportColors
      ..clear()
      ..addAll(colors);
    _rebuildExportKeys();
  }

  void _rebuildExportKeys() {
    _exportColorKeys
      ..clear()
      ..addAll(_exportColors.map(_colorKey));
  }

  String _makeRecordId(String fileName) {
    return '${DateTime.now().microsecondsSinceEpoch}_$fileName';
  }

  void _setActivePage(int index) {
    setState(() {
      _activePageIndex = index;
    });
  }

  void _setAutoThemeColor(bool enabled) {
    setState(() {
      _autoThemeColor = enabled;
    });
    if (enabled) {
      _applyAutoThemeSeedFromContext();
    }
  }

  void _setThemeSeedColor(Color color) {
    widget.onThemeSeedColorChanged(color);
  }

  void _applyAutoThemeSeedFromContext() {
    if (!_autoThemeColor) {
      return;
    }

    String? sourceHex;
    if (_selectedFile != null && _selectedFile!.palette.colors.isNotEmpty) {
      sourceHex = _selectedFile!.palette.colors.first.hexCode;
    } else if (_exportColors.isNotEmpty) {
      sourceHex = _exportColors.first.hexCode;
    }
    if (sourceHex == null) {
      return;
    }

    final color = _tryParseHexColor(sourceHex);
    if (color != null) {
      widget.onThemeSeedColorChanged(color);
    }
  }

  Color? _tryParseHexColor(String value) {
    final normalized = value.trim().toUpperCase();
    final match = RegExp(r'^#?[0-9A-F]{6}$').hasMatch(normalized);
    if (!match) {
      return null;
    }
    final hex =
        normalized.startsWith('#') ? normalized.substring(1) : normalized;
    return Color(int.parse('FF$hex', radix: 16));
  }

  String _hexFromColor(Color color) {
    final hex =
        color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#${hex.substring(2)}';
  }

  String? _normalizeHexInput(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }
    final normalized = value.startsWith('#') ? value : '#$value';
    final valid = RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(normalized);
    return valid ? normalized.toUpperCase() : null;
  }

  void _setPreviewConfigExpanded(bool expanded) {
    setState(() {
      _previewConfigExpanded = expanded;
      if (expanded) {
        _previewResultExpanded = false;
        _previewEffectExpanded = false;
      }
    });
  }

  void _setPreviewResultExpanded(bool expanded) {
    setState(() {
      _previewResultExpanded = expanded;
      if (expanded) {
        _previewConfigExpanded = false;
        _previewEffectExpanded = false;
      }
    });
  }

  void _setPreviewEffectExpanded(bool expanded) {
    setState(() {
      _previewEffectExpanded = expanded;
      if (expanded) {
        _previewConfigExpanded = false;
        _previewResultExpanded = false;
      }
    });
  }

  void _setExportFormatExpanded(bool expanded) {
    setState(() {
      _exportFormatExpanded = expanded;
      if (expanded) {
        _exportStrategyExpanded = false;
      }
    });
  }

  void _setExportGeneratorExpanded(bool expanded) {
    setState(() {
      _exportGeneratorExpanded = expanded;
    });
  }

  void _setExportStrategyExpanded(bool expanded) {
    setState(() {
      _exportStrategyExpanded = expanded;
      if (expanded) {
        _exportFormatExpanded = false;
      }
    });
  }

  void _openCopyrightPage() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _tr('Copyright & License'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _tr(
                      'App: {appName}\nVersion: {version}\nAuthor: {author}',
                      params: <String, String>{
                        'appName': _tr(appDisplayName),
                        'version': appVersion,
                        'author': appAuthor,
                      },
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _tr(nonCommercialNotice),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _tr(antiResaleMessage),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _tr(
                      'Export source suffix: {suffix}',
                      params: <String, String>{'suffix': exportNameSuffix},
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(_tr('Close')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final activePage = _buildActivePage();
    final showHeader =
        _activePageIndex == WorkspacePage.settings.index;

    final PreferredSizeWidget? appBar = showHeader
        ? AppBar(
            toolbarHeight: 70,
            titleSpacing: 12,
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_tr(appDisplayName)),
                Text(
                  _statusWatermarkMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          )
        : null;

    if (orientation == Orientation.landscape) {
      final body = Row(
        children: [
          NavigationRail(
            selectedIndex: _activePageIndex,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: _setActivePage,
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.folder_copy_outlined),
                selectedIcon: const Icon(Icons.folder_copy),
                label: Text(_tr('Materials')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.preview_outlined),
                selectedIcon: const Icon(Icons.preview),
                label: Text(_tr('Preview')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.ios_share_outlined),
                selectedIcon: const Icon(Icons.ios_share),
                label: Text(_tr('Export')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: Text(_tr('Settings')),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: activePage),
        ],
      );

      return Scaffold(
        appBar: appBar,
        body: showHeader
            ? body
            : SafeArea(
                bottom: false,
                child: body,
              ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: showHeader
          ? activePage
          : SafeArea(
              bottom: false,
              child: activePage,
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _activePageIndex,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.folder_copy_outlined),
            selectedIcon: const Icon(Icons.folder_copy),
            label: _tr('Materials'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.preview_outlined),
            selectedIcon: const Icon(Icons.preview),
            label: _tr('Preview'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.ios_share_outlined),
            selectedIcon: const Icon(Icons.ios_share),
            label: _tr('Export'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: _tr('Settings'),
          ),
        ],
        onDestinationSelected: _setActivePage,
      ),
    );
  }

  Widget _buildActivePage() {
    final page = WorkspacePage.values[_activePageIndex];
    return switch (page) {
      WorkspacePage.management => _buildManagementPage(),
      WorkspacePage.preview => _buildPreviewPage(),
      WorkspacePage.export => _buildExportPage(),
      WorkspacePage.settings => _buildSettingsPage(),
    };
  }

  Widget _buildManagementPage() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: MaterialsPanel(
        files: _filteredFiles,
        selectedFile: _selectedFile,
        isBusy: _isBusy,
        searchText: _searchText,
        favoritesOnly: _favoritesOnly,
        statusMessage: _statusMessage,
        onImportPressed: _importFile,
        onImportCameraPressed: _importFromCamera,
        onFavoriteFilterChanged: _toggleFavoritesOnly,
        onSearchChanged: _updateSearchText,
        onFileSelected: _selectFile,
        onToggleFavorite: _toggleFileFavorite,
      ),
    );
  }

  Widget _buildPreviewPage() {
    final sourcePanel = PreviewSourcePanel(
      files: _filteredFiles,
      selectedFile: _selectedFile,
      statusMessage: _statusMessage,
      onFileSelected: _selectFile,
    );

    final cartSummaryPanel = PreviewCartSummaryPanel(
      cartColors: _exportColors,
      onRemoveColor: _removeExportColor,
      onClearPressed: _clearExportColors,
      onUseSelectedPalettePressed: _useSelectedPaletteAsExportBase,
      statusMessage: _statusMessage,
    );

    final canvasPanel = PreviewCanvasPanel(
      file: _selectedFile,
      isBusy: _isBusy,
      onImportPressed: _importFile,
      onImportCameraPressed: _importFromCamera,
      onProfileChanged: _updateExtractionProfile,
    );

    final inspectorPanel = PreviewInspectorPanel(
      file: _selectedFile,
      isBusy: _isBusy,
      onToggleCartColor: _toggleExportColor,
      isColorInCart: _isColorInExport,
      onProfileChanged: _updateExtractionProfile,
      onReextractPressed: _reextractSelectedFile,
      onSaveProfilePressed: _saveCurrentProfile,
      onApplySavedProfilePressed: _applySavedProfile,
      chartMode: _chartMode,
      onChartModeChanged: _setChartMode,
      previewVisionMode: _previewVisionMode,
      onPreviewVisionModeChanged: _setPreviewVisionMode,
      previewSeriesCount: _previewSeriesCount,
      onPreviewSeriesCountChanged: _setPreviewSeriesCount,
      previewGroupCount: _previewGroupCount,
      onPreviewGroupCountChanged: _setPreviewGroupCount,
      previewLineWidth: _previewLineWidth,
      onPreviewLineWidthChanged: _setPreviewLineWidth,
      previewMarkerSize: _previewMarkerSize,
      onPreviewMarkerSizeChanged: _setPreviewMarkerSize,
      previewAlphaPercent: _previewAlphaPercent,
      onPreviewAlphaPercentChanged: _setPreviewAlphaPercent,
      previewMarkerShape: _previewMarkerShape,
      onPreviewMarkerShapeChanged: _setPreviewMarkerShape,
      configExpanded: _previewConfigExpanded,
      resultExpanded: _previewResultExpanded,
      effectExpanded: _previewEffectExpanded,
      onConfigExpandedChanged: _setPreviewConfigExpanded,
      onResultExpandedChanged: _setPreviewResultExpanded,
      onEffectExpandedChanged: _setPreviewEffectExpanded,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final leftStack = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: sourcePanel),
            const SizedBox(height: 10),
            Expanded(child: cartSummaryPanel),
          ],
        );

        if (constraints.maxWidth >= LayoutContract.expandedBreakpoint) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 26, child: leftStack),
                const SizedBox(width: 10),
                Expanded(flex: 40, child: canvasPanel),
                const SizedBox(width: 10),
                Expanded(flex: 34, child: inspectorPanel),
              ],
            ),
          );
        }

        if (constraints.maxWidth >= LayoutContract.mediumBreakpoint) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 30, child: leftStack),
                const SizedBox(width: 10),
                Expanded(flex: 36, child: canvasPanel),
                const SizedBox(width: 10),
                Expanded(flex: 34, child: inspectorPanel),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 32,
                child: Row(
                  children: [
                    Expanded(child: sourcePanel),
                    const SizedBox(width: 8),
                    Expanded(child: cartSummaryPanel),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(flex: 34, child: canvasPanel),
              const SizedBox(height: 8),
              Expanded(flex: 34, child: inspectorPanel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportPage() {
    PaletteExportPayload? exportPreviewPayload;
    String? exportPreviewError;
    try {
      exportPreviewPayload = _buildCurrentExportPayload();
    } catch (error) {
      exportPreviewError = _tr(
        'Preview build failed: {error}',
        params: <String, String>{'error': error.toString()},
      );
    }

    final optionsPanel = ExportOptionsPanel(
      isBusy: _isBusy,
      statusMessage: _statusMessage,
      supportedExtensions: _importService.supportedExportExtensions,
      selectedExtension: _selectedExportExtension,
      exportFileName: _exportFileName,
      sortByLightness: _sortByLightness,
      exportAsHeatmapGradient: _exportAsHeatmapGradient,
      heatmapSteps: _heatmapSteps,
      generationKind: _generationKind,
      baseHex: _baseHex,
      secondaryHex: _secondaryHex,
      generationSteps: _generationSteps,
      whiteTemperature: _whiteTemperature,
      cartIsEmpty: _exportColors.isEmpty,
      colorCandidates: _generatorColorCandidates,
      isBaseColorPicking: _isPickingBaseColor,
      isSecondaryColorPicking: _isPickingSecondaryColor,
      formatExpanded: _exportFormatExpanded,
      generatorExpanded: _exportGeneratorExpanded,
      strategyExpanded: _exportStrategyExpanded,
      onBaseColorFieldPressed: _toggleBaseColorPicking,
      onSecondaryColorFieldPressed: _toggleSecondaryColorPicking,
      onFormatExpandedChanged: _setExportFormatExpanded,
      onGeneratorExpandedChanged: _setExportGeneratorExpanded,
      onStrategyExpandedChanged: _setExportStrategyExpanded,
      onSelectedExtensionChanged: _setSelectedExportExtension,
      onExportFileNameChanged: _setExportFileName,
      onExportPressed: _exportPalette,
      onSortByLightnessChanged: _setSortByLightness,
      onExportAsHeatmapGradientChanged: _setExportAsHeatmapGradient,
      onHeatmapStepsChanged: _setHeatmapSteps,
      onGenerationKindChanged: _setGenerationKind,
      onBaseHexChanged: _setBaseHex,
      onSecondaryHexChanged: _setSecondaryHex,
      onGenerationStepsChanged: _setGenerationSteps,
      onWhiteTemperatureChanged: _setWhiteTemperature,
      onGenerateReplacePressed: _generateAndReplace,
      onGenerateAppendPressed: _generateAndAppend,
    );

    final colorsPanel = ExportColorListPanel(
      cartColors: _exportColors,
      onRemoveColor: _removeExportColor,
      onUpdateColor: _updateExportColor,
      onClearPressed: _clearExportColors,
      onUseSelectedPalettePressed: _useSelectedPaletteAsExportBase,
      statusMessage: _statusMessage,
      isBusy: _isBusy,
      selectedIndex: _selectedExportColorIndex,
      isBaseColorPicking: _isPickingBaseColor,
      isSecondaryColorPicking: _isPickingSecondaryColor,
      listExpanded: _exportColorListExpanded,
      previewExpanded: _exportPreviewExpanded,
      previewFileName:
          '${_effectiveExportFileName}${_selectedExportExtension.toLowerCase()}',
      previewContent: exportPreviewPayload?.previewContent ?? '',
      previewExtension: _selectedExportExtension,
      previewError: exportPreviewError,
      onListExpandedChanged: _setExportColorListExpanded,
      onPreviewExpandedChanged: _setExportPreviewExpanded,
      onSelectedIndexChanged: _selectExportColorIndex,
      onAddManualColorPressed: _addManualExportColor,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < LayoutContract.mediumBreakpoint) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 44, child: optionsPanel),
                const SizedBox(height: 10),
                Expanded(flex: 56, child: colorsPanel),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 45,
                child: optionsPanel,
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 55,
                child: colorsPanel,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsPage() {
    final seedHex = _hexFromColor(widget.themeSeedColor);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [
          _SettingsCard(
            title: _tr('Appearance'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text(_tr('Light')),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text(_tr('Dark')),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text(_tr('System')),
                    ),
                  ],
                  selected: {widget.themeMode},
                  onSelectionChanged: (selection) {
                    if (selection.isNotEmpty) {
                      widget.onThemeModeChanged(selection.first);
                    }
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _autoThemeColor,
                  onChanged: _setAutoThemeColor,
                  title: Text(_tr('Auto pick theme color (from file/export cart)')),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: widget.useMaterialDynamicColor,
                  onChanged: widget.materialDynamicColorAvailable
                      ? widget.onUseMaterialDynamicColorChanged
                      : null,
                  title: Text(_tr('Android Material dynamic color')),
                  subtitle: Text(
                    widget.materialDynamicColorAvailable
                        ? _tr('When enabled, system dynamic colors are preferred')
                        : _tr('System dynamic colors are not available on this device'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _tr(
                    'Current theme color: {hex}',
                    params: <String, String>{'hex': seedHex},
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _themeColorPresets
                      .map(
                        (color) => ChoiceChip(
                          label: Text(_hexFromColor(color)),
                          selected: widget.themeSeedColor.toARGB32() ==
                              color.toARGB32(),
                          onSelected: (_) => _setThemeSeedColor(color),
                          avatar: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _applyAutoThemeSeedFromContext,
                      icon: const Icon(Icons.auto_fix_high),
                      label: Text(_tr('Pick automatically now')),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _setThemeSeedColor(const Color(0xFF1D4ED8)),
                      icon: const Icon(Icons.restart_alt),
                      label: Text(_tr('Reset default theme color')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            title: _tr('Language'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<AppLanguagePreference>(
                  segments: [
                    ButtonSegment<AppLanguagePreference>(
                      value: AppLanguagePreference.system,
                      label: Text(_tr('System')),
                    ),
                    ButtonSegment<AppLanguagePreference>(
                      value: AppLanguagePreference.zhCn,
                      label: Text(_tr('Chinese')),
                    ),
                    ButtonSegment<AppLanguagePreference>(
                      value: AppLanguagePreference.enUs,
                      label: Text(_tr('English (US)')),
                    ),
                  ],
                  selected: {widget.languagePreference},
                  onSelectionChanged: (selection) {
                    if (selection.isNotEmpty) {
                      widget.onLanguagePreferenceChanged(selection.first);
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(_tr('System language falls back to English (US) when unsupported.')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            title: _tr('Copyright'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr(
                    'Author: {author}\nVersion: {version}',
                    params: <String, String>{
                      'author': appAuthor,
                      'version': appVersion,
                    },
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: _openCopyrightPage,
                  icon: const Icon(Icons.gavel_outlined),
                  label: Text(_tr('Open copyright page')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
