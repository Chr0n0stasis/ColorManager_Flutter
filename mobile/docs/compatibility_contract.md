# Compatibility Contract (Mobile Migration)

## Scope
- Keep input formats compatible with desktop: JSON, CSV, ASE, GPL, PAL, image files, PDF.
- Keep output formats compatible with desktop: JSON, CSV, ASE, PAL.
- Prefer zero new file formats. Do not add custom exchange formats unless explicitly approved.

## Required Compatibility Rules
- JSON output keeps the same shape as desktop export:
  - root keys: name, colors
  - color item keys: name, hex
- CSV output keeps header: name,hex
- No silent default drift:
  - color order preserved
  - hex values normalized to uppercase #RRGGBB
- Binary outputs (ASE/PAL) must preserve structural compatibility with desktop readers.

## Layout Fidelity Rules
- Preserve original anchor semantics:
  - Left: materials/library browsing and filtering
  - Center: detail preview and extraction
  - Right: compose cart and chart preview
- Responsive adaptation is allowed, but semantic relocation is not.

## Android Permission Rules
- SAF tree URI first for Documents/ColorManager.
- No MANAGE_EXTERNAL_STORAGE.
- No broad media/storage permission as default blocker.

## iOS Signing Rules
- Core flow is signing-agnostic.
- External PDF import must work without iCloud container dependency.
- Default external import mode copies files into sandbox workspace.
