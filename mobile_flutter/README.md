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

- Export files are written to a temporary folder under system temp:
  - `.../color_manager_exports/`
- Input/output compatibility remains the top priority.

## Run

```bash
flutter pub get
flutter test
flutter run
```
