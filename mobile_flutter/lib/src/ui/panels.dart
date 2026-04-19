import '../core/models/color_entry.dart';
import '../core/models/extraction_profile.dart';
import '../core/models/managed_palette_file.dart';
import '../core/services/palette_generation_service.dart';
import '../i18n/app_localizations.dart';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;




enum PaletteChartMode {
  table,
  line,
  bar,
  scatter,
  heatmap,
  circular,
  map,
}

enum PalettePreviewVisionMode {
  normal,
  grayscale,
  colorblindProtan,
  colorblindDeutan,
  colorblindTritan,
}

enum PaletteMarkerShape {
  circle,
  square,
  triangle,
}

class MaterialsPanel extends StatelessWidget {
  const MaterialsPanel({
    super.key,
    required this.favoriteFiles,
    required this.importedFiles,
    required this.selectedFile,
    required this.isBusy,
    required this.searchText,
    required this.statusMessage,
    required this.favoritesExpanded,
    required this.importedExpanded,
    required this.favoriteEditMode,
    required this.importedEditMode,
    required this.selectedFavoriteIds,
    required this.selectedImportedIds,
    this.headerTitle,
    this.headerSubtitle,
    required this.onImportPressed,
    required this.onImportCameraPressed,
    required this.onImportCloudPressed,
    required this.onSearchChanged,
    required this.onFavoritesExpandedChanged,
    required this.onImportedExpandedChanged,
    required this.onFavoriteEditModeChanged,
    required this.onImportedEditModeChanged,
    required this.onToggleFavoriteSelection,
    required this.onToggleImportedSelection,
    required this.onSelectAllFavorites,
    required this.onInvertFavoritesSelection,
    required this.onSelectAllImported,
    required this.onInvertImportedSelection,
    required this.onUnfavoriteSelectedPressed,
    required this.onDeleteImportedSelectedPressed,
    required this.onReorderFavorites,
    required this.onReorderImported,
    required this.onFileSelected,
    required this.onToggleFavorite,
  });

  final List<ManagedPaletteFile> favoriteFiles;
  final List<ManagedPaletteFile> importedFiles;
  final ManagedPaletteFile? selectedFile;
  final bool isBusy;
  final String searchText;
  final String? statusMessage;
  final bool favoritesExpanded;
  final bool importedExpanded;
  final bool favoriteEditMode;
  final bool importedEditMode;
  final Set<String> selectedFavoriteIds;
  final Set<String> selectedImportedIds;
  final String? headerTitle;
  final String? headerSubtitle;
  final Future<void> Function() onImportPressed;
  final Future<void> Function() onImportCameraPressed;
  final Future<void> Function() onImportCloudPressed;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onFavoritesExpandedChanged;
  final ValueChanged<bool> onImportedExpandedChanged;
  final ValueChanged<bool> onFavoriteEditModeChanged;
  final ValueChanged<bool> onImportedEditModeChanged;
  final ValueChanged<String> onToggleFavoriteSelection;
  final ValueChanged<String> onToggleImportedSelection;
  final VoidCallback onSelectAllFavorites;
  final VoidCallback onInvertFavoritesSelection;
  final VoidCallback onSelectAllImported;
  final VoidCallback onInvertImportedSelection;
  final Future<void> Function() onUnfavoriteSelectedPressed;
  final VoidCallback onDeleteImportedSelectedPressed;
  final void Function(int oldIndex, int newIndex) onReorderFavorites;
  final void Function(int oldIndex, int newIndex) onReorderImported;
  final ValueChanged<ManagedPaletteFile> onFileSelected;
  final Future<void> Function(ManagedPaletteFile) onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final hasAnyFile = favoriteFiles.isNotEmpty || importedFiles.isNotEmpty;
    final favoritesListHeight = favoriteFiles.length > 8 ? 340.0 : 230.0;
    final importedListHeight = importedFiles.length > 8 ? 340.0 : 230.0;
    final headerButtonStyle = OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const Size(0, 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
    final headerIconButtonStyle = OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const Size(34, 34),
      padding: EdgeInsets.zero,
    );

