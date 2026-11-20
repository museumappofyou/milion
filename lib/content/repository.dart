import 'dart:convert';

import 'json_reader.dart';
import 'registry.dart';

typedef LoadText = Future<String> Function(String path);

/// Inject rootBundle.loadString in Flutter, File.readAsString in the CLI/tests.
/// No Flutter, classifier or ONNX dependency is needed to load content.
class ContentRepository {
  ContentRepository(this.loadText);
  final LoadText loadText;
  Future<ContentRegistry>? _loading;

  Future<ContentRegistry> load() => _loading ??= _load();
  Future<ContentRegistry> _load() async {
    try {
      return ContentRegistry.fromJson(await readContent(loadText));
    } catch (_) {
      _loading = null;
      rethrow;
    }
  }
}

Future<Json> readContent(
  LoadText loadText, {
  String indexPath = 'assets/content/index.json',
}) async {
  final index = jsonDecode(await loadText(indexPath)) as Json;
  if (index['schemaVersion'] is! int ||
      index['schemaVersion'] != contentSchemaVersion) {
    throw FormatException(
      'Unsupported schemaVersion: ${index['schemaVersion']}',
    );
  }
  final files = index['files'];
  if (files is! Json ||
      index.keys.any((k) => !['schemaVersion', 'files'].contains(k)) ||
      files.keys.any((k) => !recordKinds.contains(k))) {
    throw const FormatException('Invalid content index');
  }
  final data = <String, dynamic>{'schemaVersion': contentSchemaVersion};
  final seen = <String>{};
  final wanted = <(String, String)>[];
  for (final kind in recordKinds) {
    final paths = files[kind];
    if (paths is! List) throw FormatException('Missing index files for $kind');
    for (final path in paths) {
      if (path is! String ||
          !safeAssetPath(path) ||
          !path.startsWith('assets/content/') ||
          !seen.add(path)) {
        throw FormatException('Unsafe or duplicate content path: $path');
      }
      wanted.add((kind, path));
    }
  }
  // Every file is requested at once and read in index order (P15: one at a
  // time, startup grew with each chapter's files). A failed read is held
  // until its turn, so the first failure in index order is the one thrown.
  final texts = [
    for (final (_, path) in wanted)
      loadText(path).then<(String?, Object?, StackTrace?)>(
        (text) => (text, null, null),
        onError: (Object e, StackTrace s) => (null, e, s),
      ),
  ];
  for (final kind in recordKinds) {
    data[kind] = <dynamic>[];
  }
  for (var i = 0; i < wanted.length; i++) {
    final (kind, path) = wanted[i];
    final (text, error, stack) = await texts[i];
    if (error != null) Error.throwWithStackTrace(error, stack!);
    final document = jsonDecode(text!) as Json;
    if (document['schemaVersion'] is! int ||
        document['schemaVersion'] != contentSchemaVersion ||
        document['kind'] != kind ||
        document['records'] is! List ||
        document.keys.any(
          (k) => !['schemaVersion', 'kind', 'records'].contains(k),
        )) {
      throw FormatException('Invalid versioned $kind document: $path');
    }
    (data[kind] as List).addAll(document['records'] as List);
  }
  return data;
}
