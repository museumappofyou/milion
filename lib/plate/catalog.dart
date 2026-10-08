import 'dart:convert';

import '../content/registry.dart';
import '../content/repository.dart';
import '../content/models.dart';
import 'manifest.dart';

/// Parsed manifests keyed by their declared Milestone; no artwork-id routing.
class PlateCatalog {
  const PlateCatalog.empty() : _plates = const {};
  PlateCatalog._(Map<String, PlateManifest> plates)
    : _plates = Map.unmodifiable(plates);
  final Map<String, PlateManifest> _plates;
  Iterable<PlateManifest> get plates => _plates.values;
  PlateManifest? forMilestone(Milestone m) =>
      m.status == MilestoneStatus.planned ? null : _plates[m.id];

  static Future<PlateCatalog> load(
    ContentRegistry registry,
    LoadText loadText,
  ) async {
    final plates = <String, PlateManifest>{};
    for (final m in registry.milestones) {
      final path = m.manifestPath;
      if (m.status == MilestoneStatus.planned ||
          path == null ||
          !path.startsWith('assets/plates/')) {
        continue;
      }
      final p = PlateManifest.fromJson(
        jsonDecode(await loadText(path)) as Map<String, dynamic>,
      );
      if (p.milestoneId != m.id ||
          p.manifestPath != path ||
          !m.artworkIds.contains(p.artworkId)) {
        throw FormatException('${m.id}: plate ownership/path mismatch');
      }
      for (final id in {
        ...p.sourceIds,
        ...p.details.expand((d) => d.sourceIds),
        ...p.beats.expand((b) => b.sourceIds),
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
      plates[m.id] = p;
    }
    return PlateCatalog._(plates);
  }
}
