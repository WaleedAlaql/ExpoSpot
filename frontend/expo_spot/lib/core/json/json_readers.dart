/// Shared JSON coercion matching Spring/Jackson payloads (int, long, double, ISO-8601).
abstract final class JsonReaders {
  static int? intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static int intValue(dynamic value, {int fallback = 0}) {
    return intOrNull(value) ?? fallback;
  }

  static double? doubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static double doubleValue(dynamic value, {double fallback = 0}) {
    return doubleOrNull(value) ?? fallback;
  }

  static bool boolValue(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  static String? stringOrNull(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static String stringValue(dynamic value, {String fallback = ''}) {
    return stringOrNull(value) ?? fallback;
  }

  static DateTime? dateTimeOrNull(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static List<T> listOf<T>(
    dynamic value,
    T Function(Map<String, dynamic> json) map,
  ) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => map(Map<String, dynamic>.from(e)))
        .toList();
  }
}
