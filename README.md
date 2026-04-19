# ColorManager / 色卡管理器

ColorManager is a local toolset for collecting, previewing, organizing, generating, and exporting scientific color palettes.

色卡管理器是一个面向科研绘图场景的本地工具集，用于整理、预览、生成、检查和导出色卡。

## Overview / 项目定位

This repository contains two implementation tracks for the same palette workflow:

本仓库包含同一配色工作流的两条实现线：

- Desktop source implementation (`Python + PySide6`) under `app/`
- Cross-platform client implementation (`Flutter`) under `mobile_flutter/`

- 桌面原始实现（`Python + PySide6`），位于 `app/`
- 跨平台客户端实现（`Flutter`），位于 `mobile_flutter/`

The shared goal is practical scientific plotting support:

共同目标是服务科研绘图中的实际配色流程：

- manage palette assets visually, not by filename only
- extract colors from palette files, images, and PDF pages
- organize a working palette in a cart-like area
- preview palette behavior in common chart styles
- export to reusable scientific workflows

- 以可视化方式管理配色素材，而不只依赖文件名
- 从色卡文件、图片、PDF 页面提取颜色
- 在导出区拼配和整理工作色卡
- 在常见图表样式中预览配色表现
- 导出到可复用的科研工作流

## Highlights / 功能速览

| Area | What it supports |
| --- | --- |
| Palette sources | `ASE`, `CSV`, `JSON`, `GPL`, `PAL`, images, `PDF` |
| Browsing | search, filtering, favorites, structured list |
| Extraction | image sampling, region pick, PDF page extraction |
| Editing | cart management, sorting, manual edit, generated colors |
| Generation | `Two-Color Gradient`, `Heatmap`, `Analogous`, `Complementary`, `To White` |
| Preview | `Line`, `Bar`, `Scatter`, `Clustered`, `Circular`, `Map` |
| Accessibility check | `Normal`, `Colorblind`, `Grayscale` |
| Export | `ASE`, `CSV`, `JSON`, `PAL`, `R`, `Python`, `MATLAB` snippets |

| 模块 | 支持内容 |
| --- | --- |
| 色卡来源 | `ASE`、`CSV`、`JSON`、`GPL`、`PAL`、图片、`PDF` |
| 浏览能力 | 搜索、筛选、收藏、结构化列表 |
| 取色方式 | 图片采样、区域框选、PDF 页面提取 |
| 编辑能力 | 导出区管理、排序、手动编辑、生成颜色 |
| 生成模式 | `双色渐变`、`热图配色`、`邻近色`、`互补色`、`向白过渡` |
| 预览图形 | `Line`、`Bar`、`Scatter`、`Clustered`、`Circular`、`Map` |
| 可读性检查 | `Normal`、`Colorblind`、`Grayscale` |
| 导出能力 | `ASE`、`CSV`、`JSON`、`PAL`、`R`、`Python`、`MATLAB` 代码片段 |

## Main Features / 主要功能

- Import and parse multiple palette formats with compatibility-first behavior
- Extract colors from image and PDF sources for real-world figure workflows
- Build and edit export-ready color collections with list operations
- Generate palette variants from selected base colors
- Preview color effects before export in chart-oriented scenes
- Export standard palette files and code snippets for downstream tools

- 兼容优先地导入和解析多种色卡格式
- 针对真实图件流程，从图片与 PDF 素材中提取颜色
- 通过导出区列表操作整理可输出的颜色集合
- 基于基色生成多种配色变体
- 在图表导向场景中提前检查颜色效果
- 导出标准色卡文件与下游工具可用代码片段

## Repository Structure / 仓库结构

```text
ColorManager/
├─ app/                           # Python desktop source implementation
│  ├─ assets/
│  ├─ main.py
│  ├─ config.py
│  ├─ models.py
│  ├─ parsers.py
│  ├─ storage.py
│  └─ ui/
│     ├─ main_window.py
│     └─ pdf_dialog.py
├─ mobile_flutter/                # Flutter cross-platform client implementation
│  ├─ lib/
│  ├─ assets/
│  ├─ test/
│  └─ pubspec.yaml
├─ .github/workflows/
│  └─ mobile_flutter_apk.yml      # mobile + desktop build pipeline
├─ build_exe.py                   # desktop packaging helper
├─ icon.ico                       # repository-level icon source
├─ LICENSE
└─ README.md
```

## Runtime & Build / 运行与构建

### Desktop Source (Python) / 桌面源码版（Python）

Recommended environment:

建议环境：

- Python 3.11+
- `PySide6`

Run from repository root:

在仓库根目录运行：

```bash
python -m app.main
```

### Flutter Client / Flutter 客户端

Recommended environment:

建议环境：

- Flutter stable (Dart SDK compatible with `pubspec.yaml`)

Run from `mobile_flutter/`:

在 `mobile_flutter/` 目录运行：

```bash
flutter pub get
flutter test
flutter run
```

## Packaging & CI / 打包与 CI

The workflow `.github/workflows/mobile_flutter_apk.yml` builds artifacts for:

`.github/workflows/mobile_flutter_apk.yml` 会构建以下产物：

- Android APK
- Android AAB
- iOS unsigned IPA
- Windows desktop package
- Linux desktop package
- macOS desktop package

## Icon Notes / 图标说明

- Repository icon source: `icon.ico`
- Flutter icon input: `mobile_flutter/assets/icons/app_icon.png`
- Mobile and desktop icon generation in CI is handled from Flutter icon configs.

- 仓库图标源文件：`icon.ico`
- Flutter 图标输入文件：`mobile_flutter/assets/icons/app_icon.png`
- CI 中的移动端与桌面端图标通过 Flutter 图标配置统一生成。

## Map Note / 地图说明

The China map used in preview is a simplified display asset. For presentation purpose, the preview does not include the nine-dash line.

预览中使用的中国地图为简化展示素材。出于展示目的，当前预览未显示九段线。

## Typical Workflow / 典型使用流程

1. Import palette files, images, or PDF sources.
2. Browse and select useful palettes/colors.
3. Add colors into export cart and adjust order.
4. Generate supporting colors when needed.
5. Preview in chart scenes and accessibility modes.
6. Export to files or code snippets.

1. 导入色卡文件、图片或 PDF 素材。
2. 浏览并选择需要的色卡与颜色。
3. 将颜色加入导出区并调整顺序。
4. 按需生成补充配色。
5. 在图表场景与可读性模式下检查效果。
6. 导出为文件或代码片段。

## Attribution / 署名保留

- Upstream author: `Alsophila`
- This repository keeps upstream attribution and non-commercial policy.
- Do not repackage for resale or commercial traffic diversion.

- 上游作者：`Alsophila`
- 本仓库保留上游署名与非商用约束。
- 禁止拆解功能用于倒卖或商业引流分发。

## License / 许可

This project is intended for personal, educational, and research non-commercial use.
Commercial use requires explicit permission from the author.

本项目面向个人、学习、科研等非商业用途。
任何商业使用需事先获得作者明确许可。

License file:

许可文件：

- `PolyForm Noncommercial 1.0.0`
- see [LICENSE](LICENSE)
