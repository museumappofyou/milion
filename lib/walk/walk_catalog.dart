import 'dart:convert';

import '../content/json_reader.dart';
import '../content/models.dart';
import '../content/registry.dart';
import '../content/repository.dart';
import 'walk.dart';

/// Walk manifests (P14), parsed once at start from `assets/walk/index.json`.
/// The model loads when a walk opens.
class WalkCatalog {
  const WalkCatalog.empty() : _walks = const {}, errors = const [];
  WalkCatalog._(Map<String, WalkManifest> walks, this.errors)
    : _walks = Map.unmodifiable(walks);
  final Map<String, WalkManifest> _walks;

  /// Walks rejected by a lenient load.
  final List<String> errors;
  Iterable<WalkManifest> get walks => _walks.values;
  WalkManifest? walk(String id) => _walks[id];
  static String manifestPath(String id) => 'assets/walk/$id/walk.json';
  static const indexPath = 'assets/walk/index.json';

  /// The walk a Milestone plays, by its manifest path, unless it is planned.
  WalkManifest? forMilestone(Milestone m) {
    final path = m.manifestPath;
    if (m.status == MilestoneStatus.planned || path == null) return null;
    for (final w in walks) {
      if (manifestPath(w.id) == path) return w;
    }
    return null;
  }

  Iterable<WalkManifest> forPlace(String placeId) =>
      walks.where((w) => w.placeId == placeId);

  static Future<WalkCatalog> load(
    ContentRegistry registry,
    LoadText loadText, {
    bool strict = true,
  }) async {
    final walks = <String, WalkManifest>{};
    final errors = <String>[];
    List<String> ids;
    try {
      ids = decode(
        jsonDecode(await loadText(indexPath)) as Map<String, dynamic>,
        (r) {
          if (r.integer('schemaVersion') != 1 || r.string('kind') != 'walks') {
            throw const FormatException(
              'assets/walk/index.json: not a walk index',
            );
          }
          return r.strings('walks');
        },
      );
    } on Object catch (e) {
      if (strict) rethrow;
      return WalkCatalog._(const {}, ['index: $e']);
    }
    for (final id in ids) {
      try {
        final walk = WalkManifest.fromJson(
          jsonDecode(await loadText(manifestPath(id))) as Map<String, dynamic>,
        );
        if (walk.id != id) throw FormatException('$id: manifest id mismatch');
        if (registry.place(walk.placeId) == null) {
          throw FormatException('$id: unknown place ${walk.placeId}');
        }
        if (registry.milestone(walk.milestoneId) == null) {
          throw FormatException('$id: unknown milestone ${walk.milestoneId}');
        }
        for (final source in walk.allSourceIds) {
          if (registry.source(source) == null) {
            throw FormatException('$id: unknown source $source');
          }
        }
        for (final stop in walk.stops) {
          if (stop.photo case final photo?
              when registry.mediaItem(photo) == null) {
            throw FormatException('$id: ${stop.id} names unknown media $photo');
          }
        }
        walks[id] = walk;
      } on Object catch (e) {
        if (strict) rethrow;
        errors.add('$id: $e');
      }
    }
    return WalkCatalog._(walks, errors);
  }
}