    return _PanelFrame(
      title: 'Management',
      subtitle: '',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (headerTitle != null) ...[
            Text(
              headerTitle!,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (headerSubtitle != null && headerSubtitle!.isNotEmpty)
              Text(
                headerSubtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: searchText,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: context.tr('Search by file name/format'),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isBusy)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.add,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),

                    tooltip: context.tr('Import'),
                    onSelected: (value) {
                      if (value == 'local') {
                        onImportPressed();
                      } else if (value == 'camera') {
                        onImportCameraPressed();
                      } else if (value == 'cloud') {
                        onImportCloudPressed();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'local',
                        child: Row(
                          children: [
                            const Icon(Icons.folder_open),
                            const SizedBox(width: 12),
                            Text(context.tr('Import from Local')),
                          ],
                        ),

                      ),

                      PopupMenuItem(
                        value: 'camera',
                        child: Row(
                          children: [
                            const Icon(Icons.photo_camera_outlined),
                            const SizedBox(width: 12),
                            Text(context.tr('Import from Camera')),
                          ],
                        ),

                      ),

                      PopupMenuItem(
                        value: 'cloud',
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_upload_outlined),
                            const SizedBox(width: 12),
                            Text(context.tr('Import from Cloud Storage')),
                          ],
                        ),

                      ),

                    ],
                  ),
                ),
            ],
          ),
          if (statusMessage != null && statusMessage!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _StatusText(message: statusMessage!),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: !hasAnyFile
                ? const _EmptyState(
                    title: 'No files yet',
                    description:
                        'Supports JSON/CSV/GPL/CPT/ASE/PAL, images and PDF.',
                  )
                : ListView(
                    children: [
                      _FoldCard(
                        title: 'Favorites',
                        expanded: favoritesExpanded,
                        onExpandedChanged: onFavoritesExpandedChanged,
                        headerAction: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return ClipRect(
                              child: SizeTransition(
                                sizeFactor: animation,
                                axis: Axis.horizontal,
                                axisAlignment: -1,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),

                              ),

                            );
                          },
                          child: favoriteEditMode
                              ? Row(
                                  key: const ValueKey<String>(
                                      'favorite-actions'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Tooltip(
                                      message: context.tr('Close'),
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            onFavoriteEditModeChanged(false),
                                        style: headerIconButtonStyle,
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 17,
                                        ),

                                      ),

                                    ),

                                    const SizedBox(width: 6),
                                    OutlinedButton.icon(
                                      onPressed: selectedFavoriteIds.isEmpty ||
                                              isBusy
                                          ? null
                                          : () => onUnfavoriteSelectedPressed(),
                                      style: headerButtonStyle,
                                      icon: const Icon(
                                        Icons.star_outline,
                                        size: 16,
                                      ),

                                      label: Text(
                                        context.tr('Unfavorite Selected'),
                                        maxLines: 1,
                                        overflow: TextOverflow.visible,
                                        softWrap: false,
                                      ),

                                    ),

                                    const SizedBox(width: 6),
                                    OutlinedButton(
                                      onPressed: favoriteFiles.isEmpty
                                          ? null
                                          : onSelectAllFavorites,
                                      style: headerButtonStyle,
                                      child: Text(
                                        context.tr('Select All'),
                                        maxLines: 1,
                                        overflow: TextOverflow.visible,
                                        softWrap: false,
                                      ),

                                    ),

                                    const SizedBox(width: 6),
                                    OutlinedButton(
                                      onPressed: favoriteFiles.isEmpty
                                          ? null
                                          : onInvertFavoritesSelection,
                                      style: headerButtonStyle,
                                      child: Text(
                                        context.tr('Invert Selection'),
                                        maxLines: 1,
                                        overflow: TextOverflow.visible,
                                        softWrap: false,
                                      ),

                                    ),

                                  ],
                                )
                              : OutlinedButton.icon(
                                  key: const ValueKey<String>('favorite-edit'),
                                  onPressed: favoriteFiles.isEmpty
                                      ? null
                                      : () => onFavoriteEditModeChanged(true),
                                  style: headerButtonStyle,
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 16),
                                  label: Text(
                                    context.tr('Edit Favorites'),
                                    maxLines: 1,
                                    overflow: TextOverflow.visible,
                                    softWrap: false,
                                  ),

                                ),

                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: favoritesListHeight,
                              child: favoriteFiles.isEmpty
                                  ? const _EmptyState(
                                      title: 'No favorites yet',
                                      description:
                                          'Tap star in Imported Files to move items here.',
                                    )
                                  : ReorderableListView.builder(
                                      itemCount: favoriteFiles.length,
                                      onReorder: onReorderFavorites,
                                      buildDefaultDragHandles: false,
                                      itemBuilder: (context, index) {
                                        final file = favoriteFiles[index];
                                        final selectedInEdit =
                                            selectedFavoriteIds
                                                .contains(file.id);
                                        final selected = favoriteEditMode
                                            ? selectedInEdit
                                            : selectedFile?.id == file.id;
                                        final firstHex =
                                            file.palette.previewColors.isEmpty
                                                ? '#CCCCCC'
                                                : file.palette.previewColors
                                                    .first.hexCode;
                                        final borderColor = selected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .outlineVariant;
                                        return Card(
                                          key: ValueKey<String>(
                                              'favorite-file-${file.id}'),
                                          margin:
                                              const EdgeInsets.only(bottom: 4),
                                          clipBehavior: Clip.antiAlias,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            side: BorderSide(
                                              color: borderColor,
                                              width: selected ? 2 : 1,
                                            ),

                                          ),

                                          child: ListTile(
                                            selected: selected,
                                            onTap: favoriteEditMode
                                                ? () =>
                                                    onToggleFavoriteSelection(
                                                      file.id,
                                                    )
                                                : () => onFileSelected(file),
                                            leading:
                                                _ColorDot(hexCode: firstHex),
                                            title: Text(
                                              file.fileName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),

                                            subtitle: Text(
                                              context.tr(
                                                '{count} colors · {format} · {mode} · Re-sampled {runs} times',
                                                params: <String, String>{
                                                  'count': file
                                                      .palette.colors.length
                                                      .toString(),
                                                  'format': file
                                                      .palette.sourceFormat
                                                      .toUpperCase(),
                                                  'mode': context.tr(_modeLabel(
                                                      file.extractionProfile
                                                          .mode)),
                                                  'runs': file.extractionRuns
                                                      .toString(),
                                                },
                                              ),

                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),

                                            trailing: favoriteEditMode
                                                ? ReorderableDragStartListener(
                                                    index: index,
                                                    child: Icon(
                                                      Icons.drag_indicator,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),

                                                  )
                                                : null,
                                          ),

                                        );
                                      },
                                    ),

                            ),

                          ],
                        ),

                      ),

                      const SizedBox(height: 8),
                      _FoldCard(
                        title: 'Imported Files',
                        expanded: importedExpanded,
                        onExpandedChanged: onImportedExpandedChanged,
                        headerAction: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return ClipRect(
                              child: SizeTransition(
                                sizeFactor: animation,
                                axis: Axis.horizontal,
                                axisAlignment: -1,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),

                              ),

                            );
                          },
                          child: importedEditMode
                              ? Row(
                                  key: const ValueKey<String>(
                                      'imported-actions'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Tooltip(
                                      message: context.tr('Close'),
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            onImportedEditModeChanged(false),
                                        style: headerIconButtonStyle,
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 17,
                                        ),

                                      ),

                                    ),

                                    const SizedBox(width: 6),
                                    OutlinedButton.icon(
                                      onPressed:
                                          selectedImportedIds.isEmpty || isBusy
                                              ? null
                                              : onDeleteImportedSelectedPressed,
                                      style: headerButtonStyle,
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 16,
                                      ),

                                      label: Text(
                                        context.tr('Delete Selected'),
                                        maxLines: 1,
                                        overflow: TextOverflow.visible,
                                        softWrap: false,
                                      ),

                                    ),

                                    const SizedBox(width: 6),
                                    OutlinedButton(
                                      onPressed: importedFiles.isEmpty
                                          ? null
                                          : onSelectAllImported,
                                      style: headerButtonStyle,
                                      child: Text(
                                        context.tr('Select All'),
                                        maxLines: 1,
                                        overflow: TextOverflow.visible,
                                        softWrap: false,
                                      ),

                                    ),

                                    const SizedBox(width: 6),
                                    OutlinedButton(
                                      onPressed: importedFiles.isEmpty
                                          ? null
                                          : onInvertImportedSelection,
                                      style: headerButtonStyle,
                                      child: Text(
                                        context.tr('Invert Selection'),
                                        maxLines: 1,
                                        overflow: TextOverflow.visible,
                                        softWrap: false,
                                      ),

                                    ),

                                  ],
                                )
                              : OutlinedButton.icon(
                                  key: const ValueKey<String>('imported-edit'),
                                  onPressed: importedFiles.isEmpty
                                      ? null
                                      : () => onImportedEditModeChanged(true),
                                  style: headerButtonStyle,
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 16),
                                  label: Text(
                                        context.tr('Edit Imported Files'),
                                        maxLines: 1,
                                        overflow: TextOverflow.visible,
                                        softWrap: false,
                                      ),

                                ),

                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: importedListHeight,
                              child: importedFiles.isEmpty
                                  ? const _EmptyState(
                                      title: 'No imported files',
                                      description:
                                          'Use the + button above to import files.',
                                    )
                                  : ReorderableListView.builder(
                                      itemCount: importedFiles.length,
                                      onReorder: onReorderImported,
                                      buildDefaultDragHandles: false,
                                      itemBuilder: (context, index) {
                                        final file = importedFiles[index];
                                        final selectedInEdit =
                                            selectedImportedIds
                                                .contains(file.id);
                                        final selected = importedEditMode
                                            ? selectedInEdit
                                            : selectedFile?.id == file.id;
                                        final firstHex =
                                            file.palette.previewColors.isEmpty
                                                ? '#CCCCCC'
                                                : file.palette.previewColors
                                                    .first.hexCode;
                                        final borderColor = selected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .outlineVariant;

                                        return Card(
                                          key: ValueKey<String>(
                                              'imported-file-${file.id}'),
                                          margin:
                                              const EdgeInsets.only(bottom: 4),
                                          clipBehavior: Clip.antiAlias,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            side: BorderSide(
                                              color: borderColor,
                                              width: selected ? 2 : 1,
                                            ),

                                          ),

                                          child: ListTile(
                                            selected: selected,
                                            onTap: importedEditMode
                                                ? () =>
                                                    onToggleImportedSelection(
                                                      file.id,
                                                    )
                                                : () => onFileSelected(file),
                                            leading:
                                                _ColorDot(hexCode: firstHex),
                                            title: Text(
                                              file.fileName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),

                                            subtitle: Text(
                                              context.tr(
                                                '{count} colors · {format} · {mode} · Re-sampled {runs} times',
                                                params: <String, String>{
                                                  'count': file
                                                      .palette.colors.length
                                                      .toString(),
                                                  'format': file
                                                      .palette.sourceFormat
                                                      .toUpperCase(),
                                                  'mode': context.tr(_modeLabel(
                                                      file.extractionProfile
                                                          .mode)),
                                                  'runs': file.extractionRuns
                                                      .toString(),
                                                },
                                              ),

                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),

                                            trailing: importedEditMode
                                                ? ReorderableDragStartListener(
                                                    index: index,
                                                    child: Icon(
                                                      Icons.drag_indicator,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),

                                                  )
                                                : IconButton(
                                                    tooltip: context
                                                        .tr('Add favorite'),
                                                    icon: const Icon(
                                                      Icons.star_border,
                                                    ),

                                                    onPressed: isBusy
                                                        ? null
                                                        : () =>
                                                            onToggleFavorite(
                                                                file),
                                                  ),

                                          ),

                                        );
                                      },
                                    ),

                            ),

                          ],
                        ),

                      ),

                    ],
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
    required this.file,
    required this.isBusy,
    required this.onImportPressed,
    required this.onImportCameraPressed,
    required this.onToggleCartColor,
    required this.isColorInCart,
    required this.onProfileChanged,
    required this.onReextractPressed,
    required this.onSaveProfilePressed,
    required this.onApplySavedProfilePressed,
    required this.chartMode,
    required this.onChartModeChanged,
    required this.previewVisionMode,
    required this.onPreviewVisionModeChanged,
    required this.previewSeriesCount,
    required this.onPreviewSeriesCountChanged,
    required this.previewGroupCount,
    required this.onPreviewGroupCountChanged,
    required this.previewLineWidth,
    required this.onPreviewLineWidthChanged,
    required this.previewMarkerSize,
    required this.onPreviewMarkerSizeChanged,
    required this.previewAlphaPercent,
    required this.onPreviewAlphaPercentChanged,
    required this.previewMarkerShape,
    required this.onPreviewMarkerShapeChanged,
  });

  final ManagedPaletteFile? file;
  final bool isBusy;
  final Future<void> Function() onImportPressed;
  final Future<void> Function() onImportCameraPressed;
  final ValueChanged<ColorEntry> onToggleCartColor;
  final bool Function(ColorEntry color) isColorInCart;
  final ValueChanged<ExtractionProfile> onProfileChanged;
  final Future<void> Function() onReextractPressed;
  final VoidCallback onSaveProfilePressed;
  final Future<void> Function() onApplySavedProfilePressed;
  final PaletteChartMode chartMode;
  final ValueChanged<PaletteChartMode> onChartModeChanged;
  final PalettePreviewVisionMode previewVisionMode;
  final ValueChanged<PalettePreviewVisionMode> onPreviewVisionModeChanged;
  final int previewSeriesCount;
  final ValueChanged<double> onPreviewSeriesCountChanged;
  final int previewGroupCount;
  final ValueChanged<double> onPreviewGroupCountChanged;
  final int previewLineWidth;
  final ValueChanged<double> onPreviewLineWidthChanged;
  final int previewMarkerSize;
  final ValueChanged<double> onPreviewMarkerSizeChanged;
  final int previewAlphaPercent;
  final ValueChanged<double> onPreviewAlphaPercentChanged;
  final PaletteMarkerShape previewMarkerShape;
  final ValueChanged<PaletteMarkerShape> onPreviewMarkerShapeChanged;

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return _PanelFrame(
        title: 'Preview',
        subtitle: 'File preview, sampling modes, and chart preview.',
        child: _EmptyState(
          title: 'No file selected',
          description:
              'Import or select a file from the left to start sampling.',
          action: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: isBusy ? null : () => onImportPressed(),
                icon: const Icon(Icons.file_open),
                label: Text(context.tr('Import File')),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : () => onImportCameraPressed(),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(context.tr('Camera Sampling')),
              ),
            ],
          ),
        ),
      );
    }

    final usesMarkerShape = _chartModeUsesMarkerShape(chartMode);

    return _PanelFrame(
      title: 'Preview',
      subtitle:
          'Supports whole file/page/visible range/box selection/eyedropper/camera mode.',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    file!.fileName,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : () => onImportPressed(),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(context.tr('Import')),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(
                '{count} colors · {format} · Current mode: {mode}',
                params: <String, String>{
                  'count': file!.palette.colors.length.toString(),
                  'format': file!.palette.sourceFormat.toUpperCase(),
                  'mode': context.tr(_modeLabel(file!.extractionProfile.mode)),
                },
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            if (file!.previewBytes != null) ...[
              _PreviewBox(
                imageBytes: file!.previewBytes!,
                profile: file!.extractionProfile,
                onProfileChanged: onProfileChanged,
              ),
              const SizedBox(height: 10),
            ],
            _ExtractionControls(
              profile: file!.extractionProfile,
              sourceKind: file!.sourceKind.name,
              hasSavedProfile: file!.savedProfile != null,
              isBusy: isBusy,
              onProfileChanged: onProfileChanged,
              onReextractPressed: onReextractPressed,
              onSaveProfilePressed: onSaveProfilePressed,
              onApplySavedProfilePressed: onApplySavedProfilePressed,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('Sampling results (tap to add into export cart)'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: file!.palette.colors
                  .map(
                    (color) => SizedBox(
                      width: 188,
                      child: _ColorCard(
                        color: color,
                        selected: isColorInCart(color),
                        onPressed: () => onToggleCartColor(color),
                      ),

                    ),

                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<PaletteChartMode>(
                    initialValue: chartMode,
                    decoration: InputDecoration(
                      labelText: context.tr('Chart Style'),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),

                    items: PaletteChartMode.values
                        .map(
                          (mode) => DropdownMenuItem<PaletteChartMode>(
                            value: mode,
                            child: Text(context.tr(_chartModeLabel(mode))),
                          ),

                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        onChartModeChanged(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<PalettePreviewVisionMode>(
                    initialValue: previewVisionMode,
                    decoration: InputDecoration(
                      labelText: context.tr('Vision Mode'),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),

                    items: PalettePreviewVisionMode.values
                        .map(
                          (mode) => DropdownMenuItem<PalettePreviewVisionMode>(
                            value: mode,
                            child: Text(context.tr(_visionModeLabel(mode))),
                          ),

                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        onPreviewVisionModeChanged(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (usesMarkerShape) ...[
                  Expanded(
                    child: DropdownButtonFormField<PaletteMarkerShape>(
                      initialValue: previewMarkerShape,
                      decoration: InputDecoration(
                        labelText: context.tr('Marker Shape'),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),

                      items: PaletteMarkerShape.values
                          .map(
                            (shape) => DropdownMenuItem<PaletteMarkerShape>(
                              value: shape,
                              child:
                                  Text(context.tr(_markerShapeLabel(shape))),
                            ),

                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          onPreviewMarkerShapeChanged(value);
                        }
                      },
                    ),

                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    'Series $previewSeriesCount · Group $previewGroupCount · Alpha $previewAlphaPercent%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _LabeledSlider(
              label: 'Series: $previewSeriesCount',
              value: previewSeriesCount.toDouble(),
              min: 1,
              max: 24,
              divisions: 23,
              onChanged: onPreviewSeriesCountChanged,
            ),
            _LabeledSlider(
              label: 'Group: $previewGroupCount',
              value: previewGroupCount.toDouble(),
              min: 2,
              max: 48,
              divisions: 46,
              onChanged: onPreviewGroupCountChanged,
            ),
            _LabeledSlider(
              label: 'Line Width: $previewLineWidth',
              value: previewLineWidth.toDouble(),
              min: 1,
              max: 8,
              divisions: 7,
              onChanged: onPreviewLineWidthChanged,
            ),
            _LabeledSlider(
              label: 'Point Size: $previewMarkerSize',
              value: previewMarkerSize.toDouble(),
              min: 2,
              max: 18,
              divisions: 16,
              onChanged: onPreviewMarkerSizeChanged,
            ),
            _LabeledSlider(
              label: 'Alpha: $previewAlphaPercent%',
              value: previewAlphaPercent.toDouble(),
              min: 10,
              max: 100,
              divisions: 18,
              onChanged: onPreviewAlphaPercentChanged,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
              child: _PaletteChartPreview(
                colors: file!.palette.colors,
                mode: chartMode,
                visionMode: previewVisionMode,
                seriesCount: previewSeriesCount,
                groupCount: previewGroupCount,
                lineWidth: previewLineWidth,
                markerSize: previewMarkerSize,
                markerShape: previewMarkerShape,
                alphaPercent: previewAlphaPercent,
                isSelected: isColorInCart,
              ),
            ),
          ],
        ),
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
    required this.supportedExtensions,
    required this.sortByLightness,
    required this.exportAsHeatmapGradient,
    required this.heatmapSteps,
    required this.generationKind,
    required this.baseHex,
    required this.secondaryHex,
    required this.generationSteps,
    required this.whiteTemperature,
    required this.onRemoveColor,
    required this.onUpdateColor,
    required this.onClearPressed,
    required this.onUseSelectedPalettePressed,
    required this.onExportPressed,
    required this.onSortByLightnessChanged,
    required this.onExportAsHeatmapGradientChanged,
    required this.onHeatmapStepsChanged,
    required this.onGenerationKindChanged,
    required this.onBaseHexChanged,
    required this.onSecondaryHexChanged,
    required this.onGenerationStepsChanged,
    required this.onWhiteTemperatureChanged,
    required this.onGenerateReplacePressed,
    required this.onGenerateAppendPressed,
  });

  final List<ColorEntry> cartColors;
  final bool isBusy;
  final String? statusMessage;
  final List<String> supportedExtensions;
  final bool sortByLightness;
  final bool exportAsHeatmapGradient;
  final int heatmapSteps;
  final PaletteGenerationKind generationKind;
  final String baseHex;
  final String secondaryHex;
  final int generationSteps;
  final WhiteTemperature whiteTemperature;
  final ValueChanged<ColorEntry> onRemoveColor;
  final void Function(int index, ColorEntry color) onUpdateColor;
  final VoidCallback onClearPressed;
  final VoidCallback onUseSelectedPalettePressed;
  final Future<void> Function(String extension) onExportPressed;
  final ValueChanged<bool> onSortByLightnessChanged;
  final ValueChanged<bool> onExportAsHeatmapGradientChanged;
  final ValueChanged<double> onHeatmapStepsChanged;
  final ValueChanged<PaletteGenerationKind> onGenerationKindChanged;
  final ValueChanged<String> onBaseHexChanged;
  final ValueChanged<String> onSecondaryHexChanged;
  final ValueChanged<double> onGenerationStepsChanged;
  final ValueChanged<WhiteTemperature> onWhiteTemperatureChanged;
  final VoidCallback onGenerateReplacePressed;
  final VoidCallback onGenerateAppendPressed;

  @override
  Widget build(BuildContext context) {
    return _PanelFrame(
      title: 'Export',
      subtitle:
          'Edit export palette, generate schemes, sort and export scientific formats.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: cartColors.isEmpty ? null : onClearPressed,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(context.tr('Clear Export Cart')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUseSelectedPalettePressed,
                  icon: const Icon(Icons.layers_outlined),
                  label: Text(context.tr('Load Current File')),
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
          _SectionCard(
            title: 'Heatmap Palette Generator',
            child: Column(
              children: [
                DropdownButtonFormField<PaletteGenerationKind>(
                  initialValue: generationKind,
                  decoration: InputDecoration(
                    labelText: context.tr('Generation Mode'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: PaletteGenerationKind.values
                      .map(
                        (kind) => DropdownMenuItem<PaletteGenerationKind>(
                          value: kind,
                          child: Text(context.tr(_generationLabel(kind))),
                        ),

                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      onGenerationKindChanged(value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: baseHex,
                        onChanged: onBaseHexChanged,
                        decoration: InputDecoration(
                          labelText: context.tr('Base (HEX)'),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),

                      ),

                    ),

                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: secondaryHex,
                        onChanged: onSecondaryHexChanged,
                        decoration: InputDecoration(
                          labelText: context.tr('Secondary (HEX)'),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),

                      ),

                    ),

                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      context.tr(
                        'Count: {count}',
                        params: <String, String>{
                          'count': generationSteps.toString(),
                        },
                      ),

                    ),

                    Expanded(
                      child: Slider(
                        min: 2,
                        max: 20,
                        divisions: 18,
                        value: generationSteps.toDouble(),
                        label: '$generationSteps',
                        onChanged: onGenerationStepsChanged,
                      ),

                    ),

                  ],
                ),
                if (generationKind == PaletteGenerationKind.toWhite) ...[
                  const SizedBox(height: 4),
                  DropdownButtonFormField<WhiteTemperature>(
                    initialValue: whiteTemperature,
                    decoration: InputDecoration(
                      labelText: context.tr('White Temperature'),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),

                    items: WhiteTemperature.values
                        .map(
                          (value) => DropdownMenuItem<WhiteTemperature>(
                            value: value,
                            child:
                                Text(context.tr(_whiteTemperatureLabel(value))),
                          ),

                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        onWhiteTemperatureChanged(value);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: isBusy ? null : onGenerateReplacePressed,
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: Text(context.tr('Replace Export Cart')),
                      ),

                    ),

                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: isBusy ? null : onGenerateAppendPressed,
                        icon: const Icon(Icons.add),
                        label: Text(context.tr('Append To Export Cart')),
                      ),

                    ),

                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            title: 'Export Strategy',
            child: Column(
              children: [
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: sortByLightness,
                  onChanged: onSortByLightnessChanged,
                  title: Text(context.tr('Sort by lightness before export')),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: exportAsHeatmapGradient,
                  onChanged: onExportAsHeatmapGradientChanged,
                  title: Text(context.tr('Export as heatmap gradient')),
                ),
                if (exportAsHeatmapGradient)
                  Row(
                    children: [
                      Text(
                        context.tr(
                          'Heatmap Steps: {count}',
                          params: <String, String>{
                            'count': heatmapSteps.toString(),
                          },
                        ),

                      ),

                      Expanded(
                        child: Slider(
                          min: 2,
                          max: 512,
                          divisions: 510,
                          value: heatmapSteps.toDouble(),
                          label: '$heatmapSteps',
                          onChanged: onHeatmapStepsChanged,
                        ),

                      ),

                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: supportedExtensions
                .map(
                  (ext) => OutlinedButton(
                    onPressed: cartColors.isEmpty || isBusy
                        ? null
                        : () => onExportPressed(ext),
                    child: Text(ext.toUpperCase().replaceFirst('.', '')),
                  ),
                )
                .toList(growable: false),
          ),
          if (statusMessage != null && statusMessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _StatusText(message: statusMessage!),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: cartColors.isEmpty
                ? const _EmptyState(
                    title: 'Export cart is empty',
                    description:
                        'Pick colors from preview, or generate from the top panel.',
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
                          onTap: () => _showEditDialog(
                            context,
                            index,
                            color,
                            onUpdateColor,
                          ),

                          trailing: IconButton(
                            tooltip: context.tr('Remove'),
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
              height: 20,
              child: Row(
                children: cartColors
                    .map(
                      (color) => Expanded(
                        child: Container(
                          color: _parseHexColor(color.hexCode),
                        ),

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

  Future<void> _showEditDialog(
    BuildContext context,
    int index,
    ColorEntry color,
    void Function(int index, ColorEntry color) onUpdate,
  ) async {
    final nameController = TextEditingController(text: color.name);
    final hexController = TextEditingController(text: color.hexCode);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr('Edit Export Color')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: context.tr('Name'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: hexController,
                decoration: const InputDecoration(
                  labelText: 'HEX',
                  hintText: '#RRGGBB',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.tr('Cancel')),
            ),
            FilledButton(
              onPressed: () {
                final normalized = _normalizeHexInput(hexController.text);
                if (normalized == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr('Invalid HEX format, please input #RRGGBB'),
                      ),

                    ),

                  );
                  return;
                }
                onUpdate(
                  index,
                  ColorEntry(
                    name: nameController.text.trim().isEmpty
                        ? 'Color ${index + 1}'
                        : nameController.text.trim(),
                    hexCode: normalized,
                  ),
                );
                Navigator.of(dialogContext).pop();
              },
              child: Text(context.tr('Save')),
            ),
          ],
        );
      },
    );
  }
}

class PreviewCanvasPanel extends StatelessWidget {
  const PreviewCanvasPanel({
    super.key,
    required this.file,
    required this.isBusy,
    required this.onImportPressed,
    required this.onImportCameraPressed,
    required this.onProfileChanged,
    required this.onAddColor,
  });

  final ManagedPaletteFile? file;
  final bool isBusy;
  final Future<void> Function() onImportPressed;
  final Future<void> Function() onImportCameraPressed;
  final ValueChanged<ExtractionProfile> onProfileChanged;
  final ValueChanged<ColorEntry> onAddColor;

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return _PanelFrame(
        title: 'File Preview',
        subtitle: '',
        child: _EmptyState(
          title: 'No file selected',
          description: 'Import or select a file first',
          action: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: isBusy ? null : () => onImportPressed(),
                icon: const Icon(Icons.file_open),
                label: Text(context.tr('Import File')),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : () => onImportCameraPressed(),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(context.tr('Camera Sampling')),
              ),
            ],
          ),
        ),
      );
    }

    return _PanelFrame(
      title: 'File Preview',
      subtitle: '',
      headerAction: file != null
          ? IconButton(
              icon: const Icon(Icons.fullscreen),
              tooltip: context.tr('Fullscreen Analytics'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => _FullscreenPreviewDialog(
                      file: file!,
                      onExtractFromBox: (rect) {
                        onProfileChanged(
                          ExtractionProfile(
                            mode: ExtractionMode.boxRange,
                            sampleCount: file!.extractionProfile.sampleCount,
                            boxLeft: rect.left,
                            boxTop: rect.top,
                            boxWidth: rect.width,
                            boxHeight: rect.height,
                          ),

                        );
                      },
                      onExtractPixel: (color) {
                        final hex = '#${color.value.toRadixString(16).padLeft(8, "0").substring(2).toUpperCase()}';
                        onAddColor(ColorEntry(name: 'Picked', hexCode: hex));
                        Navigator.of(context).pop();
                      },
                    ),

                  ),
                );
              },
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  file!.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.tr(
                  '{count} colors · {format}',
                  params: <String, String>{
                    'count': file!.palette.colors.length.toString(),
                    'format': file!.palette.sourceFormat.toUpperCase(),
                  },
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: file!.previewBytes == null
                ? const _EmptyState(
                    title: 'No preview image',
                    description: 'Current file does not support image preview',
                  )
                : _PreviewBox(
                    imageBytes: file!.previewBytes!,
                    profile: file!.extractionProfile,
                    onProfileChanged: onProfileChanged,
                    fullHeight: true,
                  ),
          ),
        ],
      ),
    );
  }
}

class PreviewInspectorPanel extends StatelessWidget {
  const PreviewInspectorPanel({
    super.key,
    required this.file,
    required this.isBusy,
    required this.onToggleCartColor,
    required this.isColorInCart,
    required this.onProfileChanged,
    required this.onReextractPressed,
    required this.onSaveProfilePressed,
    required this.onApplySavedProfilePressed,
    required this.chartMode,
    required this.onChartModeChanged,
    required this.previewVisionMode,
    required this.onPreviewVisionModeChanged,
    required this.previewSeriesCount,
    required this.onPreviewSeriesCountChanged,
    required this.previewGroupCount,
    required this.onPreviewGroupCountChanged,
    required this.previewLineWidth,
    required this.onPreviewLineWidthChanged,
    required this.previewMarkerSize,
    required this.onPreviewMarkerSizeChanged,
    required this.previewAlphaPercent,
    required this.onPreviewAlphaPercentChanged,
    required this.previewMarkerShape,
    required this.onPreviewMarkerShapeChanged,
    required this.onAddAllSamplingPressed,
    required this.configExpanded,
    required this.resultExpanded,
    required this.effectExpanded,
    required this.onConfigExpandedChanged,
    required this.onResultExpandedChanged,
    required this.onEffectExpandedChanged,
  });

  final ManagedPaletteFile? file;
  final bool isBusy;
  final ValueChanged<ColorEntry> onToggleCartColor;
  final bool Function(ColorEntry color) isColorInCart;
  final ValueChanged<ExtractionProfile> onProfileChanged;
  final Future<void> Function() onReextractPressed;
  final VoidCallback onSaveProfilePressed;
  final Future<void> Function() onApplySavedProfilePressed;
  final PaletteChartMode chartMode;
  final ValueChanged<PaletteChartMode> onChartModeChanged;
  final PalettePreviewVisionMode previewVisionMode;
  final ValueChanged<PalettePreviewVisionMode> onPreviewVisionModeChanged;
  final int previewSeriesCount;
  final ValueChanged<double> onPreviewSeriesCountChanged;
  final int previewGroupCount;
  final ValueChanged<double> onPreviewGroupCountChanged;
  final int previewLineWidth;
  final ValueChanged<double> onPreviewLineWidthChanged;
  final int previewMarkerSize;
  final ValueChanged<double> onPreviewMarkerSizeChanged;
  final int previewAlphaPercent;
  final ValueChanged<double> onPreviewAlphaPercentChanged;
  final PaletteMarkerShape previewMarkerShape;
  final ValueChanged<PaletteMarkerShape> onPreviewMarkerShapeChanged;
  final VoidCallback onAddAllSamplingPressed;
  final bool configExpanded;
  final bool resultExpanded;
  final bool effectExpanded;
  final ValueChanged<bool> onConfigExpandedChanged;
  final ValueChanged<bool> onResultExpandedChanged;
  final ValueChanged<bool> onEffectExpandedChanged;

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return _PanelFrame(
        title: 'Preview Controls',
        subtitle: '',
        child: const _EmptyState(
          title: 'No file selected',
          description: 'Configure sampling and preview after selecting a file',
        ),
      );
    }

    final usesMarkerShape = _chartModeUsesMarkerShape(chartMode);

    return _PanelFrame(
      title: 'Preview Controls',
      subtitle: '',
      child: ListView(
        children: [
          _FoldCard(
            title: 'Sampling Settings',
            expanded: configExpanded,
            onExpandedChanged: onConfigExpandedChanged,
            child: _ExtractionControls(
              wrapped: false,
              profile: file!.extractionProfile,
              sourceKind: file!.sourceKind.name,
              hasSavedProfile: file!.savedProfile != null,
              isBusy: isBusy,
              onProfileChanged: onProfileChanged,
              onReextractPressed: onReextractPressed,
              onSaveProfilePressed: onSaveProfilePressed,
              onApplySavedProfilePressed: onApplySavedProfilePressed,
            ),
          ),
          const SizedBox(height: 8),
          _FoldCard(
            title: 'Sampling Analysis Results',
            expanded: resultExpanded,
            onExpandedChanged: onResultExpandedChanged,
            headerAction: FilledButton.tonalIcon(
              onPressed: onAddAllSamplingPressed,
              icon: const Icon(Icons.playlist_add, size: 16),
              label: Text(context.tr('Add All Colors')),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
            child: file!.palette.colors.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: _EmptyState(
                      title: context.tr('No samples yet'),
                      description:
                          context.tr('Pick colors or run extraction first'),
                    ),
                  )
                : Column(
                    children: [
                      for (final color in file!.palette.colors)
                        _SamplingColorItem(
                          color: color,
                          isSelected: isColorInCart(color),
                          onTap: () => onToggleCartColor(color),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          _FoldCard(
            title: 'Preview Effects',
            expanded: effectExpanded,
            onExpandedChanged: onEffectExpandedChanged,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<PaletteChartMode>(
                        initialValue: chartMode,
                        decoration: InputDecoration(
                          labelText: context.tr('Chart Style'),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),

                        items: PaletteChartMode.values
                            .map(
                              (mode) => DropdownMenuItem<PaletteChartMode>(
                                value: mode,
                                child: Text(context.tr(_chartModeLabel(mode))),
                              ),

                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            onChartModeChanged(value);
                          }
                        },
                      ),

                    ),

                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<PalettePreviewVisionMode>(
                        initialValue: previewVisionMode,
                        decoration: InputDecoration(
                          labelText: context.tr('Vision Mode'),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),

                        items: PalettePreviewVisionMode.values
                            .map(
                              (mode) =>
                                  DropdownMenuItem<PalettePreviewVisionMode>(
                                value: mode,
                                child: Text(context.tr(_visionModeLabel(mode))),
                              ),

                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            onPreviewVisionModeChanged(value);
                          }
                        },
                      ),

                    ),

                  ],
                ),
                if (usesMarkerShape) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<PaletteMarkerShape>(
                    initialValue: previewMarkerShape,
                    decoration: InputDecoration(
                      labelText: context.tr('Marker Shape'),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),

                    items: PaletteMarkerShape.values
                        .map(
                          (shape) => DropdownMenuItem<PaletteMarkerShape>(
                            value: shape,
                            child:
                                Text(context.tr(_markerShapeLabel(shape))),
                          ),

                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        onPreviewMarkerShapeChanged(value);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 8),
                _LabeledSlider(
                  label: 'Series: $previewSeriesCount',
                  value: previewSeriesCount.toDouble(),
                  min: 1,
                  max: 24,
                  divisions: 23,
                  onChanged: onPreviewSeriesCountChanged,
                ),
                _LabeledSlider(
                  label: 'Group: $previewGroupCount',
                  value: previewGroupCount.toDouble(),
                  min: 2,
                  max: 48,
                  divisions: 46,
                  onChanged: onPreviewGroupCountChanged,
                ),
                _LabeledSlider(
                  label: 'Line Width: $previewLineWidth',
                  value: previewLineWidth.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  onChanged: onPreviewLineWidthChanged,
                ),
                _LabeledSlider(
                  label: 'Point Size: $previewMarkerSize',
                  value: previewMarkerSize.toDouble(),
                  min: 2,
                  max: 18,
                  divisions: 16,
                  onChanged: onPreviewMarkerSizeChanged,
                ),
                _LabeledSlider(
                  label: 'Alpha: $previewAlphaPercent%',
                  value: previewAlphaPercent.toDouble(),
                  min: 10,
                  max: 100,
                  divisions: 18,
                  onChanged: onPreviewAlphaPercentChanged,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 220,
                  child: _PaletteChartPreview(
                    colors: file!.palette.colors,
                    mode: chartMode,
                    visionMode: previewVisionMode,
                    seriesCount: previewSeriesCount,
                    groupCount: previewGroupCount,
                    lineWidth: previewLineWidth,
                    markerSize: previewMarkerSize,
                    markerShape: previewMarkerShape,
                    alphaPercent: previewAlphaPercent,
                    isSelected: isColorInCart,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoldCard extends StatelessWidget {
  const _FoldCard({
    required this.title,
    required this.expanded,
    required this.onExpandedChanged,
    required this.child,
    this.headerAction,
  });

  final String title;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final Widget child;
  final Widget? headerAction;

  static const Duration _kAnimationDuration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => onExpandedChanged(!expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            context.tr(title),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),

                        ),

                        if (headerAction != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                clipBehavior: Clip.hardEdge,
                                child: headerAction!,
                              ),

                            ),

                          ),

                        ],
                      ],
                    ),

                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    duration: _kAnimationDuration,
                    curve: Curves.easeOutCubic,
                    turns: expanded ? 0.5 : 0,
                    child: const Icon(
                      Icons.expand_more,
                      size: 20,
                    ),

                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedAlign(
              duration: _kAnimationDuration,
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              heightFactor: expanded ? 1 : 0,
              child: IgnorePointer(
                ignoring: !expanded,
                child: AnimatedOpacity(
                  duration: _kAnimationDuration,
                  curve: Curves.easeInOutCubic,
                  opacity: expanded ? 1 : 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PreviewSourcePanel extends StatelessWidget {
  const PreviewSourcePanel({
    super.key,
    required this.files,
    required this.selectedFile,
    required this.statusMessage,
    required this.onFileSelected,
  });

  final List<ManagedPaletteFile> files;
  final ManagedPaletteFile? selectedFile;
  final String? statusMessage;
  final ValueChanged<ManagedPaletteFile> onFileSelected;

  @override
  Widget build(BuildContext context) {
    return _PanelFrame(
      title: 'Managed Files',
      subtitle: '',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (statusMessage != null && statusMessage!.isNotEmpty) ...[
            _StatusText(message: statusMessage!),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: files.isEmpty
                ? const _EmptyState(
                    title: 'No files available for preview',
                    description:
                        'Import files in Management first, then select here.',
                  )
                : ListView.separated(
                    itemCount: files.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final selected = selectedFile?.id == file.id;
                      final firstHex = file.palette.previewColors.isEmpty
                          ? '#CCCCCC'
                          : file.palette.previewColors.first.hexCode;
                      return Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          selected: selected,
                          leading: _ColorDot(hexCode: firstHex),
                          title: Text(
                            file.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          subtitle: Text(
                            context.tr(
                              '{count} colors · {format}',
                              params: <String, String>{
                                'count': file.palette.colors.length.toString(),
                                'format':
                                    file.palette.sourceFormat.toUpperCase(),
                              },
                            ),

                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          onTap: () => onFileSelected(file),
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

class PreviewCartSummaryPanel extends StatelessWidget {
  const PreviewCartSummaryPanel({
    super.key,
    required this.cartColors,
    required this.statusMessage,
    required this.editMode,
    required this.selectedIndices,
    required this.onEditModeChanged,
    required this.onDeleteSelectedPressed,
    required this.onSelectAllPressed,
    required this.onInvertSelectionPressed,
    required this.onToggleSelection,
    required this.onReorder,
  });

  final List<ColorEntry> cartColors;
  final String? statusMessage;
  final bool editMode;
  final Set<int> selectedIndices;
  final ValueChanged<bool> onEditModeChanged;
  final VoidCallback onDeleteSelectedPressed;
  final VoidCallback onSelectAllPressed;
  final VoidCallback onInvertSelectionPressed;
  final ValueChanged<int> onToggleSelection;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return _PanelFrame(
      title: 'Export Cart Colors',
      subtitle: '',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: editMode ? 42 : 164,
                height: 40,
                child: editMode
                    ? OutlinedButton(
                        onPressed: () => onEditModeChanged(false),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: const CircleBorder(),
                        ),

                        child: const Icon(Icons.close_rounded, size: 18),
                      )
                    : OutlinedButton.icon(
                        onPressed: cartColors.isEmpty
                            ? null
                            : () => onEditModeChanged(true),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(
                          context.tr('Edit Export Cart'),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                        ),

                      ),

              ),
              if (editMode)
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 134),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(134, 40),
                    ),

                    onPressed: selectedIndices.isEmpty
                        ? null
                        : onDeleteSelectedPressed,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(
                      context.tr('Delete Selected'),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),

                  ),
                ),
              if (editMode)
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 98),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(98, 40),
                    ),

                    onPressed: cartColors.isEmpty ? null : onSelectAllPressed,
                    child: Text(
                      context.tr('Select All'),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),

                  ),
                ),
              if (editMode)
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 98),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(98, 40),
                    ),

                    onPressed:
                        cartColors.isEmpty ? null : onInvertSelectionPressed,
                    child: Text(
                      context.tr('Invert Selection'),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),

                  ),
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
                    title: 'Export cart is empty',
                    description:
                        'Tap colors in the middle preview to add to export cart.',
                  )
                : ReorderableListView.builder(
                    itemCount: cartColors.length,
                    onReorder: onReorder,
                    buildDefaultDragHandles: false,
                    itemBuilder: (context, index) {
                      final color = cartColors[index];
                      final selected = selectedIndices.contains(index);
                      final bgHex = _parseHexColor(color.hexCode);
                      final isDark = bgHex.computeLuminance() < 0.4;
                      final txColor = isDark ? Colors.white : Colors.black;
                      final computedBorderColor = selected
                          ? (isDark ? Colors.white : Colors.black)
                          : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.1);

                      return Card(
                        key: ValueKey<String>(
                            'preview-cart-${color.hexCode}-$index'),
                        margin: const EdgeInsets.only(bottom: 4),
                        clipBehavior: Clip.antiAlias,
                        color: bgHex,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: computedBorderColor,
                            width: selected ? 2 : 1,
                          ),

                        ),

                        child: ListTile(
                          dense: true,
                          onTap:
                              editMode ? () => onToggleSelection(index) : null,
                          title: Text(color.name, style: TextStyle(color: txColor, fontWeight: FontWeight.w600)),
                          subtitle: Text(color.hexCode, style: TextStyle(color: txColor.withValues(alpha: 0.8))),
                          trailing: ReorderableDragStartListener(
                            index: index,
                            child: Icon(
                              Icons.drag_indicator,
                              color: txColor.withValues(alpha: 0.6),
                            ),

                          ),

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

class ExportOptionsPanel extends StatelessWidget {
  const ExportOptionsPanel({
    super.key,
    required this.isBusy,
    required this.statusMessage,
    required this.supportedExtensions,
    required this.selectedExtension,
    required this.exportFileName,
    required this.sortByLightness,
    required this.exportAsHeatmapGradient,
    required this.heatmapSteps,
    required this.generationKind,
    required this.baseHex,
    required this.secondaryHex,
    required this.generationSteps,
    required this.whiteTemperature,
    required this.generatedPreviewColors,
    required this.cartIsEmpty,
    required this.colorCandidates,
    required this.isBaseColorPicking,
    required this.isSecondaryColorPicking,
    required this.formatExpanded,
    required this.generatorExpanded,
    required this.strategyExpanded,
    required this.onBaseColorFieldPressed,
    required this.onSecondaryColorFieldPressed,
    required this.onFormatExpandedChanged,
    required this.onGeneratorExpandedChanged,
    required this.onStrategyExpandedChanged,
    required this.onSelectedExtensionChanged,
    required this.onExportFileNameChanged,
    required this.onExportPressed,
    required this.onSortByLightnessChanged,
    required this.onExportAsHeatmapGradientChanged,
    required this.onHeatmapStepsChanged,
    required this.onGenerationKindChanged,
    required this.onBaseHexChanged,
    required this.onSecondaryHexChanged,
    required this.onGenerationStepsChanged,
    required this.onWhiteTemperatureChanged,
    required this.onGeneratePreviewPressed,
    required this.onGenerateReplacePressed,
    required this.onGenerateAppendPressed,
  });

  final bool isBusy;
  final String? statusMessage;
  final List<String> supportedExtensions;
  final String selectedExtension;
  final String exportFileName;
  final bool sortByLightness;
  final bool exportAsHeatmapGradient;
  final int heatmapSteps;
  final PaletteGenerationKind generationKind;
  final String baseHex;
  final String secondaryHex;
  final int generationSteps;
  final WhiteTemperature whiteTemperature;
  final List<ColorEntry> generatedPreviewColors;
  final bool cartIsEmpty;
  final List<ColorEntry> colorCandidates;
  final bool isBaseColorPicking;
  final bool isSecondaryColorPicking;
  final bool formatExpanded;
  final bool generatorExpanded;
  final bool strategyExpanded;
  final VoidCallback onBaseColorFieldPressed;
  final VoidCallback onSecondaryColorFieldPressed;
  final ValueChanged<bool> onFormatExpandedChanged;
  final ValueChanged<bool> onGeneratorExpandedChanged;
  final ValueChanged<bool> onStrategyExpandedChanged;
  final ValueChanged<String?> onSelectedExtensionChanged;
  final ValueChanged<String> onExportFileNameChanged;
  final Future<void> Function() onExportPressed;
  final ValueChanged<bool> onSortByLightnessChanged;
  final ValueChanged<bool> onExportAsHeatmapGradientChanged;
  final ValueChanged<double> onHeatmapStepsChanged;
  final ValueChanged<PaletteGenerationKind> onGenerationKindChanged;
  final ValueChanged<String> onBaseHexChanged;
  final ValueChanged<String> onSecondaryHexChanged;
  final ValueChanged<double> onGenerationStepsChanged;
  final ValueChanged<WhiteTemperature> onWhiteTemperatureChanged;
  final VoidCallback onGeneratePreviewPressed;
  final VoidCallback onGenerateReplacePressed;
  final VoidCallback onGenerateAppendPressed;

  @override
  Widget build(BuildContext context) {
    final uniqueCandidates = <String, ColorEntry>{
      for (final color in colorCandidates) color.hexCode.toUpperCase(): color,
    }.values.toList(growable: false);

    return _PanelFrame(
      title: 'Export Options',
      subtitle: '',
      child: ListView(
        children: [
          _FoldCard(
            title: 'Export File Settings',
            expanded: formatExpanded,
            onExpandedChanged: onFormatExpandedChanged,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  initialValue: exportFileName,
                  onChanged: onExportFileNameChanged,
                  decoration: InputDecoration(
                    labelText: context.tr('Export File Name'),
                    hintText: context.tr('Example: My Palette'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedExtension,
                  decoration: InputDecoration(
                    labelText: context.tr('Export Format'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: supportedExtensions
                      .map(
                        (extension) => DropdownMenuItem<String>(
                          value: extension,
                          child: Text(
                            extension.toUpperCase().replaceFirst('.', ''),
                          ),

                        ),

                      )
                      .toList(growable: false),
                  onChanged: isBusy ? null : onSelectedExtensionChanged,
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: cartIsEmpty || isBusy ? null : onExportPressed,
                  icon: const Icon(Icons.download_rounded),
                  label: Text(context.tr('Export File')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _FoldCard(
            title: 'Heatmap Palette Generator',
            expanded: generatorExpanded,
            onExpandedChanged: onGeneratorExpandedChanged,
            child: Column(
              children: [
                DropdownButtonFormField<PaletteGenerationKind>(
                  initialValue: generationKind,
                  decoration: InputDecoration(
                    labelText: context.tr('Generation Mode'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: PaletteGenerationKind.values
                      .map(
                        (kind) => DropdownMenuItem<PaletteGenerationKind>(
                          value: kind,
                          child: Text(context.tr(_generationLabel(kind))),
                        ),

                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      onGenerationKindChanged(value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                if (uniqueCandidates.isEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child:
                        Text(context.tr('Add colors to the export list first')),
                  ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return SizeTransition(
                      axis: Axis.horizontal,
                      sizeFactor: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),

                    );
                  },
                  child:
                      generationKind == PaletteGenerationKind.twoColorGradient
                          ? Row(
                              key: const ValueKey<String>('dual-color-fields'),
                              children: [
                                Expanded(
                                  child: _PickHexField(
                                    label: context.tr('Base (HEX)'),
                                    hexCode: baseHex,
                                    active: isBaseColorPicking,
                                    enabled: uniqueCandidates.isNotEmpty,
                                    onTap: onBaseColorFieldPressed,
                                  ),

                                ),

                                const SizedBox(width: 8),
                                Expanded(
                                  child: _PickHexField(
                                    label: context.tr('Secondary (HEX)'),
                                    hexCode: secondaryHex,
                                    active: isSecondaryColorPicking,
                                    enabled: uniqueCandidates.isNotEmpty,
                                    onTap: onSecondaryColorFieldPressed,
                                  ),

                                ),

                              ],
                            )
                          : Row(
                              key: const ValueKey<String>('single-base-field'),
                              children: [
                                Expanded(
                                  child: _PickHexField(
                                    label: context.tr('Base (HEX)'),
                                    hexCode: baseHex,
                                    active: isBaseColorPicking,
                                    enabled: uniqueCandidates.isNotEmpty,
                                    onTap: onBaseColorFieldPressed,
                                  ),

                                ),

                              ],
                            ),

                ),
                if (isBaseColorPicking || isSecondaryColorPicking) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isBaseColorPicking
                          ? context.tr(
                              'Base color pick mode: tap a color in the right export list to apply',
                            )
                          : context.tr(
                              'Secondary color pick mode: tap a color in the right export list to apply',
                            ),

                    ),

                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      context.tr(
                        'Count: {count}',
                        params: <String, String>{
                          'count': generationSteps.toString(),
                        },
                      ),

                    ),

                    Expanded(
                      child: Slider(
                        min: 2,
                        max: 20,
                        divisions: 18,
                        value: generationSteps.toDouble(),
                        label: '$generationSteps',
                        onChanged: onGenerationStepsChanged,
                      ),

                    ),

                  ],
                ),
                if (generationKind == PaletteGenerationKind.toWhite) ...[
                  const SizedBox(height: 4),
                  DropdownButtonFormField<WhiteTemperature>(
                    initialValue: whiteTemperature,
                    decoration: InputDecoration(
                      labelText: context.tr('White Temperature'),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),

                    items: WhiteTemperature.values
                        .map(
                          (value) => DropdownMenuItem<WhiteTemperature>(
                            value: value,
                            child:
                                Text(context.tr(_whiteTemperatureLabel(value))),
                          ),

                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        onWhiteTemperatureChanged(value);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: isBusy ? null : onGeneratePreviewPressed,
                  icon: const Icon(Icons.auto_fix_high),
                  label: Text(context.tr('Generate Preview')),
                ),
                if (generatedPreviewColors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _GeneratedPaletteBand(colors: generatedPreviewColors),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: isBusy || generatedPreviewColors.isEmpty
                            ? null
                            : onGenerateReplacePressed,
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: Text(context.tr('Replace Export Cart')),
                      ),

                    ),

                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: isBusy || generatedPreviewColors.isEmpty
                            ? null
                            : onGenerateAppendPressed,
                        icon: const Icon(Icons.add),
                        label: Text(context.tr('Append To Export Cart')),
                      ),

                    ),

                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _FoldCard(
            title: 'Export Strategy',
            expanded: strategyExpanded,
            onExpandedChanged: onStrategyExpandedChanged,
            child: Column(
              children: [
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: sortByLightness,
                  onChanged: onSortByLightnessChanged,
                  title: Text(context.tr('Sort by lightness before export')),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: exportAsHeatmapGradient,
                  onChanged: onExportAsHeatmapGradientChanged,
                  title: Text(context.tr('Export as heatmap gradient')),
                ),
                if (exportAsHeatmapGradient)
                  Row(
                    children: [
                      Text(
                        context.tr(
                          'Heatmap Steps: {count}',
                          params: <String, String>{
                            'count': heatmapSteps.toString(),
                          },
                        ),

                      ),

                      Expanded(
                        child: Slider(
                          min: 2,
                          max: 512,
                          divisions: 510,
                          value: heatmapSteps.toDouble(),
                          label: '$heatmapSteps',
                          onChanged: onHeatmapStepsChanged,
                        ),

                      ),

                    ],
                  ),
              ],
            ),
          ),
          if (statusMessage != null && statusMessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _StatusText(message: statusMessage!),
          ],
        ],
      ),
    );
  }
}

class _PickHexField extends StatelessWidget {
  const _PickHexField({
    required this.label,
    required this.hexCode,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String hexCode;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalized = _normalizeHexInput(hexCode) ?? '#1D4ED8';
    final borderColor = active ? colorScheme.primary : colorScheme.outline;

    final field = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: active ? 2 : 1,
            ),
            color: active
                ? colorScheme.primaryContainer.withValues(alpha: 0.45)
                : colorScheme.surface,
          ),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _parseHexColor(normalized),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.2),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),

                    Text(
                      normalized,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                  ],
                ),
              ),
              Icon(
                active ? Icons.radio_button_checked : Icons.touch_app_outlined,
                size: 18,
                color:
                    active ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );

    if (enabled) {
      return field;
    }

    return Opacity(
      opacity: 0.55,
      child: field,
    );
  }
}

class _GeneratedPaletteBand extends StatelessWidget {
  const _GeneratedPaletteBand({required this.colors});

  final List<ColorEntry> colors;

  @override
  Widget build(BuildContext context) {
    if (colors.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final bandColors = colors
        .map<Color>((entry) => _parseHexColor(entry.hexCode))
        .toList(growable: false);
    final gradientColors = bandColors.length == 1
        ? <Color>[bandColors.first, bandColors.first]
        : bandColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('Generated Palette Preview'),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 6),
        Container(
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant),
            gradient: LinearGradient(colors: gradientColors),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              colors.first.hexCode,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            Text(
              colors.last.hexCode,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class ExportColorListPanel extends StatelessWidget {
  const ExportColorListPanel({
    super.key,
    required this.cartColors,
    required this.onUpdateColor,
    required this.statusMessage,
    required this.isBusy,
    required this.selectedIndex,
    required this.isBaseColorPicking,
    required this.isSecondaryColorPicking,
    required this.editMode,
    required this.selectedIndices,
    required this.listExpanded,
    required this.previewExpanded,
    required this.previewFileName,
    required this.previewContent,
    required this.previewExtension,
    required this.previewError,
    required this.onListExpandedChanged,
    required this.onPreviewExpandedChanged,
    required this.onSelectedIndexChanged,
    required this.onAddManualColorPressed,
    required this.onEditModeToggle,
    required this.onDeleteSelectedPressed,
    required this.onSelectAllPressed,
    required this.onInvertSelectionPressed,
    required this.onToggleSelection,
    required this.onReorder,
  });

  final List<ColorEntry> cartColors;
  final void Function(int index, ColorEntry color) onUpdateColor;
  final String? statusMessage;
  final bool isBusy;
  final int? selectedIndex;
  final bool isBaseColorPicking;
  final bool isSecondaryColorPicking;
  final bool editMode;
  final Set<int> selectedIndices;
  final bool listExpanded;
  final bool previewExpanded;
  final String previewFileName;
  final String previewContent;
  final String previewExtension;
  final String? previewError;
  final ValueChanged<bool> onListExpandedChanged;
  final ValueChanged<bool> onPreviewExpandedChanged;
  final ValueChanged<int> onSelectedIndexChanged;
  final Future<void> Function() onAddManualColorPressed;
  final VoidCallback onEditModeToggle;
  final VoidCallback onDeleteSelectedPressed;
  final VoidCallback onSelectAllPressed;
  final VoidCallback onInvertSelectionPressed;
  final ValueChanged<int> onToggleSelection;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    final listPanelHeight = cartColors.length > 10 ? 360.0 : 280.0;
    return _PanelFrame(
      title: 'Export Content & Preview',
      subtitle: '',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: editMode ? 42 : 164,
                height: 40,
                child: editMode
                    ? OutlinedButton(
                        onPressed: onEditModeToggle,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: const CircleBorder(),
                        ),

                        child: const Icon(Icons.close_rounded, size: 18),
                      )
                    : OutlinedButton.icon(
                        onPressed: cartColors.isEmpty ? null : onEditModeToggle,
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(
                          context.tr('Edit Export Cart'),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                        ),

                      ),

              ),
              if (editMode)
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 134),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(134, 40),
                    ),

                    onPressed: selectedIndices.isEmpty
                        ? null
                        : onDeleteSelectedPressed,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(
                      context.tr('Delete Selected'),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),

                  ),
                ),
              if (editMode)
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 98),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(98, 40),
                    ),

                    onPressed: cartColors.isEmpty ? null : onSelectAllPressed,
                    child: Text(
                      context.tr('Select All'),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),

                  ),
                ),
              if (editMode)
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 98),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(98, 40),
                    ),

                    onPressed:
                        cartColors.isEmpty ? null : onInvertSelectionPressed,
                    child: Text(
                      context.tr('Invert Selection'),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),

                  ),
                ),
              FilledButton.tonalIcon(
                onPressed: isBusy ? null : () => onAddManualColorPressed(),
                icon: const Icon(Icons.add_circle_outline),
                label: Text(context.tr('Add Color Manually')),
              ),
              if (isBusy)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (statusMessage != null && statusMessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _StatusText(message: statusMessage!),
          ],
          if (isBaseColorPicking || isSecondaryColorPicking) ...[
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Text(
                  isBaseColorPicking
                      ? context.tr(
                          'Base color picking: tap any color below to set as base',
                        )
                      : context.tr(
                          'Secondary color picking: tap any color below to set as secondary',
                        ),

                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                _FoldCard(
                  title: 'Export Color List',
                  expanded: listExpanded,
                  onExpandedChanged: onListExpandedChanged,
                  child: SizedBox(
                    height: listPanelHeight,
                    child: cartColors.isEmpty
                        ? const _EmptyState(
                            title: 'Export cart is empty',
                            description:
                                'Pick colors from preview, or generate from the left panel.',
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: ReorderableListView.builder(
                                  itemCount: cartColors.length,
                                  onReorder: onReorder,
                                  buildDefaultDragHandles: false,
                                  itemBuilder: (context, index) {
                                    final color = cartColors[index];
                                    final editSelected =
                                        selectedIndices.contains(index);
                                    final normalSelected =
                                        selectedIndex == index;
                                    final selected = editMode
                                        ? editSelected
                                        : normalSelected;
                                    final borderColor = selected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .outlineVariant;

                                    return Card(
                                      key: ValueKey<String>(
                                          'export-list-${color.hexCode}-$index'),
                                      margin: EdgeInsets.zero,
                                      clipBehavior: Clip.antiAlias,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                          color: borderColor,
                                          width: selected ? 2 : 1,
                                        ),

                                      ),

                                      child: ListTile(
                                        selected: selected,
                                        leading:
                                            _ColorDot(hexCode: color.hexCode),
                                        title: Text(color.name),
                                        subtitle: Text(color.hexCode),
                                        onTap: () {
                                          if (isBaseColorPicking ||
                                              isSecondaryColorPicking) {
                                            onSelectedIndexChanged(index);
                                            return;
                                          }
                                          if (editMode) {
                                            onToggleSelection(index);
                                            return;
                                          }
                                          onSelectedIndexChanged(index);
                                        },
                                        onLongPress: editMode
                                            ? null
                                            : () => _showColorEditDialog(
                                                  context,
                                                  index,
                                                  color,
                                                  onUpdateColor,
                                                ),

                                        trailing: ReorderableDragStartListener(
                                          index: index,
                                          child: Icon(
                                            Icons.drag_indicator,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),

                                        ),

                                      ),

                                    );
                                  },
                                ),

                              ),

                              const SizedBox(height: 8),
                              SizedBox(
                                height: 20,
                                child: Row(
                                  children: cartColors
                                      .map(
                                        (color) => Expanded(
                                          child: Container(
                                            color:
                                                _parseHexColor(color.hexCode),
                                          ),

                                        ),

                                      )
                                      .toList(growable: false),
                                ),

                              ),

                            ],
                          ),

                  ),
                ),
                const SizedBox(height: 8),
                _FoldCard(
                  title: 'Export File Content Preview',
                  expanded: previewExpanded,
                  onExpandedChanged: onPreviewExpandedChanged,
                  child: SizedBox(
                    height: 320,
                    child: _ExportFilePreview(
                      fileName: previewFileName,
                      extension: previewExtension,
                      content: previewContent,
                      errorMessage: previewError,
                    ),

                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportFilePreview extends StatelessWidget {
  const _ExportFilePreview({
    required this.fileName,
    required this.extension,
    required this.content,
    this.errorMessage,
  });

  static final RegExp _tokenPattern = RegExp(
    r'#(?:[0-9A-Fa-f]{6})\b|"(?:[^"\\]|\\.)*"|\b(?:true|false|null)\b|-?\d+(?:\.\d+)?|[{}\[\]:,]|[A-Za-z_][A-Za-z0-9_\.]*',
  );
  static final RegExp _hexPattern = RegExp(r'^#(?:[0-9A-Fa-f]{6})$');
  static final RegExp _quotedHexPattern = RegExp(r'^"#(?:[0-9A-Fa-f]{6})"$');
  static final RegExp _numberPattern = RegExp(r'^-?\d+(?:\.\d+)?$');
  static final RegExp _keywordPattern = RegExp(r'^(?:true|false|null)$');
  static final RegExp _punctuationPattern = RegExp(r'^[{}\[\]:,]$');

  final String fileName;
  final String extension;
  final String content;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final appScheme = Theme.of(context).colorScheme;
    final darkScheme = ColorScheme.fromSeed(
      seedColor: appScheme.primary,
      brightness: Brightness.dark,
    );

    if (errorMessage != null && errorMessage!.trim().isNotEmpty) {
      return _buildPreviewContainer(
        darkScheme: darkScheme,
        child: Center(
          child: Text(
            errorMessage!,
            style: TextStyle(color: darkScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final normalizedContent = content.trim();
    if (normalizedContent.isEmpty) {
      return _buildPreviewContainer(
        darkScheme: darkScheme,
        child: Center(
          child: Text(
            context.tr(
                'Export cart is empty, or current format cannot be previewed.'),
            style: TextStyle(color: darkScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final lines = normalizedContent.split('\n');
    final visibleLines = lines.length > 240 ? lines.sublist(0, 240) : lines;
    final clipped = lines.length > visibleLines.length;

    final codeSpans = <InlineSpan>[];
    final baseStyle = TextStyle(
      color: darkScheme.onSurface,
      fontFamily: 'monospace',
      fontSize: 12,
      height: 1.45,
    );

    for (var index = 0; index < visibleLines.length; index++) {
      final line = visibleLines[index];
      codeSpans.add(
        TextSpan(
          text: '${(index + 1).toString().padLeft(3, ' ')}  ',
          style: baseStyle.copyWith(color: darkScheme.outline),
        ),
      );
      codeSpans.addAll(_highlightLine(line, baseStyle, darkScheme));
      if (index != visibleLines.length - 1) {
        codeSpans.add(const TextSpan(text: '\n'));
      }
    }

    if (clipped) {
      codeSpans
        ..add(const TextSpan(text: '\n'))
        ..add(
          TextSpan(
            text: '... preview truncated ...',
            style: baseStyle.copyWith(color: darkScheme.outline),
          ),
        );
    }

    return _buildPreviewContainer(
      darkScheme: darkScheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: darkScheme.surfaceContainer,
              border: Border(
                bottom: BorderSide(color: darkScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.description_outlined, color: darkScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: darkScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),

                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: darkScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    extension.toUpperCase().replaceFirst('.', ''),
                    style: TextStyle(
                      color: darkScheme.onPrimaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),

                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: SelectableText.rich(
                TextSpan(style: baseStyle, children: codeSpans),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContainer({
    required ColorScheme darkScheme,
    required Widget child,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: darkScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: darkScheme.outlineVariant),
      ),
      child: child,
    );
  }

  List<InlineSpan> _highlightLine(
    String line,
    TextStyle baseStyle,
    ColorScheme darkScheme,
  ) {
    final spans = <InlineSpan>[];
    final commentLine = line.trimLeft().startsWith('#');
    var cursor = 0;

    for (final match in _tokenPattern.allMatches(line)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: line.substring(cursor, match.start),
            style: commentLine
                ? baseStyle.copyWith(color: darkScheme.outline)
                : baseStyle,
          ),
        );
      }

      final token = match.group(0)!;
      final isKey = _isLikelyObjectKeyToken(token, line, match.end);
      spans.add(
        TextSpan(
          text: token,
          style: _styleForToken(
            token,
            baseStyle,
            darkScheme,
            commentLine: commentLine,
            isKey: isKey,
          ),
        ),
      );
      cursor = match.end;
    }

    if (cursor < line.length) {
      spans.add(
        TextSpan(
          text: line.substring(cursor),
          style: commentLine
              ? baseStyle.copyWith(color: darkScheme.outline)
              : baseStyle,
        ),
      );
    }

    return spans;
  }

  bool _isLikelyObjectKeyToken(String token, String line, int tokenEnd) {
    if (!token.startsWith('"') || !token.endsWith('"')) {
      return false;
    }

    var cursor = tokenEnd;
    while (
        cursor < line.length && (line[cursor] == ' ' || line[cursor] == '\t')) {
      cursor += 1;
    }

    return cursor < line.length && line[cursor] == ':';
  }

  TextStyle _styleForToken(
    String token,
    TextStyle baseStyle,
    ColorScheme darkScheme, {
    required bool commentLine,
    required bool isKey,
  }) {
    if (_hexPattern.hasMatch(token)) {
      final color = _parseHexColor(token);
      return baseStyle.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        backgroundColor: color.withValues(alpha: 0.2),
      );
    }

    if (_quotedHexPattern.hasMatch(token)) {
      final color = _parseHexColor(token.substring(1, token.length - 1));
      return baseStyle.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        backgroundColor: color.withValues(alpha: 0.25),
      );
    }

    if (commentLine) {
      return baseStyle.copyWith(color: darkScheme.outline);
    }

    if (isKey) {
      return baseStyle.copyWith(
        color: darkScheme.secondary,
        fontWeight: FontWeight.w600,
      );
    }

    if (token.startsWith('"')) {
      return baseStyle.copyWith(color: darkScheme.tertiary);
    }
    if (_keywordPattern.hasMatch(token)) {
      return baseStyle.copyWith(color: darkScheme.primary);
    }
    if (_numberPattern.hasMatch(token)) {
      return baseStyle.copyWith(color: darkScheme.secondary);
    }
    if (_punctuationPattern.hasMatch(token)) {
      return baseStyle.copyWith(color: darkScheme.outline);
    }
    if (token.toUpperCase() == token && token.length > 1) {
      return baseStyle.copyWith(color: darkScheme.primary);
    }

    return baseStyle.copyWith(color: darkScheme.onSurfaceVariant);
  }
}

Future<void> _showColorEditDialog(
  BuildContext context,
  int index,
  ColorEntry color,
  void Function(int index, ColorEntry color) onUpdate,
) async {
  final nameController = TextEditingController(text: color.name);
  final hexController = TextEditingController(text: color.hexCode);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(context.tr('Edit Export Color')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: context.tr('Name'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: hexController,
              decoration: const InputDecoration(
                labelText: 'HEX',
                hintText: '#RRGGBB',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () {
              final normalized = _normalizeHexInput(hexController.text);
              if (normalized == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr('Invalid HEX format, please input #RRGGBB'),
                    ),

                  ),
                );
                return;
              }
              onUpdate(
                index,
                ColorEntry(
                  name: nameController.text.trim().isEmpty
                      ? 'Color ${index + 1}'
                      : nameController.text.trim(),
                  hexCode: normalized,
                ),
              );
              Navigator.of(dialogContext).pop();
            },
            child: Text(context.tr('Save')),
          ),
        ],
      );
    },
  );
}

class _PreviewBox extends StatefulWidget {
  const _PreviewBox({
    this.fullHeight = false,
    required this.imageBytes,
    required this.profile,
    required this.onProfileChanged,
  });

  final bool fullHeight;
  final Uint8List imageBytes;
  final ExtractionProfile profile;
  final ValueChanged<ExtractionProfile> onProfileChanged;

  @override
  State<_PreviewBox> createState() => _PreviewBoxState();
}

class _PreviewBoxState extends State<_PreviewBox> {
  Offset? _dragStart;
  Offset? _dragCurrent;

  Rect? _dragRect(double width, double height) {
    final start = _dragStart;
    final current = _dragCurrent;
    if (start == null || current == null) {
      return null;
    }
    return Rect.fromPoints(start, current).intersect(
      Rect.fromLTWH(0, 0, width, height),
    );
  }

  Rect _profileRect(double width, double height) {
    final profile = widget.profile;
    return Rect.fromLTWH(
      profile.boxLeft * width,
      profile.boxTop * height,
      profile.boxWidth * width,
      profile.boxHeight * height,
    );
  }

  void _commitDragRect(double width, double height) {
    final rect = _dragRect(width, height);
    if (rect == null || rect.width < 8 || rect.height < 8) {
      return;
    }

    final left = (rect.left / width).clamp(0.0, 1.0);
    final top = (rect.top / height).clamp(0.0, 1.0);
    final right = (rect.right / width).clamp(0.0, 1.0);
    final bottom = (rect.bottom / height).clamp(0.0, 1.0);

    widget.onProfileChanged(
      widget.profile.copyWith(
        mode: ExtractionMode.boxRange,
        boxLeft: left,
        boxTop: top,
        boxWidth: (right - left).clamp(0.05, 1.0),
        boxHeight: (bottom - top).clamp(0.05, 1.0),
      ),
    );
  }

  void _handleBoxPanStart(DragStartDetails details) {
    if (widget.profile.mode != ExtractionMode.boxRange) return;
    setState(() {
      _dragStart = details.localPosition;
      _dragCurrent = details.localPosition;
    });
  }

  void _handleBoxPanUpdate(DragUpdateDetails details) {
    if (widget.profile.mode != ExtractionMode.boxRange || _dragStart == null) return;
    setState(() {
      _dragCurrent = details.localPosition;
    });
  }

  void _handleBoxPanEnd(double width, double height) {
    if (widget.profile.mode != ExtractionMode.boxRange || _dragStart == null) return;
    _commitDragRect(width, height);
    setState(() {
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final boundedHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : math.min(420.0, width * 0.8);
        final height =
            widget.fullHeight ? boundedHeight : math.min(260.0, width * 0.72);
        final profile = widget.profile;
        final boxRect = _profileRect(width, height);
        final dragRect = _dragRect(width, height);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: profile.mode == ExtractionMode.eyeDropper
              ? (details) {
                  final nx = (details.localPosition.dx / width).clamp(0.0, 1.0);
                  final ny =
                      (details.localPosition.dy / height).clamp(0.0, 1.0);
                  widget.onProfileChanged(
                    profile.copyWith(
                      eyeDropperX: nx,
                      eyeDropperY: ny,
                    ),

                  );
                }
              : null,
          child: Container(
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 6,
                  panEnabled: false,
                  scaleEnabled: true,
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: Image.memory(
                      widget.imageBytes,
                      fit: BoxFit.contain,
                    ),

                  ),
                ),
                if (profile.mode == ExtractionMode.boxRange)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: _handleBoxPanStart,
                      onPanUpdate: _handleBoxPanUpdate,
                      onPanEnd: (details) => _handleBoxPanEnd(width, height),
                      onPanCancel: () => _handleBoxPanEnd(width, height),
                    ),

                  ),
                if (profile.mode == ExtractionMode.boxRange)
                  Positioned.fromRect(
                    rect: boxRect,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),

                    ),

                  ),
                if (profile.mode == ExtractionMode.boxRange && dragRect != null)
                  Positioned.fromRect(
                    rect: dragRect,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFF2563EB), width: 2),
                        color: const Color(0xFF2563EB).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),

                    ),

                  ),
                if (profile.mode == ExtractionMode.eyeDropper)
                  Positioned(
                    left: (profile.eyeDropperX * width)
                        .clamp(0.0, width - 1)
                        .toDouble(),
                    top: (profile.eyeDropperY * height)
                        .clamp(0.0, height - 1)
                        .toDouble(),
                    child: const Icon(
                      Icons.add,
                      size: 22,
                      color: Colors.white,
                    ),

                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExtractionControls extends StatelessWidget {
  const _ExtractionControls({
    this.wrapped = true,
    required this.profile,
    required this.sourceKind,
    required this.hasSavedProfile,
    required this.isBusy,
    required this.onProfileChanged,
    required this.onReextractPressed,
    required this.onSaveProfilePressed,
    required this.onApplySavedProfilePressed,
  });

  final bool wrapped;
  final ExtractionProfile profile;
  final String sourceKind;
  final bool hasSavedProfile;
  final bool isBusy;
  final ValueChanged<ExtractionProfile> onProfileChanged;
  final Future<void> Function() onReextractPressed;
  final VoidCallback onSaveProfilePressed;
  final Future<void> Function() onApplySavedProfilePressed;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<ExtractionMode>(
          initialValue: profile.mode,
          decoration: InputDecoration(
            labelText: context.tr('Sampling Mode'),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          items: ExtractionMode.values
              .map(
                (mode) => DropdownMenuItem<ExtractionMode>(
                  value: mode,
                  child: Text(context.tr(_modeLabel(mode))),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) {
              onProfileChanged(profile.copyWith(mode: value));
            }
          },
        ),
        const SizedBox(height: 8),
        _LabeledSlider(
          label: context.tr(
            'Sampling count: {count}',
            params: <String, String>{'count': profile.sampleCount.toString()},
          ),
          value: profile.sampleCount.toDouble(),
          min: 1,
          max: 256,
          divisions: 255,
          onChanged: (value) => onProfileChanged(
            profile.copyWith(sampleCount: value.round()),
          ),
        ),
        if (profile.mode == ExtractionMode.selectedPage ||
            sourceKind == 'pdf') ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(context.tr('Page')),
              const SizedBox(width: 8),
              IconButton(
                onPressed: profile.pageIndex <= 1
                    ? null
                    : () => onProfileChanged(
                          profile.copyWith(pageIndex: profile.pageIndex - 1),
                        ),

                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('${profile.pageIndex}'),
              IconButton(
                onPressed: () => onProfileChanged(
                  profile.copyWith(pageIndex: profile.pageIndex + 1),
                ),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
        if (profile.mode == ExtractionMode.visibleRange) ...[
          const SizedBox(height: 8),
          _LabeledSlider(
            label: context.tr(
              'Visible range factor: {factor}',
              params: <String, String>{
                'factor': profile.visibleRangeFactor.toStringAsFixed(2),
              },
            ),
            value: profile.visibleRangeFactor,
            min: 0.1,
            max: 1.0,
            divisions: 18,
            onChanged: (value) => onProfileChanged(
              profile.copyWith(visibleRangeFactor: value),
            ),
          ),
        ],
        if (profile.mode == ExtractionMode.boxRange) ...[
          const SizedBox(height: 8),
          _LabeledSlider(
            label: context.tr(
              'Box left: {value}',
              params: <String, String>{
                'value': profile.boxLeft.toStringAsFixed(2),
              },
            ),
            value: profile.boxLeft,
            min: 0,
            max: 1,
            divisions: 20,
            onChanged: (value) =>
                onProfileChanged(profile.copyWith(boxLeft: value)),
          ),
          _LabeledSlider(
            label: context.tr(
              'Box top: {value}',
              params: <String, String>{
                'value': profile.boxTop.toStringAsFixed(2),
              },
            ),
            value: profile.boxTop,
            min: 0,
            max: 1,
            divisions: 20,
            onChanged: (value) =>
                onProfileChanged(profile.copyWith(boxTop: value)),
          ),
          _LabeledSlider(
            label: context.tr(
              'Box width: {value}',
              params: <String, String>{
                'value': profile.boxWidth.toStringAsFixed(2),
              },
            ),
            value: profile.boxWidth,
            min: 0.05,
            max: 1,
            divisions: 19,
            onChanged: (value) =>
                onProfileChanged(profile.copyWith(boxWidth: value)),
          ),
          _LabeledSlider(
            label: context.tr(
              'Box height: {value}',
              params: <String, String>{
                'value': profile.boxHeight.toStringAsFixed(2),
              },
            ),
            value: profile.boxHeight,
            min: 0.05,
            max: 1,
            divisions: 19,
            onChanged: (value) =>
                onProfileChanged(profile.copyWith(boxHeight: value)),
          ),
        ],
        if (profile.mode == ExtractionMode.eyeDropper) ...[
          const SizedBox(height: 8),
          _LabeledSlider(
            label: context.tr(
              'Eyedropper X: {value}',
              params: <String, String>{
                'value': profile.eyeDropperX.toStringAsFixed(2),
              },
            ),
            value: profile.eyeDropperX,
            min: 0,
            max: 1,
            divisions: 20,
            onChanged: (value) =>
                onProfileChanged(profile.copyWith(eyeDropperX: value)),
          ),
          _LabeledSlider(
            label: context.tr(
              'Eyedropper Y: {value}',
              params: <String, String>{
                'value': profile.eyeDropperY.toStringAsFixed(2),
              },
            ),
            value: profile.eyeDropperY,
            min: 0,
            max: 1,
            divisions: 20,
            onChanged: (value) =>
                onProfileChanged(profile.copyWith(eyeDropperY: value)),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: isBusy ? null : () => onReextractPressed(),
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('Run Sampling')),
            ),
            OutlinedButton.icon(
              onPressed: isBusy ? null : onSaveProfilePressed,
              icon: const Icon(Icons.save_alt_outlined),
              label: Text(context.tr('Save Profile')),
            ),
            OutlinedButton.icon(
              onPressed: isBusy || !hasSavedProfile
                  ? null
                  : () => onApplySavedProfilePressed(),
              icon: const Icon(Icons.settings_backup_restore),
              label: Text(context.tr('Apply Saved Profile')),
            ),
          ],
        ),
      ],
    );

    if (!wrapped) {
      return content;
    }

    return _SectionCard(
      title: 'Sampling Settings',
      child: content,
    );
  }
}

