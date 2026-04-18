import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/models/color_entry.dart';
import '../core/models/extraction_profile.dart';
import '../core/models/managed_palette_file.dart';
import '../core/services/palette_generation_service.dart';

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
    required this.files,
    required this.selectedFile,
    required this.isBusy,
    required this.searchText,
    required this.favoritesOnly,
    required this.statusMessage,
    required this.onImportPressed,
    required this.onImportCameraPressed,
    required this.onFavoriteFilterChanged,
    required this.onSearchChanged,
    required this.onFileSelected,
    required this.onToggleFavorite,
  });

  final List<ManagedPaletteFile> files;
  final ManagedPaletteFile? selectedFile;
  final bool isBusy;
  final String searchText;
  final bool favoritesOnly;
  final String? statusMessage;
  final Future<void> Function() onImportPressed;
  final Future<void> Function() onImportCameraPressed;
  final ValueChanged<bool> onFavoriteFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ManagedPaletteFile> onFileSelected;
  final Future<void> Function(ManagedPaletteFile) onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return _PanelFrame(
      title: '管理区',
      subtitle: '',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isBusy ? null : () => onImportPressed(),
                  icon: const Icon(Icons.file_open),
                  label: const Text('导入文件'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : () => onImportCameraPressed(),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('相机取色'),
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
              hintText: '按文件名/格式搜索',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              selected: favoritesOnly,
              onSelected: onFavoriteFilterChanged,
              label: const Text('仅看收藏'),
            ),
          ),
          if (statusMessage != null && statusMessage!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _StatusText(message: statusMessage!),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: files.isEmpty
                ? const _EmptyState(
                    title: '还没有文件',
                    description: '支持 JSON/CSV/GPL/CPT/ASE/PAL、图片与 PDF。',
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
                            '${file.palette.colors.length} 色 · ${file.palette.sourceFormat.toUpperCase()} · ${_modeLabel(file.extractionProfile.mode)} · 重采样${file.extractionRuns}次',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: file.isFavorite ? '取消收藏' : '收藏',
                            icon: Icon(
                              file.isFavorite ? Icons.star : Icons.star_border,
                              color: file.isFavorite
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            onPressed: () => onToggleFavorite(file),
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
        title: '预览区',
        subtitle: '文件预览、取色模式、图表预览。',
        child: _EmptyState(
          title: '还未选择文件',
          description: '从左侧导入或选择文件后可进行可变数量取色。',
          action: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: isBusy ? null : () => onImportPressed(),
                icon: const Icon(Icons.file_open),
                label: const Text('导入文件'),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : () => onImportCameraPressed(),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('相机取色'),
              ),
            ],
          ),
        ),
      );
    }

    return _PanelFrame(
      title: '预览区',
      subtitle: '支持全文件/页面/展示范围/框选/取色器/相机模式。',
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
                  label: const Text('导入'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${file!.palette.colors.length} 色 · ${file!.palette.sourceFormat.toUpperCase()} · 当前模式: ${_modeLabel(file!.extractionProfile.mode)}',
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
              '取色结果（点选加入导出区）',
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
                    decoration: const InputDecoration(
                      labelText: '预览样式',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: PaletteChartMode.values
                        .map(
                          (mode) => DropdownMenuItem<PaletteChartMode>(
                            value: mode,
                            child: Text(_chartModeLabel(mode)),
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
                    decoration: const InputDecoration(
                      labelText: '视觉模式',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: PalettePreviewVisionMode.values
                        .map(
                          (mode) => DropdownMenuItem<PalettePreviewVisionMode>(
                            value: mode,
                            child: Text(_visionModeLabel(mode)),
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
                Expanded(
                  child: DropdownButtonFormField<PaletteMarkerShape>(
                    initialValue: previewMarkerShape,
                    decoration: const InputDecoration(
                      labelText: '点形状',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: PaletteMarkerShape.values
                        .map(
                          (shape) => DropdownMenuItem<PaletteMarkerShape>(
                            value: shape,
                            child: Text(_markerShapeLabel(shape)),
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
      title: '导出区',
      subtitle: '编辑导出配色、生成方案、排序并导出科研格式。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: cartColors.isEmpty ? null : onClearPressed,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('清空导出区'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUseSelectedPalettePressed,
                  icon: const Icon(Icons.layers_outlined),
                  label: const Text('载入当前文件'),
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
            title: '配色生成器',
            child: Column(
              children: [
                DropdownButtonFormField<PaletteGenerationKind>(
                  initialValue: generationKind,
                  decoration: const InputDecoration(
                    labelText: '生成模式',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: PaletteGenerationKind.values
                      .map(
                        (kind) => DropdownMenuItem<PaletteGenerationKind>(
                          value: kind,
                          child: Text(_generationLabel(kind)),
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
                        decoration: const InputDecoration(
                          labelText: '基色 (HEX)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: secondaryHex,
                        onChanged: onSecondaryHexChanged,
                        decoration: const InputDecoration(
                          labelText: '第二颜色 (HEX)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('数量: $generationSteps'),
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
                    decoration: const InputDecoration(
                      labelText: '白色温度',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: WhiteTemperature.values
                        .map(
                          (value) => DropdownMenuItem<WhiteTemperature>(
                            value: value,
                            child: Text(_whiteTemperatureLabel(value)),
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
                        label: const Text('替换导出区'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: isBusy ? null : onGenerateAppendPressed,
                        icon: const Icon(Icons.add),
                        label: const Text('追加到导出区'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            title: '导出策略',
            child: Column(
              children: [
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: sortByLightness,
                  onChanged: onSortByLightnessChanged,
                  title: const Text('按深浅排序后导出'),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: exportAsHeatmapGradient,
                  onChanged: onExportAsHeatmapGradientChanged,
                  title: const Text('导出渐变热图配色'),
                ),
                if (exportAsHeatmapGradient)
                  Row(
                    children: [
                      Text('热图步数: $heatmapSteps'),
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
                    title: '导出区为空',
                    description: '可从预览区点选颜色，或用上方生成器直接生成。',
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
                            tooltip: '移除',
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
          title: const Text('编辑导出颜色'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
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
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final normalized = _normalizeHexInput(hexController.text);
                if (normalized == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('HEX 格式无效，请输入 #RRGGBB')),
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
              child: const Text('保存'),
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
  });

  final ManagedPaletteFile? file;
  final bool isBusy;
  final Future<void> Function() onImportPressed;
  final Future<void> Function() onImportCameraPressed;
  final ValueChanged<ExtractionProfile> onProfileChanged;

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return _PanelFrame(
        title: '文件预览',
        subtitle: '',
        child: _EmptyState(
          title: '未选择文件',
          description: '先导入或选择文件',
          action: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: isBusy ? null : () => onImportPressed(),
                icon: const Icon(Icons.file_open),
                label: const Text('导入文件'),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : () => onImportCameraPressed(),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('相机取色'),
              ),
            ],
          ),
        ),
      );
    }

    return _PanelFrame(
      title: '文件预览',
      subtitle: '',
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
                '${file!.palette.colors.length} 色 · ${file!.palette.sourceFormat.toUpperCase()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: file!.previewBytes == null
                ? const _EmptyState(
                    title: '无预览图像',
                    description: '当前文件暂不支持图像预览',
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
        title: '预览控制',
        subtitle: '',
        child: const _EmptyState(
          title: '未选择文件',
          description: '选择文件后可配置取色与预览',
        ),
      );
    }

    return _PanelFrame(
      title: '预览控制',
      subtitle: '',
      child: ListView(
        children: [
          _FoldCard(
            title: '取色配置',
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
            title: '取色结果',
            expanded: resultExpanded,
            onExpandedChanged: onResultExpandedChanged,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: file!.palette.colors
                  .map(
                    (color) => SizedBox(
                      width: 160,
                      child: _ColorCard(
                        color: color,
                        selected: isColorInCart(color),
                        onPressed: () => onToggleCartColor(color),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 8),
          _FoldCard(
            title: '预览效果',
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
                        decoration: const InputDecoration(
                          labelText: '预览样式',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: PaletteChartMode.values
                            .map(
                              (mode) => DropdownMenuItem<PaletteChartMode>(
                                value: mode,
                                child: Text(_chartModeLabel(mode)),
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
                        decoration: const InputDecoration(
                          labelText: '视觉模式',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: PalettePreviewVisionMode.values
                            .map(
                              (mode) =>
                                  DropdownMenuItem<PalettePreviewVisionMode>(
                                value: mode,
                                child: Text(_visionModeLabel(mode)),
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
                const SizedBox(height: 8),
                DropdownButtonFormField<PaletteMarkerShape>(
                  initialValue: previewMarkerShape,
                  decoration: const InputDecoration(
                    labelText: '点形状',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: PaletteMarkerShape.values
                      .map(
                        (shape) => DropdownMenuItem<PaletteMarkerShape>(
                          value: shape,
                          child: Text(_markerShapeLabel(shape)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      onPreviewMarkerShapeChanged(value);
                    }
                  },
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
  });

  final String title;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final Widget child;

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
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: child,
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
      title: '管理区文件',
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
                    title: '暂无可预览文件',
                    description: '先到管理区导入文件后再在此选择。',
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
                            '${file.palette.colors.length} 色 · ${file.palette.sourceFormat.toUpperCase()}',
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
    required this.onRemoveColor,
    required this.onClearPressed,
    required this.onUseSelectedPalettePressed,
    required this.statusMessage,
  });

  final List<ColorEntry> cartColors;
  final ValueChanged<ColorEntry> onRemoveColor;
  final VoidCallback onClearPressed;
  final VoidCallback onUseSelectedPalettePressed;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    return _PanelFrame(
      title: '导出区累计颜色',
      subtitle: '',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: cartColors.isEmpty ? null : onClearPressed,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('清空'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUseSelectedPalettePressed,
                  icon: const Icon(Icons.layers_outlined),
                  label: const Text('载入当前文件'),
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
                    title: '导出区为空',
                    description: '在中间预览区点选颜色加入导出区。',
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
                          dense: true,
                          leading: _ColorDot(hexCode: color.hexCode),
                          title: Text(color.name),
                          subtitle: Text(color.hexCode),
                          trailing: IconButton(
                            tooltip: '移除',
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => onRemoveColor(color),
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
    required this.sortByLightness,
    required this.exportAsHeatmapGradient,
    required this.heatmapSteps,
    required this.generationKind,
    required this.baseHex,
    required this.secondaryHex,
    required this.generationSteps,
    required this.whiteTemperature,
    required this.cartIsEmpty,
    required this.colorCandidates,
    required this.formatExpanded,
    required this.generatorExpanded,
    required this.strategyExpanded,
    required this.onFormatExpandedChanged,
    required this.onGeneratorExpandedChanged,
    required this.onStrategyExpandedChanged,
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
  final bool cartIsEmpty;
  final List<ColorEntry> colorCandidates;
  final bool formatExpanded;
  final bool generatorExpanded;
  final bool strategyExpanded;
  final ValueChanged<bool> onFormatExpandedChanged;
  final ValueChanged<bool> onGeneratorExpandedChanged;
  final ValueChanged<bool> onStrategyExpandedChanged;
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

  String? _resolveCandidateHex(List<ColorEntry> candidates, String hex) {
    final target = hex.trim().toUpperCase();
    for (final candidate in candidates) {
      if (candidate.hexCode.toUpperCase() == target) {
        return candidate.hexCode.toUpperCase();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final uniqueCandidates = <String, ColorEntry>{
      for (final color in colorCandidates) color.hexCode.toUpperCase(): color,
    }.values.toList(growable: false);

    final baseSelection = _resolveCandidateHex(uniqueCandidates, baseHex);
    final secondarySelection =
        _resolveCandidateHex(uniqueCandidates, secondaryHex);

    return _PanelFrame(
      title: '导出选项设置',
      subtitle: '',
      child: ListView(
        children: [
          _FoldCard(
            title: '导出格式',
            expanded: formatExpanded,
            onExpandedChanged: onFormatExpandedChanged,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: supportedExtensions
                  .map(
                    (ext) => OutlinedButton(
                      onPressed: cartIsEmpty || isBusy
                          ? null
                          : () => onExportPressed(ext),
                      child: Text(ext.toUpperCase().replaceFirst('.', '')),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 8),
          _FoldCard(
            title: '配色生成器',
            expanded: generatorExpanded,
            onExpandedChanged: onGeneratorExpandedChanged,
            child: Column(
              children: [
                DropdownButtonFormField<PaletteGenerationKind>(
                  initialValue: generationKind,
                  decoration: const InputDecoration(
                    labelText: '生成模式',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: PaletteGenerationKind.values
                      .map(
                        (kind) => DropdownMenuItem<PaletteGenerationKind>(
                          value: kind,
                          child: Text(_generationLabel(kind)),
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('先在右侧颜色列表中添加颜色后再选择基色'),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: baseSelection,
                          decoration: const InputDecoration(
                            labelText: '基色',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: uniqueCandidates
                              .map(
                                (color) => DropdownMenuItem<String>(
                                  value: color.hexCode.toUpperCase(),
                                  child: Text('${color.name} ${color.hexCode}'),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value != null) {
                              onBaseHexChanged(value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: secondarySelection,
                          decoration: const InputDecoration(
                            labelText: '第二颜色',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: uniqueCandidates
                              .map(
                                (color) => DropdownMenuItem<String>(
                                  value: color.hexCode.toUpperCase(),
                                  child: Text('${color.name} ${color.hexCode}'),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value != null) {
                              onSecondaryHexChanged(value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('数量: $generationSteps'),
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
                    decoration: const InputDecoration(
                      labelText: '白色温度',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: WhiteTemperature.values
                        .map(
                          (value) => DropdownMenuItem<WhiteTemperature>(
                            value: value,
                            child: Text(_whiteTemperatureLabel(value)),
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
                        label: const Text('替换导出区'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: isBusy ? null : onGenerateAppendPressed,
                        icon: const Icon(Icons.add),
                        label: const Text('追加到导出区'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _FoldCard(
            title: '导出策略',
            expanded: strategyExpanded,
            onExpandedChanged: onStrategyExpandedChanged,
            child: Column(
              children: [
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: sortByLightness,
                  onChanged: onSortByLightnessChanged,
                  title: const Text('按深浅排序后导出'),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: exportAsHeatmapGradient,
                  onChanged: onExportAsHeatmapGradientChanged,
                  title: const Text('导出渐变热图配色'),
                ),
                if (exportAsHeatmapGradient)
                  Row(
                    children: [
                      Text('热图步数: $heatmapSteps'),
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

class ExportColorListPanel extends StatelessWidget {
  const ExportColorListPanel({
    super.key,
    required this.cartColors,
    required this.onRemoveColor,
    required this.onUpdateColor,
    required this.onClearPressed,
    required this.onUseSelectedPalettePressed,
    required this.statusMessage,
    required this.isBusy,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
    required this.onAddManualColorPressed,
  });

  final List<ColorEntry> cartColors;
  final ValueChanged<ColorEntry> onRemoveColor;
  final void Function(int index, ColorEntry color) onUpdateColor;
  final VoidCallback onClearPressed;
  final VoidCallback onUseSelectedPalettePressed;
  final String? statusMessage;
  final bool isBusy;
  final int? selectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;
  final Future<void> Function() onAddManualColorPressed;

  @override
  Widget build(BuildContext context) {
    return _PanelFrame(
      title: '导出颜色列表',
      subtitle: '',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: cartColors.isEmpty ? null : onClearPressed,
                icon: const Icon(Icons.delete_outline),
                label: const Text('清空导出区'),
              ),
              OutlinedButton.icon(
                onPressed: onUseSelectedPalettePressed,
                icon: const Icon(Icons.layers_outlined),
                label: const Text('载入当前文件'),
              ),
              FilledButton.tonalIcon(
                onPressed: isBusy ? null : () => onAddManualColorPressed(),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('手动添加颜色'),
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
          const SizedBox(height: 8),
          Expanded(
            child: cartColors.isEmpty
                ? const _EmptyState(
                    title: '导出区为空',
                    description: '可从预览区点选颜色，或用左侧生成器直接生成。',
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
                          selected: selectedIndex == index,
                          leading: _ColorDot(hexCode: color.hexCode),
                          title: Text(color.name),
                          subtitle: Text(color.hexCode),
                          onTap: () => onSelectedIndexChanged(index),
                          onLongPress: () => _showColorEditDialog(
                            context,
                            index,
                            color,
                            onUpdateColor,
                          ),
                          trailing: IconButton(
                            tooltip: '移除',
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
        title: const Text('编辑导出颜色'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '名称',
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
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final normalized = _normalizeHexInput(hexController.text);
              if (normalized == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('HEX 格式无效，请输入 #RRGGBB')),
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
            child: const Text('保存'),
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
          onPanStart: profile.mode == ExtractionMode.boxRange
              ? (details) {
                  setState(() {
                    _dragStart = details.localPosition;
                    _dragCurrent = details.localPosition;
                  });
                }
              : null,
          onPanUpdate: profile.mode == ExtractionMode.boxRange
              ? (details) {
                  setState(() {
                    _dragCurrent = details.localPosition;
                  });
                }
              : null,
          onPanEnd: profile.mode == ExtractionMode.boxRange
              ? (_) {
                  _commitDragRect(width, height);
                  setState(() {
                    _dragStart = null;
                    _dragCurrent = null;
                  });
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
          decoration: const InputDecoration(
            labelText: '取色模式',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: ExtractionMode.values
              .map(
                (mode) => DropdownMenuItem<ExtractionMode>(
                  value: mode,
                  child: Text(_modeLabel(mode)),
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
          label: '取色数量: ${profile.sampleCount}',
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
              const Text('页码'),
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
            label: '展示范围比例: ${profile.visibleRangeFactor.toStringAsFixed(2)}',
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
            label: '框选左边界: ${profile.boxLeft.toStringAsFixed(2)}',
            value: profile.boxLeft,
            min: 0,
            max: 1,
            divisions: 20,
            onChanged: (value) =>
                onProfileChanged(profile.copyWith(boxLeft: value)),
          ),
          _LabeledSlider(
            label: '框选上边界: ${profile.boxTop.toStringAsFixed(2)}',
            value: profile.boxTop,
            min: 0,
            max: 1,
            divisions: 20,
            onChanged: (value) =>
                onProfileChanged(profile.copyWith(boxTop: value)),
          ),
          _LabeledSlider(
            label: '框选宽度: ${profile.boxWidth.toStringAsFixed(2)}',
            value: profile.boxWidth,
            min: 0.05,
            max: 1,
            divisions: 19,
            onChanged: (value) =>
                onProfileChanged(profile.copyWith(boxWidth: value)),
          ),
          _LabeledSlider(
            label: '框选高度: ${profile.boxHeight.toStringAsFixed(2)}',
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
            label: '取色器 X: ${profile.eyeDropperX.toStringAsFixed(2)}',
            value: profile.eyeDropperX,
            min: 0,
            max: 1,
            divisions: 20,
            onChanged: (value) =>
                onProfileChanged(profile.copyWith(eyeDropperX: value)),
          ),
          _LabeledSlider(
            label: '取色器 Y: ${profile.eyeDropperY.toStringAsFixed(2)}',
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
              label: const Text('执行取色'),
            ),
            OutlinedButton.icon(
              onPressed: isBusy ? null : onSaveProfilePressed,
              icon: const Icon(Icons.save_alt_outlined),
              label: const Text('保存方案'),
            ),
            OutlinedButton.icon(
              onPressed: isBusy || !hasSavedProfile
                  ? null
                  : () => onApplySavedProfilePressed(),
              icon: const Icon(Icons.settings_backup_restore),
              label: const Text('应用已保存方案'),
            ),
          ],
        ),
      ],
    );

    if (!wrapped) {
      return content;
    }

    return _SectionCard(
      title: '取色配置',
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
        title: '无可视化数据',
        description: '请先进行取色。',
      );
    }

    if (mode == PaletteChartMode.table) {
      return DecoratedBox(
        decoration: BoxDecoration(
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListView.separated(
          itemCount: colors.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final color = colors[index];
            final selected = isSelected(color);
            final visual = _previewColor(color.hexCode, visionMode);
            return ListTile(
              dense: true,
              leading: Container(
                height: 14,
                width: 14,
                decoration: BoxDecoration(
                  color: visual,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.black.withValues(alpha: 0.2)),
                ),
              ),
              title: Text(
                color.name,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              subtitle: Text(color.hexCode),
              trailing: Text(
                  'L ${_luminanceOfHex(color.hexCode).toStringAsFixed(2)}'),
            );
          },
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
              title,
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
            if (subtitle.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
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

String _modeLabel(ExtractionMode mode) {
  return switch (mode) {
    ExtractionMode.wholeFile => '全文件',
    ExtractionMode.selectedPage => '可选页面',
    ExtractionMode.visibleRange => '展示范围',
    ExtractionMode.boxRange => '框选区域（拖拽）',
    ExtractionMode.eyeDropper => '取色器',
    ExtractionMode.cameraFrame => '相机画面',
  };
}

String _chartModeLabel(PaletteChartMode mode) {
  return switch (mode) {
    PaletteChartMode.table => '表格',
    PaletteChartMode.line => '折线图',
    PaletteChartMode.bar => '柱状图',
    PaletteChartMode.scatter => '散点图',
    PaletteChartMode.heatmap => '聚类热图',
    PaletteChartMode.circular => '环形图',
    PaletteChartMode.map => '地图示意',
  };
}

String _visionModeLabel(PalettePreviewVisionMode mode) {
  return switch (mode) {
    PalettePreviewVisionMode.normal => '普通',
    PalettePreviewVisionMode.grayscale => '灰度',
    PalettePreviewVisionMode.colorblindProtan => '色盲 Protan',
    PalettePreviewVisionMode.colorblindDeutan => '色盲 Deutan',
    PalettePreviewVisionMode.colorblindTritan => '色盲 Tritan',
  };
}

String _markerShapeLabel(PaletteMarkerShape shape) {
  return switch (shape) {
    PaletteMarkerShape.circle => '圆形',
    PaletteMarkerShape.square => '方形',
    PaletteMarkerShape.triangle => '三角',
  };
}

String _generationLabel(PaletteGenerationKind kind) {
  return switch (kind) {
    PaletteGenerationKind.twoColorGradient => '双色渐变',
    PaletteGenerationKind.heatmap => '热图配色',
    PaletteGenerationKind.analogous => '近似色',
    PaletteGenerationKind.complementary => '互补色',
    PaletteGenerationKind.toWhite => '到白色渐变',
  };
}

String _whiteTemperatureLabel(WhiteTemperature value) {
  return switch (value) {
    WhiteTemperature.warm => '暖白',
    WhiteTemperature.neutral => '中性白',
    WhiteTemperature.cool => '冷白',
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

  final r = raw.r.toDouble();
  final g = raw.g.toDouble();
  final b = raw.b.toDouble();

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
  return (0.2126 * (c.r / 255.0)) +
      (0.7152 * (c.g / 255.0)) +
      (0.0722 * (c.b / 255.0));
}

Color _parseHexColor(String hexCode) {
  final value = hexCode.replaceFirst('#', '').padLeft(6, '0').substring(0, 6);
  return Color(int.parse('FF$value', radix: 16));
}

int _clampChannel(num value) {
  return value.round().clamp(0, 255).toInt();
}
