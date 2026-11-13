import 'package:flutter/material.dart';

import '../city/place_screen.dart';
import '../guide/guide_screen.dart';
import '../content/models.dart';
import '../milestones/milestone_sheet.dart';
import '../plate/player.dart';
import '../screens/artworks_tab.dart';
import '../screens/about_tab.dart';
import '../screens/scan_screen.dart';
import '../services/progress_service.dart';
import '../space/player.dart';
import '../space/study.dart';
import 'app_scope.dart';

Future<T?> _push<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

Future<void> openMilestone(
  BuildContext context,
  Milestone milestone, {
  Detail? detail,
}) async {
  final app = AppScope.of(context);
  final scene = app.plates.forMilestone(milestone);
  if (scene == null) {
    // A 3D Milestone (CA) plays its kit study (P11: VI, Chora through time).
    final study = studyForMilestone(app, milestone);
    if (study == null) return showMilestoneSheet(context, milestone);
    ProgressScope.of(context).open(milestone.id);
    return openStudy(context, study);
  }
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

/// The study a 3D Milestone plays, by its manifest path.
SpaceStudy? studyForMilestone(AppScope app, Milestone m) => app.studyFor(m);

Future<void> openStudy(BuildContext context, SpaceStudy study) =>
    _push<void>(context, SpacePlayer(key: ValueKey(study.id), study: study));

Future<void> openPlace(BuildContext context, Place place) =>
    _push<void>(context, PlaceScreen(place: place));

/// The camera; opened from a place with a plan, a confident match flies to
/// its place on the plan (P11).
Future<void> openScan(BuildContext context, {String? placeId}) {
  final guide = placeId == null
      ? null
      : AppScope.of(context).registry?.guideFor(placeId);
  final navigator = Navigator.of(context);
  return _push<void>(
    context,
    ScanScreen(
      onLocate: guide == null
          ? null
          : (artwork, frame) {
              navigator.pop(); // the camera
              var planOnTop = false;
              navigator.popUntil((r) {
                planOnTop = r.settings.name == _guideRoute;
                return true; // only looks at the top route
              });
              final route = _guidePage(
                artwork.placeId,
                focus: artwork.id,
                flyFrom: frame,
              );
              planOnTop
                  ? navigator.pushReplacement(route)
                  : navigator.push(route);
            },
    ),
  );
}

Future<void> openAbout(BuildContext context) =>
    _push<void>(context, const AboutTab());

/// A place's artworks: its plan and guide when it has one (P11), else the
/// catalogue.
Future<void> openArtworks(BuildContext context, String placeId) =>
    AppScope.of(context).registry!.guideFor(placeId) == null
    ? openCatalogue(context, placeId)
    : openGuide(context, placeId);

Future<void> openGuide(BuildContext context, String placeId) =>
    Navigator.of(context).push<void>(_guidePage(placeId));

const _guideRoute = 'guide';

/// The guide in its own route, built with that route's context so its
/// actions outlive whatever opened it.
MaterialPageRoute<void> _guidePage(
  String placeId, {
  String? focus,
  Rect? flyFrom,
}) => MaterialPageRoute<void>(
  settings: const RouteSettings(name: _guideRoute),
  builder: (context) {
    final app = AppScope.of(context);
    final registry = app.registry!;
    final playable = _playable(app);
    return GuideScreen(
      place: registry.place(placeId)!,
      guide: registry.guideFor(placeId)!,
      registry: registry,
      focus: focus,
      flyFrom: flyFrom,
      examinable: playable.keys.toSet(),
      onExamine: (id) => openMilestone(context, playable[id]!),
      onCatalogue: () => openCatalogue(context, placeId),
      onScan: app.placeRecognised(placeId)
          ? () => openScan(context, placeId: placeId)
          : null,
    );
  },
);

Map<String, Milestone> _playable(AppScope app) => {
  for (final m in app.registry!.milestones)
    for (final a in m.artworkIds)
      if (app.plates.forMilestone(m) != null) a: m,
};

Future<void> openCatalogue(BuildContext context, String placeId) {
  final app = AppScope.of(context);
  final registry = app.registry!;
  final milestones = _playable(app);
  return _push<void>(
    context,
    ArtworksTab(
      artworks: [
        for (final a in registry.artworks)
          if (a.placeId == placeId) a,
      ],
      examinable: milestones.keys.toSet(),
      onExamine: (id) => openMilestone(context, milestones[id]!),
      onScan: app.placeRecognised(placeId)
          ? () => openScan(context, placeId: placeId)
          : null,
    ),
  );
}
