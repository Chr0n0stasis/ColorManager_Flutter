import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/models/color_entry.dart';
import '../core/models/extraction_profile.dart';
import '../core/models/managed_palette_file.dart';
import '../core/services/palette_generation_service.dart';

enum PaletteChartMode {
  table,
  scatter,
  line,
  bar,
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
  final ValueChanged<ManagedPaletteFile> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return _PanelFrame(
      title: '管理区',
      subtitle: '文件导入、文件收藏、已取色概要。',
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
    required this.colorBlindFriendlyPreview,
    required this.onColorBlindFriendlyChanged,
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
  final bool colorBlindFriendlyPreview;
  final ValueChanged<bool> onColorBlindFriendlyChanged;

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
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: colorBlindFriendlyPreview,
                    onChanged: onColorBlindFriendlyChanged,
                    title: const Text('色盲友好预览'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 190,
              child: _PaletteChartPreview(
                colors: file!.palette.colors,
                mode: chartMode,
                colorBlindFriendly: colorBlindFriendlyPreview,
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

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({
    required this.imageBytes,
    required this.profile,
    required this.onProfileChanged,
  });

  final Uint8List imageBytes;
  final ExtractionProfile profile;
  final ValueChanged<ExtractionProfile> onProfileChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = math.min(260.0, width * 0.72);

        return GestureDetector(
          onTapDown: profile.mode == ExtractionMode.eyeDropper
              ? (details) {
                  final nx = (details.localPosition.dx / width).clamp(0.0, 1.0);
                  final ny =
                      (details.localPosition.dy / height).clamp(0.0, 1.0);
                  onProfileChanged(
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
                Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
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
    required this.profile,
    required this.sourceKind,
    required this.hasSavedProfile,
    required this.isBusy,
    required this.onProfileChanged,
    required this.onReextractPressed,
    required this.onSaveProfilePressed,
    required this.onApplySavedProfilePressed,
  });

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
    return _SectionCard(
      title: '取色配置',
      child: Column(
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
      ),
    );
  }
}

class _PaletteChartPreview extends StatelessWidget {
  const _PaletteChartPreview({
    required this.colors,
    required this.mode,
    required this.colorBlindFriendly,
    required this.isSelected,
  });

  final List<ColorEntry> colors;
  final PaletteChartMode mode;
  final bool colorBlindFriendly;
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
            final visual = _previewColor(color.hexCode, colorBlindFriendly);
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
            colorBlindFriendly: colorBlindFriendly,
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
    required this.colorBlindFriendly,
    required this.isSelected,
  });

  final List<ColorEntry> colors;
  final PaletteChartMode mode;
  final bool colorBlindFriendly;
  final bool Function(ColorEntry color) isSelected;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = Colors.grey.shade500
      ..strokeWidth = 1;

    final leftPad = 20.0;
    final bottomPad = 16.0;
    final chartWidth = math.max(1.0, size.width - leftPad - 6);
    final chartHeight = math.max(1.0, size.height - bottomPad - 6);

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

    final points = <Offset>[];
    for (var i = 0; i < colors.length; i++) {
      final x = leftPad +
          (chartWidth * (colors.length == 1 ? 0.5 : i / (colors.length - 1)));
      final y =
          chartHeight - (_luminanceOfHex(colors[i].hexCode) * chartHeight);
      points.add(Offset(x, y));
    }

    if (mode == PaletteChartMode.bar) {
      final width = chartWidth / colors.length;
      for (var i = 0; i < points.length; i++) {
        final color = _previewColor(colors[i].hexCode, colorBlindFriendly);
        final selected = isSelected(colors[i]);
        final barPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        final stroke = Paint()
          ..color =
              selected ? Colors.black : Colors.black.withValues(alpha: 0.2)
          ..strokeWidth = selected ? 3 : 1
          ..style = PaintingStyle.stroke;
        final rect = Rect.fromLTWH(
          points[i].dx - (width * 0.35),
          points[i].dy,
          width * 0.7,
          chartHeight - points[i].dy,
        );
        canvas.drawRect(rect, barPaint);
        canvas.drawRect(rect, stroke);
      }
      return;
    }

    if (mode == PaletteChartMode.line) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    for (var i = 0; i < points.length; i++) {
      final color = _previewColor(colors[i].hexCode, colorBlindFriendly);
      final selected = isSelected(colors[i]);
      canvas.drawCircle(
        points[i],
        selected ? 6.5 : 4.5,
        Paint()..color = color,
      );
      canvas.drawCircle(
        points[i],
        selected ? 6.5 : 4.5,
        Paint()
          ..color =
              selected ? Colors.black : Colors.black.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 2.4 : 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PaletteChartPainter oldDelegate) {
    return oldDelegate.colors != colors ||
        oldDelegate.mode != mode ||
        oldDelegate.colorBlindFriendly != colorBlindFriendly;
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
    ExtractionMode.boxRange => '框选区域',
    ExtractionMode.eyeDropper => '取色器',
    ExtractionMode.cameraFrame => '相机画面',
  };
}

String _chartModeLabel(PaletteChartMode mode) {
  return switch (mode) {
    PaletteChartMode.table => '表格',
    PaletteChartMode.scatter => '散点图',
    PaletteChartMode.line => '折线图',
    PaletteChartMode.bar => '柱状图',
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

Color _previewColor(String hexCode, bool colorBlindFriendly) {
  final raw = _parseHexColor(hexCode);
  if (!colorBlindFriendly) {
    return raw;
  }

  final r = raw.r.toDouble();
  final g = raw.g.toDouble();
  final b = raw.b.toDouble();

  final nr = (0.625 * r + 0.375 * g).round().clamp(0, 255);
  final ng = (0.7 * r + 0.3 * g).round().clamp(0, 255);
  final nb = (0.3 * g + 0.7 * b).round().clamp(0, 255);
  return Color.fromARGB(255, nr, ng, nb);
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