class _PaletteChartPreview extends StatelessWidget {
  const _PaletteChartPreview({
    required this.colors,
    required this.mode,
    required this.visionMode,
    required this.seriesCount,
    required this.groupCount,
    required this.lineWidth,
    required this.markerSize,
    required this.markerShape,
    required this.alphaPercent,
    required this.isSelected,
  });

  final List<ColorEntry> colors;
  final PaletteChartMode mode;
  final PalettePreviewVisionMode visionMode;
  final int seriesCount;
  final int groupCount;
  final int lineWidth;
  final int markerSize;
  final PaletteMarkerShape markerShape;
  final int alphaPercent;
  final bool Function(ColorEntry color) isSelected;

  @override
  Widget build(BuildContext context) {
    if (colors.isEmpty) {
      return const _EmptyState(
        title: 'No visual data',
        description: 'Please run sampling first.',
      );
    }

    if (mode == PaletteChartMode.table) {
      final dummyData = [
        ['001', 'Primary Action', 'Active', '1,200.00'],
        ['002', 'Secondary Sidebar', 'Idle', '850.50'],
        ['003', 'Header Background', 'Pinned', '200.00'],
        ['004', 'System Feedback', 'Error', '0.00'],
        ['005', 'Success Indicator', 'Done', '1,500.00'],
        ['006', 'Neutral Contrast', 'Hidden', '45.00'],
      ];

      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SingleChildScrollView(
          child: Table(
            border: TableBorder.all(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                children: [
                   for (var head in ['ID', 'Hex', 'Name', 'Val'])
                     Padding(
                       padding: const EdgeInsets.all(8.0),
                       child: Text(head, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                     ),

                ],
              ),
              for (int i = 0; i < math.min(colors.length, 12); i++)
                TableRow(
                  decoration: BoxDecoration(
                    color: _previewColor(colors[i].hexCode, visionMode).withOpacity(0.85),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('${(i + 1).toString().padLeft(3, '0')}', 
                        style: TextStyle(fontSize: 12, color: _luminanceOfHex(colors[i].hexCode) > 0.45 ? Colors.black : Colors.white)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(colors[i].hexCode, 
                        style: TextStyle(fontSize: 12, color: _luminanceOfHex(colors[i].hexCode) > 0.45 ? Colors.black : Colors.white)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(colors[i].name, 
                        style: TextStyle(fontSize: 12, color: _luminanceOfHex(colors[i].hexCode) > 0.45 ? Colors.black : Colors.white, overflow: TextOverflow.ellipsis)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('${(1000 - i * 50).toStringAsFixed(1)}', 
                        style: TextStyle(fontSize: 12, color: _luminanceOfHex(colors[i].hexCode) > 0.45 ? Colors.black : Colors.white)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: CustomPaint(
          painter: _PaletteChartPainter(
            colors: colors,
            mode: mode,
            visionMode: visionMode,
            seriesCount: seriesCount,
            groupCount: groupCount,
            lineWidth: lineWidth,
            markerSize: markerSize,
            markerShape: markerShape,
            alphaPercent: alphaPercent,
            isSelected: isSelected,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _PaletteChartPainter extends CustomPainter {
  _PaletteChartPainter({
    required this.colors,
    required this.mode,
    required this.visionMode,
    required this.seriesCount,
    required this.groupCount,
    required this.lineWidth,
    required this.markerSize,
    required this.markerShape,
    required this.alphaPercent,
    required this.isSelected,
  });

  final List<ColorEntry> colors;
  final PaletteChartMode mode;
  final PalettePreviewVisionMode visionMode;
  final int seriesCount;
  final int groupCount;
  final int lineWidth;
  final int markerSize;
  final PaletteMarkerShape markerShape;
  final int alphaPercent;
  final bool Function(ColorEntry color) isSelected;

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) {
      return;
    }

    if (mode == PaletteChartMode.heatmap) {
      _paintHeatmap(canvas, size);
      return;
    }
    if (mode == PaletteChartMode.circular) {
      _paintCircular(canvas, size);
      return;
    }
    if (mode == PaletteChartMode.map) {
      _paintMap(canvas, size);
      return;
    }

    _paintStandard(canvas, size);
  }

  void _paintStandard(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = Colors.grey.shade500
      ..strokeWidth = 1;

    final leftPad = 24.0;
    final bottomPad = 20.0;
    final chartWidth = math.max(1.0, size.width - leftPad - 8);
    final chartHeight = math.max(1.0, size.height - bottomPad - 10);

    canvas.drawLine(
      Offset(leftPad, 4),
      Offset(leftPad, chartHeight),
      axis,
    );
    canvas.drawLine(
      Offset(leftPad, chartHeight),
      Offset(leftPad + chartWidth, chartHeight),
      axis,
    );

    final hasFocus = colors.any(isSelected);
    final seriesTotal = math.max(1, seriesCount);
    final pointTotal = math.max(2, groupCount);

    for (var seriesIndex = 0; seriesIndex < seriesTotal; seriesIndex += 1) {
      final values = <double>[];
      for (var pointIndex = 0; pointIndex < pointTotal; pointIndex += 1) {
        final base = math.sin((pointIndex + 1) * 0.8 + seriesIndex * 0.9);
        final value = 0.48 + 0.18 * base + 0.06 * seriesIndex;
        values.add(value.clamp(0.08, 0.92));
      }

      final points = <Offset>[];
      for (var pointIndex = 0; pointIndex < pointTotal; pointIndex += 1) {
        final x = leftPad +
            (chartWidth *
                (pointTotal == 1 ? 0.5 : pointIndex / (pointTotal - 1)));
        final y = chartHeight - values[pointIndex] * chartHeight;
        points.add(Offset(x, y));
      }

      final color = _effectiveSeriesColor(seriesIndex, hasFocus: hasFocus);
      final highlighted = _isSeriesHighlighted(seriesIndex);

      if (mode == PaletteChartMode.bar) {
        final slotWidth = chartWidth / pointTotal;
        final barWidth = math.max(6.0, slotWidth / (seriesTotal + 0.8));
        for (var pointIndex = 0; pointIndex < pointTotal; pointIndex += 1) {
          final left = leftPad +
              slotWidth * pointIndex +
              seriesIndex * barWidth -
              (seriesTotal - 1) * barWidth / 2;
          final top = chartHeight - values[pointIndex] * chartHeight;
          final rect = Rect.fromLTWH(
            left,
            top,
            barWidth - 2,
            chartHeight - top,
          );
          canvas.drawRect(
            rect,
            Paint()
              ..color = color
              ..style = PaintingStyle.fill,
          );
          if (highlighted) {
            canvas.drawRect(
              rect,
              Paint()
                ..color = Colors.black
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2,
            );
          }
        }
        continue;
      }

      if (mode == PaletteChartMode.line) {
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        for (var index = 1; index < points.length; index += 1) {
          path.lineTo(points[index].dx, points[index].dy);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..strokeWidth = highlighted ? lineWidth + 2 : lineWidth.toDouble()
            ..style = PaintingStyle.stroke,
        );
      }

      for (final point in points) {
        _drawMarker(
          canvas,
          point,
          color,
          highlighted: highlighted,
        );
      }
    }

    final axisTextPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    for (var pointIndex = 0; pointIndex < pointTotal; pointIndex += 1) {
      final x = leftPad +
          (chartWidth *
              (pointTotal == 1 ? 0.5 : pointIndex / (pointTotal - 1)));
      axisTextPainter.text = TextSpan(
        text: '${pointIndex + 1}',
        style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(
        canvas,
        Offset(x - axisTextPainter.width / 2, chartHeight + 4),
      );
    }
  }

  void _paintHeatmap(Canvas canvas, Size size) {
    final rows = math.max(8, math.min(18, seriesCount * 3));
    final cols = math.max(8, math.min(18, groupCount * 3));
    final matrixRect = Rect.fromLTWH(18, 18, size.width - 36, size.height - 42);
    final cellW = matrixRect.width / cols;
    final cellH = matrixRect.height / rows;
    final hasFocus = colors.any(isSelected);

    for (var row = 0; row < rows; row += 1) {
      final base =
          _effectiveSeriesColor(row, hasFocus: hasFocus).withAlpha(255);
      for (var col = 0; col < cols; col += 1) {
        final wave = 0.5 + 0.5 * math.sin((row + 1) * 0.48 + (col + 1) * 0.35);
        final lift = 0.88 + 0.12 * wave;
        final cellColor = Color.fromARGB(
          255,
          _clampChannel(255 - (255 - base.red) * lift),
          _clampChannel(255 - (255 - base.green) * lift),
          _clampChannel(255 - (255 - base.blue) * lift),
        );
        final rect = Rect.fromLTWH(
          matrixRect.left + col * cellW,
          matrixRect.top + row * cellH,
          cellW,
          cellH,
        );
        canvas.drawRect(
          rect,
          Paint()..color = cellColor,
        );
      }
    }

    canvas.drawRect(
      matrixRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFCBD5E1),
    );
  }

  void _paintCircular(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = math.min(size.width, size.height) * 0.34;
    final rings = math.max(3, math.min(7, seriesCount));
    final segments = math.max(colors.length, groupCount);
    final hasFocus = colors.any(isSelected);

    for (var ring = 0; ring < rings; ring += 1) {
      final inner = radius + ring * 12;
      final outer = inner + 10;
      final ringRadius = (inner + outer) / 2;
      final stroke = math.max(3.0, outer - inner);
      final oval = Rect.fromCircle(center: center, radius: ringRadius);

      for (var segment = 0; segment < segments; segment += 1) {
        final color = _effectiveSeriesColor(segment + ring, hasFocus: hasFocus);
        final start = -math.pi / 2 + (2 * math.pi * segment / segments);
        final sweep = (2 * math.pi / segments) * 0.95;
        canvas.drawArc(
          oval,
          start,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round
            ..color = color,
        );
      }
    }
  }

  void _paintMap(Canvas canvas, Size size) {
    final content = Rect.fromLTWH(16, 12, size.width - 32, size.height - 30);
    final hasFocus = colors.any(isSelected);

    final polygons = <List<Offset>>[
      const [
        Offset(0.05, 0.55),
        Offset(0.18, 0.44),
        Offset(0.27, 0.5),
        Offset(0.21, 0.64),
        Offset(0.08, 0.68),
      ],
      const [
        Offset(0.22, 0.44),
        Offset(0.36, 0.32),
        Offset(0.5, 0.38),
        Offset(0.45, 0.54),
        Offset(0.3, 0.58),
      ],
      const [
        Offset(0.45, 0.36),
        Offset(0.62, 0.24),
        Offset(0.78, 0.3),
        Offset(0.72, 0.48),
        Offset(0.54, 0.52),
      ],
      const [
        Offset(0.34, 0.58),
        Offset(0.52, 0.52),
        Offset(0.63, 0.62),
        Offset(0.51, 0.76),
        Offset(0.31, 0.74),
      ],
      const [
        Offset(0.62, 0.52),
        Offset(0.79, 0.47),
        Offset(0.9, 0.56),
        Offset(0.84, 0.72),
        Offset(0.66, 0.73),
      ],
    ];

    for (var index = 0; index < polygons.length; index += 1) {
      final path = Path();
      final polygon = polygons[index];
      final color = _effectiveSeriesColor(index, hasFocus: hasFocus);
      for (var pointIndex = 0; pointIndex < polygon.length; pointIndex += 1) {
        final p = Offset(
          content.left + polygon[pointIndex].dx * content.width,
          content.top + polygon[pointIndex].dy * content.height,
        );
        if (pointIndex == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()..color = color,
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF94A3B8),
      );
    }
  }

  Color _effectiveSeriesColor(int seriesIndex, {required bool hasFocus}) {
    final colorEntry = colors[seriesIndex % colors.length];
    final preview = _previewColor(colorEntry.hexCode, visionMode);
    final highlighted = isSelected(colorEntry);
    final effectiveAlpha = hasFocus && !highlighted
        ? math.max(18, alphaPercent ~/ 3)
        : alphaPercent;
    return preview.withAlpha((255 * effectiveAlpha / 100).round());
  }

  bool _isSeriesHighlighted(int seriesIndex) {
    final colorEntry = colors[seriesIndex % colors.length];
    return isSelected(colorEntry);
  }

  void _drawMarker(
    Canvas canvas,
    Offset point,
    Color color, {
    required bool highlighted,
  }) {
    final radius = highlighted ? markerSize * 0.65 : markerSize * 0.5;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color =
          highlighted ? Colors.black : Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = highlighted ? 2 : 1;

    switch (markerShape) {
      case PaletteMarkerShape.circle:
        canvas.drawCircle(point, radius, fill);
        canvas.drawCircle(point, radius, stroke);
      case PaletteMarkerShape.square:
        final rect = Rect.fromCenter(
          center: point,
          width: radius * 2,
          height: radius * 2,
        );
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, stroke);
      case PaletteMarkerShape.triangle:
        final path = Path()
          ..moveTo(point.dx, point.dy - radius)
          ..lineTo(point.dx - radius, point.dy + radius)
          ..lineTo(point.dx + radius, point.dy + radius)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _PaletteChartPainter oldDelegate) {
    return oldDelegate.colors != colors ||
        oldDelegate.mode != mode ||
        oldDelegate.visionMode != visionMode ||
        oldDelegate.seriesCount != seriesCount ||
        oldDelegate.groupCount != groupCount ||
        oldDelegate.lineWidth != lineWidth ||
        oldDelegate.markerSize != markerSize ||
        oldDelegate.markerShape != markerShape ||
        oldDelegate.alphaPercent != alphaPercent;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(title),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PanelFrame extends StatelessWidget {
  const _PanelFrame({
    required this.title,
    this.subtitle = '',
    this.headerAction,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget? headerAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final panelColor = Theme.of(context).brightness == Brightness.dark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerLow;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: panelColor,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr(title), style: Theme.of(context).textTheme.titleMedium),
                      if (subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          context.tr(subtitle),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),

                      ],
                    ],
                  ),
                ),
                if (headerAction != null) headerAction!,
              ],
            ),
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
            width: selected ? 2.4 : 1,
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
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),

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
              color:
                  selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
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
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.primary,
          ),
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
            Text(context.tr(title),
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              context.tr(description),
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

String _modeLabel(ExtractionMode mode) {
  return switch (mode) {
    ExtractionMode.wholeFile => 'Whole File',
    ExtractionMode.selectedPage => 'Selected Page',
    ExtractionMode.visibleRange => 'Visible Range',
    ExtractionMode.boxRange => 'Box Range (Drag)',
    ExtractionMode.eyeDropper => 'Eyedropper',
    ExtractionMode.cameraFrame => 'Camera Frame',
  };
}

String _chartModeLabel(PaletteChartMode mode) {
  return switch (mode) {
    PaletteChartMode.table => 'Table',
    PaletteChartMode.line => 'Line Chart',
    PaletteChartMode.bar => 'Bar Chart',
    PaletteChartMode.scatter => 'Scatter Plot',
    PaletteChartMode.heatmap => 'Clustered Heatmap',
    PaletteChartMode.circular => 'Circular Chart',
    PaletteChartMode.map => 'Map View',
  };
}

bool _chartModeUsesMarkerShape(PaletteChartMode mode) {
  return mode == PaletteChartMode.line || mode == PaletteChartMode.scatter;
}

String _visionModeLabel(PalettePreviewVisionMode mode) {
  return switch (mode) {
    PalettePreviewVisionMode.normal => 'Normal',
    PalettePreviewVisionMode.grayscale => 'Grayscale',
    PalettePreviewVisionMode.colorblindProtan => 'Colorblind Protan',
    PalettePreviewVisionMode.colorblindDeutan => 'Colorblind Deutan',
    PalettePreviewVisionMode.colorblindTritan => 'Colorblind Tritan',
  };
}

String _markerShapeLabel(PaletteMarkerShape shape) {
  return switch (shape) {
    PaletteMarkerShape.circle => 'Circle',
    PaletteMarkerShape.square => 'Square',
    PaletteMarkerShape.triangle => 'Triangle',
  };
}

String _rgbTextFromHex(String hexCode) {
  final color = _parseHexColor(hexCode);
  return '${color.r},${color.g},${color.b}';
}

String _generationLabel(PaletteGenerationKind kind) {
  return switch (kind) {
    PaletteGenerationKind.twoColorGradient => 'Two-Color Gradient',
    PaletteGenerationKind.analogous => 'Analogous',
    PaletteGenerationKind.complementary => 'Complementary',
    PaletteGenerationKind.toWhite => 'Gradient to White',
    PaletteGenerationKind.perceptuallyUniform => 'Perceptually Uniform',
    PaletteGenerationKind.rainbow => 'Rainbow/Jet',
  };
}

String _whiteTemperatureLabel(WhiteTemperature value) {
  return switch (value) {
    WhiteTemperature.warm => 'Warm White',
    WhiteTemperature.neutral => 'Neutral White',
    WhiteTemperature.cool => 'Cool White',
  };
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

Color _previewColor(String hexCode, PalettePreviewVisionMode mode) {
  final raw = _parseHexColor(hexCode);
  if (mode == PalettePreviewVisionMode.normal) {
    return raw;
  }

  final r = raw.red.toDouble();
  final g = raw.green.toDouble();
  final b = raw.blue.toDouble();

  if (mode == PalettePreviewVisionMode.grayscale) {
    final gray = _clampChannel(0.299 * r + 0.587 * g + 0.114 * b);
    return Color.fromARGB(255, gray, gray, gray);
  }

  if (mode == PalettePreviewVisionMode.colorblindProtan) {
    return Color.fromARGB(
      255,
      _clampChannel(0.56667 * r + 0.43333 * g),
      _clampChannel(0.55833 * r + 0.44167 * g),
      _clampChannel(0.24167 * g + 0.75833 * b),
    );
  }

  if (mode == PalettePreviewVisionMode.colorblindDeutan) {
    return Color.fromARGB(
      255,
      _clampChannel(0.625 * r + 0.375 * g),
      _clampChannel(0.7 * r + 0.3 * g),
      _clampChannel(0.3 * g + 0.7 * b),
    );
  }

  return Color.fromARGB(
    255,
    _clampChannel(0.95 * r + 0.05 * g),
    _clampChannel(0.43333 * g + 0.56667 * b),
    _clampChannel(0.475 * g + 0.525 * b),
  );
}

double _luminanceOfHex(String hexCode) {
  final c = _parseHexColor(hexCode);
  return (0.2126 * c.red / 255.0) +
      (0.7152 * c.green / 255.0) +
      (0.0722 * c.blue / 255.0);
}

Color _parseHexColor(String hexCode) {
  final value = hexCode.replaceFirst('#', '').padLeft(6, '0').substring(0, 6);
  return Color(int.parse('FF$value', radix: 16));
}

int _clampChannel(num value) {
  return value.round().clamp(0, 255).toInt();
}


enum _FullscreenViewState { idle, boxRange, colorPicker }

class _FullscreenPreviewDialog extends StatefulWidget {
  const _FullscreenPreviewDialog({
    required this.file,
    required this.onExtractFromBox,
    required this.onExtractPixel,
  });

  final ManagedPaletteFile file;
  final ValueChanged<Rect> onExtractFromBox;
  final ValueChanged<Color> onExtractPixel;

  @override
  State<_FullscreenPreviewDialog> createState() => _FullscreenPreviewDialogState();
}

class _FullscreenPreviewDialogState extends State<_FullscreenPreviewDialog> {
  final GlobalKey _imageCardKey = GlobalKey();
  _FullscreenViewState _state = _FullscreenViewState.idle;
  
  img.Image? _decodedImage;
  Offset? _pointerPos;
  Color? _pointerColor;
  
  Offset? _dragStart;
  Offset? _dragCurrent;

  late final Uint8List _cachedBytes;

  @override
  void initState() {
    super.initState();
    _cachedBytes = Uint8List.fromList(widget.file.sourceBytes!);
    _decodeImageAsync();
  }
  
  Future<void> _decodeImageAsync() async {
    final bytes = widget.file.sourceBytes;
    if (bytes != null) {
      final decoded = img.decodeImage(Uint8List.fromList(bytes));
      if (mounted) {
        setState(() {
          _decodedImage = decoded;
        });
      }
    }
  }

  void _handlePointerPan(DragUpdateDetails details, BoxConstraints constraints) {
    if (_decodedImage == null) return;
    final RenderBox? renderBox = _imageCardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final localPos = renderBox.globalToLocal(details.globalPosition);
    final w = renderBox.size.width;
    final h = renderBox.size.height;
    final pctX = (localPos.dx / w).clamp(0.0, 1.0);
    final pctY = (localPos.dy / h).clamp(0.0, 1.0);
    final px = (pctX * (_decodedImage!.width - 1)).round();
    final py = (pctY * (_decodedImage!.height - 1)).round();
    final pixel = _decodedImage!.getPixel(px, py);
    setState(() {
      _pointerPos = localPos;
      _pointerColor = Color.fromARGB(pixel.a.toInt(), pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
    });
  }
  void _handleBoxStart(DragStartDetails details) {
    final RenderBox? renderBox = _imageCardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final localPos = renderBox.globalToLocal(details.globalPosition);
    setState(() {
      _dragStart = localPos;
      _dragCurrent = localPos;
    });
  }

  void _handleBoxUpdate(DragUpdateDetails details) {
    final RenderBox? renderBox = _imageCardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final localPos = renderBox.globalToLocal(details.globalPosition);
    setState(() {
      _dragCurrent = localPos;
    });
  }

  Widget _buildTopButtons() {
    List<Widget> buttons = [];
    
    if (_state == _FullscreenViewState.idle) {
      buttons = [
        FloatingActionButton.small(
          heroTag: 'fs_close',
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(Icons.close),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          heroTag: 'fs_box',
          onPressed: () => setState(() => _state = _FullscreenViewState.boxRange),
          child: const Icon(Icons.crop),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          heroTag: 'fs_pick',
          onPressed: () => setState(() => _state = _FullscreenViewState.colorPicker),
          child: const Icon(Icons.colorize),
        ),
      ];
    } else if (_state == _FullscreenViewState.boxRange) {
      buttons = [
        FloatingActionButton.small(
          heroTag: 'fs_back_b',
          onPressed: () => setState(() => _state = _FullscreenViewState.idle),
          child: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          heroTag: 'fs_exec_b',
          onPressed: () {
            if (_dragStart != null && _dragCurrent != null) {
              final RenderBox? renderBox = _imageCardKey.currentContext?.findRenderObject() as RenderBox?;
              if (renderBox == null) return;
              final w = renderBox.size.width;
              final h = renderBox.size.height;
              final rect = Rect.fromPoints(_dragStart!, _dragCurrent!).intersect(Rect.fromLTWH(0, 0, w, h));
              final left = (rect.left / w).clamp(0.0, 1.0);
              final top = (rect.top / h).clamp(0.0, 1.0);
              final right = (rect.right / w).clamp(0.0, 1.0);
              final bottom = (rect.bottom / h).clamp(0.0, 1.0);
              widget.onExtractFromBox(Rect.fromLTRB(left, top, right, bottom));
              Navigator.of(context).pop();
            }
          },
          child: const Icon(Icons.check),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          heroTag: 'fs_rst_b',
          onPressed: () => setState(() {
            _dragStart = null;
            _dragCurrent = null;
          }),
          child: const Icon(Icons.refresh),
        ),
      ];
    } else if (_state == _FullscreenViewState.colorPicker) {
      buttons = [
        FloatingActionButton.small(
          heroTag: 'fs_back_p',
          onPressed: () => setState(() => _state = _FullscreenViewState.idle),
          child: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          heroTag: 'fs_exec_p',
          onPressed: () {
            if (_pointerColor != null) {
              widget.onExtractPixel(_pointerColor!);
            }
          },
          child: const Icon(Icons.check),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          heroTag: 'fs_del_p',
          onPressed: () {},
          child: const Icon(Icons.undo),
        ),
      ];
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: buttons,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Image.memory(
      _cachedBytes,
      fit: BoxFit.contain,
    );

    if (_state != _FullscreenViewState.idle) {
      content = LayoutBuilder(
        builder: (context, constraints) {
          final isPicker = _state == _FullscreenViewState.colorPicker;
          return GestureDetector(
            onPanStart: _state == _FullscreenViewState.boxRange ? _handleBoxStart : (d) => _handlePointerPan(DragUpdateDetails(globalPosition: d.globalPosition, localPosition: d.localPosition), constraints),
            onPanUpdate: _state == _FullscreenViewState.boxRange ? _handleBoxUpdate : (d) => _handlePointerPan(d, constraints),
            child: Center(
              child: AspectRatio(
                key: _imageCardKey,
                aspectRatio: _decodedImage != null ? _decodedImage!.width / _decodedImage!.height : 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      _cachedBytes,
                      fit: BoxFit.fill,
                    ),
                    if (_state == _FullscreenViewState.boxRange && _dragStart != null && _dragCurrent != null)
                      Positioned.fromRect(
                        rect: Rect.fromPoints(_dragStart!, _dragCurrent!),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                    if (isPicker && _pointerPos != null && _pointerColor != null)
                      Positioned(
                        left: _pointerPos!.dx,
                        top: _pointerPos!.dy,
                        child: FractionalTranslation(
                          translation: const Offset(0.2, -1.2),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              border: Border.all(color: Colors.white54),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 24, height: 24, color: _pointerColor),
                                const SizedBox(width: 8),
                                Text(
                                  '#${_pointerColor!.value.toRadixString(16).padLeft(8, "0").substring(2).toUpperCase()}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      content = InteractiveViewer(
        maxScale: 10.0,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: content),
          Positioned(
            top: 10,
            right: 10,
            child: _buildTopButtons(),
          ),
        ],
      ),
    );
  }
}


class HeaderDragWrapper extends StatelessWidget {
  const HeaderDragWrapper({
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.child,
  });

  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Transparent overlay on the header area only (~56px top)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 56,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: onDragUpdate,
            onHorizontalDragEnd: onDragEnd,
          ),
        ),
      ],
    );
  }
}

class _SamplingColorItem extends StatelessWidget {
  const _SamplingColorItem({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final ColorEntry color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final itemColor = _parseHexColor(color.hexCode);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected 
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
              ? colorScheme.primary.withValues(alpha: 0.5)
              : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: itemColor,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    color.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    color.hexCode.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontFamily: "monospace",
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.add_circle_outline,
              size: 20,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

