import 'package:flutter/material.dart';

import '../models/explorable_scene.dart';
import 'scene_explorer_screen.dart';

class AnastasisReliefScreen extends StatelessWidget {
  const AnastasisReliefScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const SceneExplorerScreen(scene: ExplorableScene.anastasis);
}
