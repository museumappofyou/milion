import 'dart:convert';

import '../content/json_reader.dart';
import '../content/registry.dart';
import '../content/repository.dart';
import 'study.dart';

/// Study manifests, parsed once at start: every study the bundle lists in
/// `assets/space/index.json` and any a place layer names (`studies` on a
/// stratum). The model itself loads when a study opens.
class SpaceCatalog {
  const SpaceCatalog.empty() : _studies = const {}, errors = const [];
  SpaceCatalog._(Map<String, SpaceStudy> studies, this.errors)
    : _studies = Map.unmodifiable(studies);
  final Map<String, SpaceStudy> _studies;

  /// Studies rejected by a lenient load; their rows are not shown.
  final List<String> errors;
  Iterable<SpaceStudy> get studies => _studies.values;
  SpaceStudy? study(String id) => _studies[id];
  static String manifestPath(String id) => 'assets/space/$id/study.json';
  static const indexPath = 'assets/space/index.json';

  /// Studies by the place they draw (kit studies; P08's has no place).
  Iterable<SpaceStudy> forPlace(String placeId) =>
      studies.where((s) => s.placeId == placeId);

  static Future<SpaceCatalog> load(
    ContentRegistry registry,
    LoadText loadText, {
    bool strict = true,
  }) async {
    final studies = <String, SpaceStudy>{};
    final errors = <String>[];
    final listed = decode(
      jsonDecode(await loadText(indexPath)) as Map<String, dynamic>,
      (r) {
        if (r.integer('schemaVersion') != 1 || r.string('kind') != 'spaces') {
          throw const FormatException(
            'assets/space/index.json: not a study index',
          );
        }
        return r.strings('studies');
      },
    );
    final ids = {
      ...listed,
      for (final p in registry.places)
        for (final s in p.strata) ...s.studyIds,
    };
    for (final id in ids) {
      try {
        final study = SpaceStudy.fromJson(
          jsonDecode(await loadText(manifestPath(id))) as Map<String, dynamic>,
        );
        if (study.id != id) throw FormatException('$id: manifest id mismatch');
        final place = study.placeId;
        if (place != null && registry.place(place) == null) {
          throw FormatException('$id: unknown place $place');
        }
        for (final source in {
          ...study.sourceIds,
          ...study.steps.expand((s) => s.sourceIds),
        }) {
          if (registry.source(source) == null) {
            throw FormatException('$id: unknown source $source');
          }
        }
        for (final c in study.citations) {
          if (registry.source(c.id)?.url != c.url) {
            throw FormatException('${c.id}: stale study citation');
          }
        }
        studies[id] = study;
      } on Object catch (e) {
        if (strict) rethrow;
        errors.add('$id: $e');
      }
    }
    return SpaceCatalog._(studies, errors);
  }
}
