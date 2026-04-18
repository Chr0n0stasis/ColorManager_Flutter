class ColorEntry {
  ColorEntry({
    required this.name,
    required String hexCode,
  }) : hexCode = normalizeHex(hexCode);

  final String name;
  final String hexCode;

  List<int> get rgb {
    final value = hexCode.substring(1);
    return [
      int.parse(value.substring(0, 2), radix: 16),
      int.parse(value.substring(2, 4), radix: 16),
      int.parse(value.substring(4, 6), radix: 16),
    ];
  }

  static String normalizeHex(String value) {
    final raw = value.trim().replaceFirst('#', '');
    final expanded = raw.length == 3
        ? raw.split('').map((part) => '$part$part').join()
        : raw;

    if (expanded.length != 6) {
      throw FormatException('HEX color must contain exactly 6 digits.');
    }

    final parsed = int.tryParse(expanded, radix: 16);
    if (parsed == null) {
      throw FormatException('HEX color contains invalid characters.');
    }

    return '#${expanded.toUpperCase()}';
  }

  static String rgbToHex(int red, int green, int blue) {
    final values = [red, green, blue].map((value) => value.clamp(0, 255)).toList();
    return '#${values[0].toRadixString(16).padLeft(2, '0').toUpperCase()}${values[1].toRadixString(16).padLeft(2, '0').toUpperCase()}${values[2].toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }
}
