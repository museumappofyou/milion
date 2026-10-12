import 'dart:convert';

import '../content/registry.dart';
import '../content/repository.dart';
import '../content/models.dart';
import 'manifest.dart';

/// Parsed manifests keyed by their declared Milestone; no artwork-id routing.
class PlateCatalog {
  const PlateCatalog.empty() : _plates = const {}, errors = const [];
  PlateCatalog._(Map<String, PlateManifest> plates, this.errors)
    : _plates = Map.unmodifiable(plates);
  final Map<String, PlateManifest> _plates;

  /// Plates rejected by a lenient load; the app keeps every other plate.
  final List<String> errors;
  Iterable<PlateManifest> get plates => _plates.values;
  PlateManifest? forMilestone(Milestone m) =>
      m.status == MilestoneStatus.planned ? null : _plates[m.id];

  /// [strict] (the validator CLI) throws on the first bad plate. The app loads
  /// leniently: one stale manifest removes that Milestone's plate, not the app.
  static Future<PlateCatalog> load(
    ContentRegistry registry,
    LoadText loadText, {
    bool strict = true,
  }) async {
    final plates = <String, PlateManifest>{};
    final errors = <String>[];
    for (final m in registry.milestones) {
      final path = m.manifestPath;
      if (m.status == MilestoneStatus.planned ||
          path == null ||
          !path.startsWith('assets/plates/')) {
        continue;
      }
      try {
        plates[m.id] = _check(
          registry,
          m,
          path,
          PlateManifest.fromJson(
            jsonDecode(await loadText(path)) as Map<String, dynamic>,
          ),
        );
      } on Object catch (e) {
        if (strict) rethrow;
        errors.add('${m.id}: $e');
      }
    }
    return PlateCatalog._(plates, errors);
  }

  static PlateManifest _check(
    ContentRegistry registry,
    Milestone m,
    String path,
    PlateManifest p,
  ) {
    if (p.milestoneId != m.id ||
        p.manifestPath != path ||
        !m.artworkIds.contains(p.artworkId)) {
      throw FormatException('${m.id}: plate ownership/path mismatch');
    }
    for (final id in {
      ...p.sourceIds,
      ...p.details.expand((d) => d.sourceIds),
      ...p.beats.expand((b) => b.sourceIds),
      ...p.reveal.sourceIds,
    }) {
      if (registry.source(id) == null) {
        throw FormatException('${p.id}: unknown source $id');
      }
    }
    for (final d in p.details) {
      final master = registry.details
          .where((record) => record.id == d.id)
          .firstOrNull;
      if (master == null ||
          master.anchorX != d.anchorX ||
          master.anchorY != d.anchorY ||
          master.window.left != d.window.left ||
          master.window.top != d.window.top ||
          master.window.right != d.window.right ||
          master.window.bottom != d.window.bottom ||
          master.sentence.en != d.sentence.en ||
          master.sentence.tr != d.sentence.tr) {
        throw FormatException('${d.id}: plate detail differs from Today');
      }
    }
    for (final s in p.citations) {
      if (registry.source(s.id)?.url != s.url) {
        throw FormatException('${s.id}: stale plate citation');
      }
    }
    return p;
  }
}
