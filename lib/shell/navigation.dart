import 'package:flutter/material.dart';

import '../city/place_screen.dart';
import '../content/models.dart';
import '../milestones/milestone_sheet.dart';
import '../plate/player.dart';
import '../screens/artworks_tab.dart';
import '../screens/about_tab.dart';
import '../screens/scan_screen.dart';
import '../services/progress_service.dart';
import 'app_scope.dart';

Future<T?> _push<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

Future<void> openMilestone(
  BuildContext context,
  Milestone milestone, {
  Detail? detail,
}) async {
  final scene = AppScope.of(context).plates.forMilestone(milestone);
  if (scene == null) return showMilestoneSheet(context, milestone);
  ProgressScope.of(context).open(milestone.id);
  await _push<void>(
    context,
    PlatePlayer(
      key: ValueKey(scene.id),
      manifest: scene,
      initialDetail: detail,
    ),
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
        if (app.plates.forMilestone(m) != null) a: m,
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
      examinable: milestones.keys.toSet(),
      onExamine: explore,
      onScan: app.placeRecognised(placeId) ? () => openScan(context) : null,
    ),
  );
}
