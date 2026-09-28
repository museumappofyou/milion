import 'package:flutter/widgets.dart';

import '../models/explorable_scene.dart';
import 'strings.dart';

String sceneTitle(BuildContext c, ExplorableScene scene) =>
    scene.id == 'F02' ? c.l10n.anastasis : c.l10n.judgment;
String detailTitle(BuildContext c, String id) {
  final s = c.l10n;
  return switch (id) {
    'christ' => s.detailChrist,
    'adam' => s.detailAdam,
    'eve' => s.detailEve,
    'left' => s.detailLeft,
    'right' => s.detailRight,
    'gates' => s.detailGates,
    'deesis' => s.detailDeesis,
    'apostles' => s.detailApostles,
    'heavens' => s.detailHeavens,
    'throne' => s.detailThrone,
    'river' => s.detailRiver,
    _ => s.overview,
  };
}

String detailBody(BuildContext c, String scene, String id) {
  final s = c.l10n;
  return switch (id) {
    'christ' => scene == 'F02' ? s.anastasisChristBody : s.judgmentChristBody,
    'adam' => s.adamBody,
    'eve' => s.eveBody,
    'left' => s.leftBody,
    'right' => s.rightBody,
    'gates' => s.gatesBody,
    'deesis' => s.deesisBody,
    'apostles' => s.apostlesBody,
    'heavens' => s.heavensBody,
    'throne' => s.throneBody,
    'river' => s.riverBody,
    _ => s.detailHint,
  };
}
