import 'package:flutter/material.dart';

import '../core/models/color_entry.dart';
import '../core/models/palette.dart';

class MaterialsPanel extends StatelessWidget {
  const MaterialsPanel({
    super.key,
    required this.palettes,
    required this.selectedPalette,
    required this.isBusy,
    required this.searchText,
    required this.statusMessage,
    required this.onImportPressed,
    required this.onSearchChanged,
    required this.onPaletteSelected,
  });

  final List<Palette> palettes;
  final Palette? selectedPalette;
  final bool isBusy;
  final String searchText;
  final String? statusMessage;
  final Future<void> Function() onImportPressed;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<Palette> onPaletteSelected;

  @override
  Widget build(BuildContext context) {
    return _PanelFrame(
      title: 'Materials Browser',
      subtitle: 'Left zone: import, filter, and browse source palettes.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isBusy ? null : () => onImportPressed(),
                  icon: const Icon(Icons.file_open),
                  label: const Text('Import File'),
                ),
              ),
              if (isBusy) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: searchText,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by name or format',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          if (statusMessage != null && statusMessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _StatusText(message: statusMessage!),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: palettes.isEmpty
                ? const _EmptyState(
                    title: 'No materials imported',
                    description: 'Import JSON/CSV/GPL/ASE/PAL, image, or PDF to start.',
                  )
                : ListView.separated(
                    itemCount: palettes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final palette = palettes[index];
                      return Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          selected: identical(selectedPalette, palette),
                          leading: _ColorDot(hexCode: palette.previewColors.isEmpty ? '#CCCCCC' : palette.previewColors.first.hexCode),
                          title: Text(palette.name),
                          subtitle: Text(
                            '${palette.colors.length} colors · ${palette.sourceFormat.toUpperCase()}',
                          ),
                          onTap: () => onPaletteSelected(palette),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class DetailPanel extends StatelessWidget {
  const DetailPanel({
    super.key,
    required this.palette,
    required this.isBusy,
    required this.onImportPressed,
    required this.onToggleCartColor,
    required this.isColorInCart,
  });

  final Palette? palette;
  final bool isBusy;
  final Future<void> Function() onImportPressed;
  final ValueChanged<ColorEntry> onToggleCartColor;
  final bool Function(ColorEntry color) isColorInCart;

  @override
  Widget build(BuildContext context) {
    if (palette == null) {
      return _PanelFrame(
        title: 'Detail and Picking',
        subtitle: 'Center zone: preview, sampling, and color cards.',
        child: _EmptyState(
          title: 'No palette selected',
          description: 'Import a file from the left panel to inspect colors.',
          action: ElevatedButton.icon(
            onPressed: isBusy ? null : () => onImportPressed(),
            icon: const Icon(Icons.file_open),
            label: const Text('Import File'),
          ),
        ),
      );
    }

    return _PanelFrame(
      title: 'Detail and Picking',
      subtitle: 'Center zone: preview, sampling, and color cards.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  palette!.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: isBusy ? null : () => onImportPressed(),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Import'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${palette!.colors.length} colors · source: ${palette!.sourceFormat.toUpperCase()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth ~/ 180;
                final crossAxisCount = columns < 1 ? 1 : columns;
                return GridView.builder(
                  itemCount: palette!.colors.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.4,
                  ),
                  itemBuilder: (context, index) {
                    final color = palette!.colors[index];
                    return _ColorCard(
                      color: color,
                      selected: isColorInCart(color),
                      onPressed: () => onToggleCartColor(color),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CartPreviewPanel extends StatelessWidget {
  const CartPreviewPanel({
    super.key,
    required this.cartColors,
    required this.isBusy,
    required this.statusMessage,
    required this.onRemoveColor,
    required this.onClearPressed,
    required this.onExportPressed,
  });

  final List<ColorEntry> cartColors;
  final bool isBusy;
  final String? statusMessage;
  final ValueChanged<ColorEntry> onRemoveColor;
  final VoidCallback onClearPressed;
  final Future<void> Function(String extension) onExportPressed;

  @override
  Widget build(BuildContext context) {
    return _PanelFrame(
      title: 'Cart and Preview',
      subtitle: 'Right zone: compose, export, and quick palette preview.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: cartColors.isEmpty ? null : onClearPressed,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear Cart'),
                ),
              ),
              if (isBusy) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ExportButton(
                label: 'JSON',
                onPressed: cartColors.isEmpty || isBusy
                    ? null
                    : () => onExportPressed('.json'),
              ),
              _ExportButton(
                label: 'CSV',
                onPressed: cartColors.isEmpty || isBusy
                    ? null
                    : () => onExportPressed('.csv'),
              ),
              _ExportButton(
                label: 'ASE',
                onPressed: cartColors.isEmpty || isBusy
                    ? null
                    : () => onExportPressed('.ase'),
              ),
              _ExportButton(
                label: 'PAL',
                onPressed: cartColors.isEmpty || isBusy
                    ? null
                    : () => onExportPressed('.pal'),
              ),
            ],
          ),
          if (statusMessage != null && statusMessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _StatusText(message: statusMessage!),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: cartColors.isEmpty
                ? const _EmptyState(
                    title: 'Cart is empty',
                    description: 'Select colors in the center panel to build an export set.',
                  )
                : ListView.separated(
                    itemCount: cartColors.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final color = cartColors[index];
                      return Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: _ColorDot(hexCode: color.hexCode),
                          title: Text(color.name),
                          subtitle: Text(color.hexCode),
                          trailing: IconButton(
                            tooltip: 'Remove from cart',
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => onRemoveColor(color),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (cartColors.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 18,
              child: Row(
                children: cartColors
                    .map(
                      (color) => Expanded(
                        child: Container(color: _parseHexColor(color.hexCode)),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PanelFrame extends StatelessWidget {
  const _PanelFrame({
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
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _ColorCard extends StatelessWidget {
  const _ColorCard({
    required this.color,
    required this.selected,
    required this.onPressed,
  });

  final ColorEntry color;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        ),
        child: Row(
          children: [
            _ColorDot(hexCode: color.hexCode, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    color.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    color.hexCode,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.add_circle_outline,
              size: 20,
              color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.hexCode,
    this.size = 18,
  });

  final String hexCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: _parseHexColor(hexCode),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      message,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.primary,
          ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.description,
    this.action,
  });

  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

Color _parseHexColor(String hexCode) {
  final value = hexCode.replaceFirst('#', '').padLeft(6, '0').substring(0, 6);
  return Color(int.parse('FF$value', radix: 16));
}
