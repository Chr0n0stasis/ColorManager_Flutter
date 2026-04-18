enum PaletteFormat {
  ase,
  cpt,
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
  PaletteFormat.cpt,
  PaletteFormat.csv,
  PaletteFormat.gpl,
  PaletteFormat.image,
  PaletteFormat.json,
  PaletteFormat.pal,
  PaletteFormat.pdf,
};

const Set<PaletteFormat> supportedOutputFormats = <PaletteFormat>{
  PaletteFormat.ase,
  PaletteFormat.cpt,
  PaletteFormat.csv,
  PaletteFormat.gpl,
  PaletteFormat.json,
  PaletteFormat.pal,
};
