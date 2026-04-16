String normalizeHex(String value) {
  final trimmed = value.trim().replaceFirst('#', '');
  final normalized = trimmed.length == 3
      ? trimmed.split('').map((ch) => '$ch$ch').join()
      : trimmed;
  if (normalized.length != 6) {
    throw FormatException('Invalid hex color: $value');
  }
  final parsed = int.tryParse(normalized, radix: 16);
  if (parsed == null) {
    throw FormatException('Invalid hex color: $value');
  }
  return '#${normalized.toUpperCase()}';
}

String rgbToHex(int red, int green, int blue) {
  return '#${_toHex2(red)}${_toHex2(green)}${_toHex2(blue)}';
}

int clampChannel(num value) {
  if (value < 0) {
    return 0;
  }
  if (value > 255) {
    return 255;
  }
  return value.round();
}

String _toHex2(int value) {
  final clamped = clampChannel(value);
  return clamped.toRadixString(16).padLeft(2, '0').toUpperCase();
}
