import 'package:flutter/widgets.dart';

import '../content/models.dart';
import '../content/registry.dart';
import '../plate/catalog.dart';
import '../space/catalog.dart';
import '../space/study.dart';
import '../section/section.dart';
import '../siege/siege.dart';
import '../walls/wall_strip.dart';
import '../walk/walk_catalog.dart';

/// What kind of interactive experience a playable Milestone launches.
enum PlayableKind { plate, space, walk, section, strip, map }

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
    this.strips = const WallStripCatalog.empty(),
    this.sieges = const SiegeCatalog.empty(),
    required super.child,
  });
  final ContentRegistry? registry;
  final PlateCatalog plates;
  final SpaceCatalog spaces;

  /// Immersive walks (P14: XVI, the Basilica Cistern).
  final WalkCatalog walks;

  /// Drawn excavation sections (P14: XVII, the harbour under the metro).
  final SectionCatalog sections;

  /// Walls drawn as one strip (P15: XVIII, the land walls).
  final WallStripCatalog strips;

  /// Map sequences over the Atlas (P15: XIX, 1453 in 53 days).
  final SiegeCatalog sieges;
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

  /// What kind of interactive engine a Milestone launches, or null when planned.
  PlayableKind? playableKind(Milestone m) {
    if (plates.forMilestone(m) != null) return PlayableKind.plate;
    if (walks.forMilestone(m) != null) return PlayableKind.walk;
    if (sections.forMilestone(m) != null) return PlayableKind.section;
    if (strips.forMilestone(m) != null) return PlayableKind.strip;
    if (sieges.forMilestone(m) != null) return PlayableKind.map;
    if (studyFor(m) != null) return PlayableKind.space;
    return null;
  }

  /// A Milestone plays when it has a plate, a 3D study, a walk, a section, a
  /// strip or a map sequence.
  bool playable(Milestone m) => playableKind(m) != null;

  /// Every bundled 3D study that is not already opened by a playable Milestone
  /// (e.g. Şehzade, Little Hagia Sophia, Bodrum Mosque, How a dome stands).
  List<SpaceStudy> get standaloneStudies {
    final milestonePaths = {
      for (final m in registry?.register ?? const <Milestone>[])
        if (m.status != MilestoneStatus.planned && m.manifestPath != null)
          m.manifestPath!,
    };
    final list = [
      for (final s in spaces.studies)
        if (!milestonePaths.contains(SpaceCatalog.manifestPath(s.id))) s,
    ];
    // Place-bound monuments first, then structural comparison studies.
    list.sort((a, b) {
      final aHasPlace = a.placeId != null ? 0 : 1;
      final bHasPlace = b.placeId != null ? 0 : 1;
      if (aHasPlace != bHasPlace) return aHasPlace.compareTo(bHasPlace);
      return a.id.compareTo(b.id);
    });
    return list;
  }

  /// Every 3D study associated with [place], whether linked by `study.placeId`
  /// or cited inside one of the place's historical strata.
  List<SpaceStudy> studiesForPlace(Place place) {
    final seen = <String>{};
    final out = <SpaceStudy>[];
    for (final s in spaces.forPlace(place.id)) {
      if (seen.add(s.id)) out.add(s);
    }
    for (final stratum in place.strata) {
      for (final id in stratum.studyIds) {
        final s = spaces.study(id);
        if (s != null && seen.add(s.id)) out.add(s);
      }
    }
    return out;
  }

  /// Playable Milestones that belong to [place].
  List<Milestone> playableMilestonesForPlace(Place place) => [
    for (final m in registry?.register ?? const <Milestone>[])
      if (m.placeIds.contains(place.id) && playable(m)) m,
  ];

  /// Place ids that host at least one playable Milestone, 3D study, or
  /// interactive floor-plan guide.
  Set<String> get interactivePlaceIds {
    final reg = registry;
    if (reg == null) return const {};
    return {
      for (final m in reg.register)
        if (playable(m)) ...m.placeIds,
      for (final s in spaces.studies)
        if (s.placeId != null) s.placeId!,
      for (final p in reg.places)
        if (reg.guideFor(p.id) != null ||
            p.strata.any(
              (st) => st.studyIds.any((id) => spaces.study(id) != null),
            ))
          p.id,
    };
  }

  bool hasInteractive(Place place) =>
      playableMilestonesForPlace(place).isNotEmpty ||
      studiesForPlace(place).isNotEmpty ||
      registry?.guideFor(place.id) != null;
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
      strips != old.strips ||
      sieges != old.sieges ||
      error != old.error ||
      recognised != old.recognised ||
      clock != old.clock;
}
