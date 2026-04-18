# ColorManager Mobile

This folder is the active Flutter mobile migration workspace.

## Implemented

- Responsive three-zone shell aligned with desktop semantics:
  - Materials (left)
  - Detail and picking (center)
  - Cart and preview (right)
- Interactive workflow in UI:
  - file import and palette list/search
  - color selection and cart management
  - export from cart to `JSON`, `CSV`, `ASE`, `PAL`
- Compatibility core:
  - domain models (`ColorEntry`, `Palette`)
  - codecs for `JSON`, `CSV`, `GPL`, `ASE`, `PAL`
  - extension-based codec router (no new custom format)
- Image/PDF extraction path:
  - image dominant-color sampling
  - PDF first-page raster and dominant-color sampling
- Platform contracts:
  - Android least-privilege policy (SAF-first)
  - iOS signing-agnostic file policy (sandbox-copy first)
- Tests:
  - compatibility codec tests
  - layout contract tests
  - platform policy tests
  - image sampler tests

## Notes

- Export files are written to app container documents directory:
  - `.../Documents/ColorManager/exports/`
- Input/output compatibility remains the top priority.

## Upstream Attribution / 上游署名与协议

- Upstream author: `Alsophila`
- License policy: `PolyForm Noncommercial 1.0.0`
- Anti-resale statement is preserved in app status watermark rotation.
- JSON/CSV/ASE exports keep upstream source tracing suffix: `_free_by_a`.

对应上游 Ver `1.0.1` 诉求：

- 保留防倒卖与退款提醒。
- 保留非商用许可声明。
- 导出溯源在 `ASE`、`JSON`、`CSV` 中自动写入开发者标识后缀。

## Run

```bash
flutter pub get
flutter test
flutter run
```
