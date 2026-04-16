import 'dart:convert';

String encodeJsonWithAscii(Object? value, {bool pretty = true}) {
  final encoded = pretty
      ? const JsonEncoder.withIndent('  ').convert(value)
      : jsonEncode(value);
  return _escapeNonAscii(encoded);
}

String _escapeNonAscii(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    if (rune <= 0x7F) {
      buffer.writeCharCode(rune);
      continue;
    }
    if (rune <= 0xFFFF) {
      buffer.write(_toUnicodeEscape(rune));
      continue;
    }
    final scalar = rune - 0x10000;
    final highSurrogate = 0xD800 + (scalar >> 10);
    final lowSurrogate = 0xDC00 + (scalar & 0x3FF);
    buffer
      ..write(_toUnicodeEscape(highSurrogate))
      ..write(_toUnicodeEscape(lowSurrogate));
  }
  return buffer.toString();
}

String _toUnicodeEscape(int value) {
  return '\\u${value.toRadixString(16).padLeft(4, '0').toUpperCase()}';
}
