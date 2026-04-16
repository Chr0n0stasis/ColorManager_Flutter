import 'package:flutter/material.dart';

import '../core/models/color_entry.dart';
import '../core/models/palette.dart';
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

  final List<Palette> _palettes = <Palette>[];
  final List<ColorEntry> _cartColors = <ColorEntry>[];
  final Set<String> _cartKeys = <String>{};

  Palette? _selectedPalette;
  String _searchText = '';
  String? _statusMessage;
  bool _isBusy = false;

  List<Palette> get _filteredPalettes {
    final keyword = _searchText.trim().toLowerCase();
    if (keyword.isEmpty) {
      return List<Palette>.unmodifiable(_palettes);
    }

    return List<Palette>.unmodifiable(
      _palettes.where(
        (palette) =>
            palette.name.toLowerCase().contains(keyword) ||
            palette.sourceFormat.toLowerCase().contains(keyword),
      ),
    );
  }

  bool _isColorInCart(ColorEntry color) {
    return _cartKeys.contains(_colorKey(color));
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
        _palettes.insert(0, result.palette);
        _selectedPalette = result.palette;
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

  void _selectPalette(Palette palette) {
    setState(() {
      _selectedPalette = palette;
      _statusMessage =
          'Selected ${palette.name} (${palette.colors.length} colors).';
    });
  }

  void _updateSearchText(String value) {
    setState(() {
      _searchText = value;
    });
  }

  void _toggleCartColor(ColorEntry color) {
    final key = _colorKey(color);
    setState(() {
      if (_cartKeys.remove(key)) {
        _cartColors.removeWhere((item) => _colorKey(item) == key);
        _statusMessage = 'Removed ${color.hexCode} from cart.';
      } else {
        _cartKeys.add(key);
        _cartColors.add(color);
        _statusMessage = 'Added ${color.hexCode} to cart.';
      }
    });
  }

  void _removeCartColor(ColorEntry color) {
    final key = _colorKey(color);
    setState(() {
      _cartKeys.remove(key);
      _cartColors.removeWhere((item) => _colorKey(item) == key);
      _statusMessage = 'Removed ${color.hexCode} from cart.';
    });
  }

  void _clearCart() {
    setState(() {
      _cartKeys.clear();
      _cartColors.clear();
      _statusMessage = 'Cart cleared.';
    });
  }

  Future<void> _exportCart(String extension) async {
    if (_cartColors.isEmpty) {
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
        name: _selectedPalette?.name ?? 'Cart Palette',
        colors: List<ColorEntry>.from(_cartColors),
        sourceFormat: extension.replaceFirst('.', ''),
      );

      final output = await _importService.exportToTempFile(
        palette: palette,
        extension: extension,
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

  @override
  Widget build(BuildContext context) {
    final panels = _buildPanels();

    return LayoutBuilder(
      builder: (context, constraints) {
        final mode = _resolveMode(constraints.maxWidth);
        if (mode == WorkspaceLayoutMode.compact) {
          return _CompactWorkspace(panels: panels);
        }
        return _WideWorkspace(mode: mode, panels: panels);
      },
    );
  }

  List<Widget> _buildPanels() {
    return <Widget>[
      MaterialsPanel(
        palettes: _filteredPalettes,
        selectedPalette: _selectedPalette,
        isBusy: _isBusy,
        searchText: _searchText,
        statusMessage: _statusMessage,
        onImportPressed: _importFile,
        onSearchChanged: _updateSearchText,
        onPaletteSelected: _selectPalette,
      ),
      DetailPanel(
        palette: _selectedPalette,
        isBusy: _isBusy,
        onImportPressed: _importFile,
        onToggleCartColor: _toggleCartColor,
        isColorInCart: _isColorInCart,
      ),
      CartPreviewPanel(
        cartColors: _cartColors,
        isBusy: _isBusy,
        statusMessage: _statusMessage,
        onRemoveColor: _removeCartColor,
        onClearPressed: _clearCart,
        onExportPressed: _exportCart,
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
  const _CompactWorkspace({required this.panels});

  final List<Widget> panels;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ColorManager'),
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
      ),
    );
  }
}

class _WideWorkspace extends StatelessWidget {
  const _WideWorkspace({
    required this.mode,
    required this.panels,
  });

  final WorkspaceLayoutMode mode;
  final List<Widget> panels;

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
    );
  }
}
