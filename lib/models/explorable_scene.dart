import 'package:flutter/material.dart';

class SceneDetail {
  const SceneDetail(
    this.id,
    this.title,
    this.description,
    this.point,
    this.window,
  );
  final String id, title, description;

  /// Normalized photograph coordinates, shared by every image variant.
  final Offset point;
  final Rect window;
}

class RestorationStudy {
  const RestorationStudy(
    this.title,
    this.original,
    this.study, {
    this.initialBlend = .35,
  });
  final double initialBlend;
  final String title, original, study;
}

class ExplorableScene {
  const ExplorableScene({
    required this.id,
    required this.title,
    required this.original,
    required this.relief,
    required this.restored,
    required this.geometry,
    required this.figures,
    required this.size,
    required this.details,
    required this.studies,
  });
  final String id, title, original, relief, restored, geometry, figures;
  final Size size;
  final List<SceneDetail> details;
  final List<RestorationStudy> studies;

  static const anastasis = ExplorableScene(
    id: 'F02',
    title: 'Anastasis',
    size: Size(2048, 1091),
    original: 'assets/anastasis/conch_reference.jpg',
    relief: 'assets/anastasis/relief_v5/relief_front.jpg',
    restored: 'assets/restoration/anastasis_restored_4k_v2.jpg',
    geometry: 'assets/explorer/anastasis_geometry.json',
    figures: 'assets/explorer/anastasis_figures_v2.json',
    details: [
      SceneDetail(
        'christ',
        'Christ',
        'Look at the face, the light robe and the star-filled mandorla surrounding the central figure.',
        Offset(.48, .40),
        Rect.fromLTRB(.385, .275, .615, .785),
      ),
      SceneDetail(
        'adam',
        'Adam',
        'Follow the joined hands and the movement from the tomb toward the center.',
        Offset(.335, .575),
        Rect.fromLTRB(.16, .49, .425, .82),
      ),
      SceneDetail(
        'eve',
        'Eve',
        'Examine the red robe, the bowed face and the extended arm.',
        Offset(.616, .522),
        Rect.fromLTRB(.545, .435, .762, .80),
      ),
      SceneDetail(
        'left',
        'Left figures',
        'Compare the overlapping faces, halos, crowns and surviving robe details.',
        Offset(.259, .348),
        Rect.fromLTRB(.075, .165, .397, .64),
      ),
      SceneDetail(
        'right',
        'Right figures',
        'Look closely at the faces and folds where the figures overlap the painted rock.',
        Offset(.73, .34),
        Rect.fromLTRB(.63, .16, .93, .675),
      ),
      SceneDetail(
        'gates',
        'Gates',
        'Explore the broken gates and small painted details beneath the central figure.',
        Offset(.484, .852),
        Rect.fromLTRB(.325, .69, .68, .94),
      ),
    ],
    studies: [
      RestorationStudy(
        '4K restored fresco',
        'assets/anastasis/conch_reference.jpg',
        'assets/restoration/anastasis_restored_4k_v2.jpg',
        initialBlend: 1,
      ),
    ],
  );

  static const judgment = ExplorableScene(
    id: 'F05',
    title: 'Last Judgment',
    size: Size(1600, 1067),
    original: 'assets/last_judgment/vault_reference.jpg',
    relief: 'assets/last_judgment/relief_v5/relief_front.jpg',
    restored: 'assets/restoration/last_judgment_restored_4k_v2.jpg',
    geometry: 'assets/explorer/last_judgment_geometry.json',
    figures: 'assets/explorer/last_judgment_figures_v2.json',
    details: [
      SceneDetail(
        'christ',
        'Christ',
        'Explore the face and mandorla. Compare the surviving paint with the reconstructed robes in the restored view.',
        Offset(.50, .60),
        Rect.fromLTRB(.406, .533, .591, .763),
      ),
      SceneDetail(
        'deesis',
        'Deesis',
        'Examine the central figure, the two standing figures and the surrounding court.',
        Offset(.447, .63),
        Rect.fromLTRB(.375, .50, .615, .768),
      ),
      SceneDetail(
        'apostles',
        'Apostles',
        'Compare the seated figures, their faces, books and overlapping halos.',
        Offset(.31, .56),
        Rect.fromLTRB(.205, .478, .420, .748),
      ),
      SceneDetail(
        'heavens',
        'Heavens',
        'Look at the angel and the circular, rolled-up heavens in the upper register.',
        Offset(.508, .395),
        Rect.fromLTRB(.422, .275, .601, .532),
      ),
      SceneDetail(
        'throne',
        'Throne',
        'Explore the prepared throne and the kneeling figures below the heavenly court.',
        Offset(.51, .849),
        Rect.fromLTRB(.395, .746, .62, .975),
      ),
      SceneDetail(
        'river',
        'River of fire',
        'Follow the red-orange painted river toward the lower right of the vault.',
        Offset(.727, .861),
        Rect.fromLTRB(.573, .748, .891, .987),
      ),
    ],
    studies: [
      RestorationStudy(
        '4K restored vault',
        'assets/last_judgment/vault_reference.jpg',
        'assets/restoration/last_judgment_restored_4k_v2.jpg',
        initialBlend: 1,
      ),
    ],
  );
}
