import 'dart:async';

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

enum WorkspaceLayoutMode {
  compact,
  medium,
  expanded,
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

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

  PaletteChartMode _chartMode = PaletteChartMode.table;
  bool _colorBlindFriendlyPreview = false;

  PaletteGenerationKind _generationKind =
      PaletteGenerationKind.twoColorGradient;
  WhiteTemperature _whiteTemperature = WhiteTemperature.neutral;
  String _baseHex = '#1D4ED8';
  String _secondaryHex = '#F97316';
  int _generationSteps = 5;

  bool _sortByLightness = false;
  bool _exportAsHeatmapGradient = false;
  int _heatmapSteps = 32;

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

  void _toggleFileFavorite(ManagedPaletteFile file) {
    final updated = file.copyWith(isFavorite: !file.isFavorite);
    _replaceRecord(updated);
    setState(() {
      _statusMessage = updated.isFavorite
          ? 'Added ${updated.fileName} to favorites.'
          : 'Removed ${updated.fileName} from favorites.';
    });
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
  }

  void _removeExportColor(ColorEntry color) {
    final key = _colorKey(color);
    setState(() {
      _exportColorKeys.remove(key);
      _exportColors.removeWhere((item) => _colorKey(item) == key);
      _statusMessage = 'Removed ${color.hexCode} from cart.';
    });
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

  void _setColorBlindFriendly(bool value) {
    setState(() {
      _colorBlindFriendlyPreview = value;
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

  @override
  Widget build(BuildContext context) {
    final panels = _buildPanels();

    return LayoutBuilder(
      builder: (context, constraints) {
        final mode = _resolveMode(constraints.maxWidth);
        if (mode == WorkspaceLayoutMode.compact) {
          return _CompactWorkspace(
            panels: panels,
            complianceMessage: _statusWatermarkMessage,
          );
        }
        return _WideWorkspace(
          mode: mode,
          panels: panels,
          complianceMessage: _statusWatermarkMessage,
        );
      },
    );
  }

  List<Widget> _buildPanels() {
    return <Widget>[
      MaterialsPanel(
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
      DetailPanel(
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
        colorBlindFriendlyPreview: _colorBlindFriendlyPreview,
        onColorBlindFriendlyChanged: _setColorBlindFriendly,
      ),
      CartPreviewPanel(
        cartColors: _exportColors,
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
        onRemoveColor: _removeExportColor,
        onUpdateColor: _updateExportColor,
        onClearPressed: _clearExportColors,
        onUseSelectedPalettePressed: _useSelectedPaletteAsExportBase,
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
      ),
    ];
  }

  WorkspaceLayoutMode _resolveMode(double width) {
    if (width >= LayoutContract.expandedBreakpoint) {
      return WorkspaceLayoutMode.expanded;
    }
    if (width >= LayoutContract.mediumBreakpoint) {
      return WorkspaceLayoutMode.medium;
    }
    return WorkspaceLayoutMode.compact;
  }
}

class _CompactWorkspace extends StatelessWidget {
  const _CompactWorkspace({
    required this.panels,
    required this.complianceMessage,
  });

  final List<Widget> panels;
  final String complianceMessage;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('$appDisplayName $appVersion'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Materials'),
              Tab(text: 'Detail'),
              Tab(text: 'Cart/Preview'),
            ],
          ),
        ),
        body: TabBarView(
          children: panels,
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ComplianceStatusBar(message: complianceMessage),
          ],
        ),
      ),
    );
  }
}

class _WideWorkspace extends StatelessWidget {
  const _WideWorkspace({
    required this.mode,
    required this.panels,
    required this.complianceMessage,
  });

  final WorkspaceLayoutMode mode;
  final List<Widget> panels;
  final String complianceMessage;

  @override
  Widget build(BuildContext context) {
    final leftFlex = mode == WorkspaceLayoutMode.expanded
        ? LayoutContract.expandedLeftFlex
        : LayoutContract.mediumLeftFlex;
    final centerFlex = mode == WorkspaceLayoutMode.expanded
        ? LayoutContract.expandedCenterFlex
        : LayoutContract.mediumCenterFlex;
    final rightFlex = mode == WorkspaceLayoutMode.expanded
        ? LayoutContract.expandedRightFlex
        : LayoutContract.mediumRightFlex;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: leftFlex,
                child: panels[0],
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: centerFlex,
                child: panels[1],
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: rightFlex,
                child: panels[2],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _ComplianceStatusBar(message: complianceMessage),
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
