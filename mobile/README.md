# ColorManager Mobile (Implementation Start)

This folder contains the first implementation slice of the mobile migration.

## What is implemented
- Flutter app skeleton with responsive layout shell.
- Layout anchor mapping aligned with the desktop structure.
- Core domain models: ColorEntry and Palette.
- Initial compatibility codecs: JSON and CSV.
- Platform file access policies capturing Android least-privilege and iOS signing-agnostic constraints.

## Immediate next steps
- Add ASE and PAL binary codecs.
- Add PDF and image palette extraction pipeline.
- Connect Android SAF and iOS Document Picker channels.
- Replace shell placeholders with real feature modules.
