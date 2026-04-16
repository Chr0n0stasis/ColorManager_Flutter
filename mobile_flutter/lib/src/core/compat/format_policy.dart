enum PaletteFormat {
  ase,
  csv,
  gpl,
  image,
  json,
  pal,
  pdf,
}

const bool zeroNewFormatPolicyEnabled = true;

const Set<PaletteFormat> supportedInputFormats = <PaletteFormat>{
  PaletteFormat.ase,
  PaletteFormat.csv,
  PaletteFormat.gpl,
  PaletteFormat.image,
  PaletteFormat.json,
  PaletteFormat.pal,
  PaletteFormat.pdf,
};

const Set<PaletteFormat> supportedOutputFormats = <PaletteFormat>{
  PaletteFormat.ase,
  PaletteFormat.csv,
  PaletteFormat.json,
  PaletteFormat.pal,
};
