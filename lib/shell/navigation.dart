import 'package:flutter/material.dart';

import '../city/place_screen.dart';
import '../content/models.dart';
import '../milestones/milestone_sheet.dart';
import '../models/explorable_scene.dart';
import '../screens/artworks_tab.dart';
import '../screens/about_tab.dart';
import '../screens/scan_screen.dart';
import '../screens/scene_explorer_screen.dart';
import '../services/progress_service.dart';
import 'app_scope.dart';

/// The two P01 explorers; P06 replaces this with manifest-driven plates.
ExplorableScene? explorerFor(Milestone m) => m.status == MilestoneStatus.planned
    ? null
    : m.artworkIds.contains('F02')
    ? ExplorableScene.anastasis
    : m.artworkIds.contains('F05')
    ? ExplorableScene.judgment
    : null;

Future<T?> _push<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

Future<void> openMilestone(
  BuildContext context,
  Milestone milestone, {
  Detail? detail,
}) async {
  final scene = explorerFor(milestone);
  if (scene == null) return showMilestoneSheet(context, milestone);
  ProgressScope.of(context).open(milestone.id);
  await _push<void>(
    context,
    SceneExplorerScreen(scene: scene, initialDetail: detail),
  );
}

Future<void> openPlace(BuildContext context, Place place) =>
    _push<void>(context, PlaceScreen(place: place));

Future<void> openScan(BuildContext context) =>
    _push<void>(context, const ScanScreen());

Future<void> openAbout(BuildContext context) =>
    _push<void>(context, const AboutTab());

Future<void> openArtworks(BuildContext context, String placeId) {
  final app = AppScope.of(context);
  final registry = app.registry!;
  final milestones = {
    for (final m in registry.milestones)
      for (final a in m.artworkIds)
        if (explorerFor(m) != null) a: m,
  };
  void explore(String artworkId) =>
      openMilestone(context, milestones[artworkId]!);
  return _push<void>(
    context,
    ArtworksTab(
      artworks: [
        for (final a in registry.artworks)
          if (a.placeId == placeId) a,
      ],
      onExamineAnastasis: milestones.containsKey('F02')
          ? () => explore('F02')
          : null,
      onExamineLastJudgment: milestones.containsKey('F05')
          ? () => explore('F05')
          : null,
      onScan: app.placeRecognised(placeId) ? () => openScan(context) : null,
    ),
  );
}
