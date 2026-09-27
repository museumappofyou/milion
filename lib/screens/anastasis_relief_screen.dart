import 'package:flutter/material.dart';

import '../models/explorable_scene.dart';
import '../services/anastasis_relief.dart';
import 'anastasis_v5_screen.dart';
import 'scene_explorer_screen.dart';

/// The interactive explorer keeps the original v5 and archived renderer intact.
class AnastasisReliefScreen extends StatelessWidget {
  const AnastasisReliefScreen({super.key, this.initialControls});
  final ReliefControls? initialControls;
  static const frozenControls = AnastasisV5Screen.frozenControls;

  @override
  Widget build(BuildContext context) => initialControls != null
      ? AnastasisV5Screen(initialControls: initialControls)
      : SceneExplorerScreen(
          scene: ExplorableScene.anastasis,
          classicBuilder: (_) => const AnastasisV5Screen(),
        );
}
