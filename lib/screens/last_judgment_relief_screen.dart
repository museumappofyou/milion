import 'package:flutter/material.dart';

import '../models/explorable_scene.dart';
import 'scene_explorer_screen.dart';

class LastJudgmentReliefScreen extends StatelessWidget {
  const LastJudgmentReliefScreen({super.key, this.initialFocus = 'Overview'});
  final String initialFocus;

  @override
  Widget build(BuildContext context) => SceneExplorerScreen(
    scene: ExplorableScene.judgment,
    initialFocus: initialFocus,
  );
}
