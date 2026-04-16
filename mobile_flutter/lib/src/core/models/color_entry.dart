import '../compat/hex_utils.dart';

class ColorEntry {
  ColorEntry({
    required this.name,
    required String hexCode,
  }) : hexCode = normalizeHex(hexCode);

  final String name;
  final String hexCode;

  List<int> get rgb {
    final value = hexCode.replaceFirst('#', '');
    final normalized = value.length == 3
        ? value.split('').map((ch) => '$ch$ch').join()
        : value;
    return [
      int.parse(normalized.substring(0, 2), radix: 16),
      int.parse(normalized.substring(2, 4), radix: 16),
      int.parse(normalized.substring(4, 6), radix: 16),
    ];
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'hex': hexCode,
    };
  }
}
