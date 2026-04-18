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
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.themeSeedColor,
    required this.onThemeSeedColorChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final Color themeSeedColor;
  final ValueChanged<Color> onThemeSeedColorChanged;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final PaletteImportService _importService = PaletteImportService();
  final PaletteGenerationService _generationService =
      const PaletteGenerationService();

  late final List<String> _statusRotationMessages;
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

  bool _autoThemeColor = true;

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
    _statusRotationMessages = buildStatusRotationMessages();
    _statusRotationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || _statusRotationMessages.isEmpty) {
        return;
      }
      setState(() {
        _statusRotationIndex =
            (_statusRotationIndex + 1) % _statusRotationMessages.length;
      });
    });
  }

  @override
  void dispose() {
    _statusRotationTimer?.cancel();
    super.dispose();
  }

  String get _statusWatermarkMessage {
    if (_statusRotationMessages.isEmpty) {
      return nonCommercialNotice;
    }
    return _statusRotationMessages[
        _statusRotationIndex % _statusRotationMessages.length];
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

  bool _isColorInExport(ColorEntry color) {
    return _exportColorKeys.contains(_colorKey(color));
  }

  String _colorKey(ColorEntry color) {
    return '${color.name}|${color.hexCode}';
  }

  Future<void> _importFile() async {
    setState(() {
      _isBusy = true;
      _statusMessage = 'Importing file...';
    });

    try {
      final result = await _importService.pickAndImport();
      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _statusMessage = 'Import canceled.';
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
        _statusMessage =
            'Imported ${result.fileName} (${result.palette.colors.length} colors).';
        _isBusy = false;
      });

      _applyAutoThemeSeedFromContext();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = 'Import failed: $error';
        _isBusy = false;
      });
    }
  }

  Future<void> _importFromCamera() async {
    if (!_importService.canCaptureFromCamera) {
      setState(() {
        _statusMessage = _importService.cameraCaptureDisabledReason;
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _statusMessage = 'Capturing camera frame...';
    });

    try {
      final result = await _importService.captureFromCamera();
      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _statusMessage = 'Camera capture canceled.';
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
        _statusMessage =
            'Captured camera frame (${result.palette.colors.length} colors).';
        _isBusy = false;
      });

      _applyAutoThemeSeedFromContext();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _statusMessage = 'Camera import failed: $error';
      });
    }
  }

  void _selectFile(ManagedPaletteFile file) {
    setState(() {
      _selectedFile = file;
      _statusMessage =
          'Selected ${file.palette.name} (${file.palette.colors.length} colors).';
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
          ? 'Removing favorite...'
          : 'Saving favorite backup...';
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
          _statusMessage = 'Removed ${updated.fileName} from favorites.';
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
        _statusMessage =
            'Added ${updated.fileName} to favorites and backed up to favorate/$backupName';
        _isBusy = false;
      });
    } catch (error) {
      setState(() {
        _statusMessage = 'Favorite backup failed: $error';
        _isBusy = false;
      });
    }
  }

  void _toggleExportColor(ColorEntry color) {
    final key = _colorKey(color);
    setState(() {
      if (_exportColorKeys.remove(key)) {
        _exportColors.removeWhere((item) => _colorKey(item) == key);
        _statusMessage = 'Removed ${color.hexCode} from cart.';
      } else {
        _exportColorKeys.add(key);
        _exportColors.add(color);
        _statusMessage = 'Added ${color.hexCode} to cart.';
      }
    });
    _applyAutoThemeSeedFromContext();
  }

  void _removeExportColor(ColorEntry color) {
    final key = _colorKey(color);
    setState(() {
      _exportColorKeys.remove(key);
      _exportColors.removeWhere((item) => _colorKey(item) == key);
      _statusMessage = 'Removed ${color.hexCode} from cart.';
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
      _statusMessage = 'Updated ${color.name}.';
    });
    _applyAutoThemeSeedFromContext();
  }

  void _clearExportColors() {
    setState(() {
      _exportColorKeys.clear();
      _exportColors.clear();
      _statusMessage = 'Cart cleared.';
    });
  }

  void _useSelectedPaletteAsExportBase() {
    final current = _selectedFile;
    if (current == null) {
      setState(() {
        _statusMessage = 'Select a file first.';
      });
      return;
    }

    setState(() {
      _syncExportPaletteFromColors(current.palette.colors);
      _statusMessage = 'Loaded current file colors into export cart.';
    });
    _applyAutoThemeSeedFromContext();
  }

  Future<void> _exportPalette(String extension) async {
    if (_exportColors.isEmpty) {
      setState(() {
        _statusMessage = 'Cart is empty. Add colors before export.';
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _statusMessage = 'Exporting $extension...';
    });

    try {
      final palette = Palette(
        name: _selectedFile?.palette.name ?? 'Cart Palette',
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
        _statusMessage = 'Exported to ${output.path}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isBusy = false;
        _statusMessage = 'Export failed: $error';
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
      _statusMessage = 'Re-extracting colors...';
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
        _isBusy = false;
        _statusMessage =
            'Re-extracted ${updated.palette.colors.length} colors from ${updated.fileName}.';
      });

      _applyAutoThemeSeedFromContext();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _statusMessage = 'Re-extract failed: $error';
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
      _statusMessage = 'Saved extraction profile for ${current.fileName}.';
    });
  }

  Future<void> _applySavedProfile() async {
    final current = _selectedFile;
    if (current == null || current.savedProfile == null) {
      setState(() {
        _statusMessage = 'No saved profile for current file.';
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
    });
  }

  void _setSecondaryHex(String value) {
    setState(() {
      _secondaryHex = value;
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
        _statusMessage = append
            ? 'Appended ${generated.length} generated colors.'
            : 'Replaced cart with ${generated.length} generated colors.';
      });

      _applyAutoThemeSeedFromContext();
    } catch (error) {
      setState(() {
        _statusMessage = 'Generate failed: $error';
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
                    'Copyright & License',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'App: $appDisplayName\nVersion: $appVersion\nAuthor: $appAuthor',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    nonCommercialNotice,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    antiResaleMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Export source suffix: $exportNameSuffix',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('$appDisplayName $appVersion'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                _pageTitle(_activePageIndex),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ],
      ),
      body: _buildActivePage(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationBar(
            selectedIndex: _activePageIndex,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.folder_copy_outlined),
                selectedIcon: Icon(Icons.folder_copy),
                label: 'Materials',
              ),
              NavigationDestination(
                icon: Icon(Icons.preview_outlined),
                selectedIcon: Icon(Icons.preview),
                label: 'Preview',
              ),
              NavigationDestination(
                icon: Icon(Icons.ios_share_outlined),
                selectedIcon: Icon(Icons.ios_share),
                label: 'Export',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            onDestinationSelected: _setActivePage,
          ),
          _ComplianceStatusBar(message: _statusWatermarkMessage),
        ],
      ),
    );
  }

  String _pageTitle(int index) {
    final page = WorkspacePage.values[index];
    return switch (page) {
      WorkspacePage.management => '管理区',
      WorkspacePage.preview => '预览页',
      WorkspacePage.export => '导出页',
      WorkspacePage.settings => '设置页',
    };
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
    final leftPanel = PreviewSourcePanel(
      files: _filteredFiles,
      selectedFile: _selectedFile,
      statusMessage: _statusMessage,
      onFileSelected: _selectFile,
    );

    final centerPanel = DetailPanel(
      file: _selectedFile,
      isBusy: _isBusy,
      onImportPressed: _importFile,
      onImportCameraPressed: _importFromCamera,
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
    );

    final rightPanel = PreviewCartSummaryPanel(
      cartColors: _exportColors,
      onRemoveColor: _removeExportColor,
      onClearPressed: _clearExportColors,
      onUseSelectedPalettePressed: _useSelectedPaletteAsExportBase,
      statusMessage: _statusMessage,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < LayoutContract.mediumBreakpoint) {
          final panelWidth = math.max(320.0, constraints.maxWidth * 0.9);
          return Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: panelWidth * 3 + 24,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: panelWidth, child: leftPanel),
                    const SizedBox(width: 12),
                    SizedBox(width: panelWidth, child: centerPanel),
                    const SizedBox(width: 12),
                    SizedBox(width: panelWidth, child: rightPanel),
                  ],
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: LayoutContract.mediumLeftFlex,
                child: leftPanel,
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: LayoutContract.mediumCenterFlex,
                child: centerPanel,
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: LayoutContract.mediumRightFlex,
                child: rightPanel,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportPage() {
    final optionsPanel = ExportOptionsPanel(
      isBusy: _isBusy,
      statusMessage: _statusMessage,
      supportedExtensions: _importService.supportedExportExtensions,
      sortByLightness: _sortByLightness,
      exportAsHeatmapGradient: _exportAsHeatmapGradient,
      heatmapSteps: _heatmapSteps,
      generationKind: _generationKind,
      baseHex: _baseHex,
      secondaryHex: _secondaryHex,
      generationSteps: _generationSteps,
      whiteTemperature: _whiteTemperature,
      cartIsEmpty: _exportColors.isEmpty,
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
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < LayoutContract.mediumBreakpoint) {
          final panelWidth = math.max(360.0, constraints.maxWidth * 0.92);
          return Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: panelWidth * 2 + 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: panelWidth, child: optionsPanel),
                    const SizedBox(width: 12),
                    SizedBox(width: panelWidth, child: colorsPanel),
                  ],
                ),
              ),
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
            title: '软件外观',
            subtitle: '深色模式、软件取色与自动取色。',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: widget.isDarkMode,
                  onChanged: widget.onDarkModeChanged,
                  title: const Text('深色模式'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _autoThemeColor,
                  onChanged: _setAutoThemeColor,
                  title: const Text('自动取色（根据当前文件/导出区首色）'),
                ),
                const SizedBox(height: 8),
                Text('当前主题色: $seedHex'),
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
                      label: const Text('立即自动取色'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _setThemeSeedColor(const Color(0xFF1D4ED8)),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('恢复默认主题色'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            title: '版权页',
            subtitle: '查看上游署名、非商用协议与防倒卖提醒。',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Author: $appAuthor\nVersion: $appVersion',
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: _openCopyrightPage,
                  icon: const Icon(Icons.gavel_outlined),
                  label: const Text('打开版权页'),
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
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
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
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _ComplianceStatusBar extends StatelessWidget {
  const _ComplianceStatusBar({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
