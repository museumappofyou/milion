typedef Json = Map<String, dynamic>;

T decode<T>(Json json, T Function(JsonReader) build) {
  final reader = JsonReader(json);
  final result = build(reader);
  reader.finish();
  return result;
}

/// A small strict decoder shared by the app and the standalone Dart CLI.
class JsonReader {
  JsonReader(this.json);
  final Json json;
  final Set<String> _read = {};

  dynamic value(String key) {
    _read.add(key);
    if (!json.containsKey(key)) throw FormatException('Missing $key');
    return json[key];
  }

  String string(String key, {bool empty = false}) {
    final v = value(key);
    if (v is! String || (!empty && v.trim().isEmpty)) {
      throw FormatException(
        '$key must be a ${empty ? "" : "non-empty "}string',
      );
    }
    return v;
  }

  String? nullableString(String key) {
    if (value(key) == null) return null;
    return string(key);
  }

  bool boolean(String key) {
    final v = value(key);
    if (v is! bool) throw FormatException('$key must be boolean');
    return v;
  }

  int integer(String key) {
    final v = value(key);
    if (v is! int) throw FormatException('$key must be an integer');
    return v;
  }

  int? nullableInteger(String key) => value(key) == null ? null : integer(key);

  double number(String key) {
    final v = value(key);
    if (v is! num || !v.isFinite) throw FormatException('$key must be finite');
    return v.toDouble();
  }

  Json object(String key) {
    final v = value(key);
    if (v is! Json) throw FormatException('$key must be an object');
    return v;
  }

  List<T> list<T>(String key, T Function(dynamic) parse) {
    final v = value(key);
    if (v is! List) throw FormatException('$key must be a list');
    return List.unmodifiable(v.map(parse));
  }

  List<String> strings(String key) => list(key, (v) {
    if (v is! String || v.trim().isEmpty) {
      throw FormatException('$key must contain non-empty strings');
    }
    return v;
  });

  T enumeration<T extends Enum>(String key, List<T> values) {
    final name = string(key);
    for (final item in values) {
      if (item.name == name) return item;
    }
    throw FormatException('Unknown $key: $name');
  }

  DateTime? date(String key, {bool nullable = false}) {
    if (value(key) == null && nullable) return null;
    final s = string(key);
    final date = DateTime.tryParse(s);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s) ||
        date == null ||
        date.toIso8601String().substring(0, 10) != s) {
      throw FormatException('Invalid $key date: $s');
    }
    return date;
  }

  void finish() {
    final unknown = json.keys.toSet().difference(_read);
    if (unknown.isNotEmpty) throw FormatException('Unknown fields: $unknown');
  }
}
