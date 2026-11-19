import 'package:flutter/widgets.dart';

import '../content/models.dart';
import '../content/registry.dart';
import '../plate/catalog.dart';
import '../space/catalog.dart';
import '../space/study.dart';
import '../section/section.dart';
import '../walk/walk_catalog.dart';

/// Content, clock and recognition coverage loaded once at start.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.registry,
    required this.error,
    required this.retry,
    required this.clock,
    required this.recognised,
    this.plates = const PlateCatalog.empty(),
    this.spaces = const SpaceCatalog.empty(),
    this.walks = const WalkCatalog.empty(),
    this.sections = const SectionCatalog.empty(),
    required super.child,
  });
  final ContentRegistry? registry;
  final PlateCatalog plates;
  final SpaceCatalog spaces;

  /// Immersive walks (P14: XVI, the Basilica Cistern).
  final WalkCatalog walks;

  /// Drawn excavation sections (P14: XVII, the harbour under the metro).
  final SectionCatalog sections;
  final Object? error;
  final VoidCallback retry;
  final DateTime Function() clock;

  /// Artwork ids the on-device classifier can suggest (assets/model/classes.json).
  final Set<String> recognised;

  bool artworkRecognised(String artworkId) => recognised.contains(artworkId);

  /// The 3D study a Milestone plays (P11: VI, Chora through time), when it
  /// is not planned and its manifest is a loaded study.
  SpaceStudy? studyFor(Milestone m) {
    final path = m.manifestPath;
    if (m.status == MilestoneStatus.planned || path == null) return null;
    for (final s in spaces.studies) {
      if (SpaceCatalog.manifestPath(s.id) == path) return s;
    }
    return null;
  }

  /// A Milestone plays when it has a plate, a 3D study, a walk or a section.
  bool playable(Milestone m) =>
      plates.forMilestone(m) != null ||
      studyFor(m) != null ||
      walks.forMilestone(m) != null ||
      sections.forMilestone(m) != null;
  bool placeRecognised(String placeId) =>
      registry?.artworks.any(
        (a) => a.placeId == placeId && recognised.contains(a.id),
      ) ??
      false;

  static AppScope of(BuildContext context) => maybeOf(context)!;

  /// Null outside the app (a debug screen pumped on its own in a test).
  static AppScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>();

  @override
  bool updateShouldNotify(AppScope old) =>
      registry != old.registry ||
      plates != old.plates ||
      spaces != old.spaces ||
      walks != old.walks ||
      sections != old.sections ||
      error != old.error ||
      recognised != old.recognised ||
      clock != old.clock;
}
