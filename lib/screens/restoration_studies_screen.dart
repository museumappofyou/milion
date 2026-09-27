import 'package:flutter/material.dart';

import '../models/explorable_scene.dart';
import '../theme/milion_theme.dart';

/// Separate full-frame and detail-file experiments; original assets stay intact.
class RestorationStudiesScreen extends StatefulWidget {
  const RestorationStudiesScreen({super.key, required this.scene});
  final ExplorableScene scene;
  @override
  State<RestorationStudiesScreen> createState() =>
      _RestorationStudiesScreenState();
}

class _RestorationStudiesScreenState extends State<RestorationStudiesScreen> {
  final _transform = TransformationController();
  int _file = 0;
  bool _study = true;
  late double _amount = widget.scene.studies.first.initialBlend;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final study = widget.scene.studies[_file];
    return Scaffold(
      backgroundColor: const Color(0xFF17251F),
      appBar: AppBar(
        title: const Text('Restoration studies'),
        backgroundColor: MilionTheme.night,
        foregroundColor: MilionTheme.paper,
        titleTextStyle: MilionTheme.display(27, color: MilionTheme.paper),
        actions: [
          IconButton(
            tooltip: 'Reset zoom',
            onPressed: () => _transform.value = Matrix4.identity(),
            icon: const Icon(Icons.center_focus_strong_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < widget.scene.studies.length; i++)
                  ChoiceChip(
                    label: Text(widget.scene.studies[i].title),
                    selectedColor: MilionTheme.lightGold,
                    backgroundColor: const Color(0xFF2C3B32),
                    labelStyle: TextStyle(
                      color: i == _file ? MilionTheme.night : MilionTheme.paper,
                    ),
                    checkmarkColor: MilionTheme.night,
                    selected: i == _file,
                    onSelected: (_) => setState(() {
                      _file = i;
                      _amount = widget.scene.studies[i].initialBlend;
                      _transform.value = Matrix4.identity();
                    }),
                  ),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              key: const ValueKey('study-interactive-viewer'),
              transformationController: _transform,
              minScale: 1,
              maxScale: 8,
              trackpadScrollCausesScale: true,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(study.original, fit: BoxFit.contain),
                    Positioned.fill(
                      child: Opacity(
                        opacity: _study ? _amount : 0,
                        child: Image.asset(
                          study.study,
                          fit: BoxFit.fill,
                          errorBuilder: (_, _, _) => const Center(
                            child: Text(
                              'Study unavailable',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Interpretive restoration study. Facial details are inferred; the source photograph is unchanged.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Blend',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Expanded(
                        child: Slider(
                          value: _amount,
                          onChanged: (v) => setState(() => _amount = v),
                        ),
                      ),
                      Text(
                        '${(_amount * 100).round()}%',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  SegmentedButton<bool>(
                    style: SegmentedButton.styleFrom(
                      foregroundColor: Colors.white,
                      selectedForegroundColor: Colors.black,
                      selectedBackgroundColor: const Color(0xFFE7D3A5),
                    ),
                    segments: const [
                      ButtonSegment(value: false, label: Text('Original')),
                      ButtonSegment(
                        value: true,
                        label: Text('Restoration study'),
                      ),
                    ],
                    selected: {_study},
                    onSelectionChanged: (value) =>
                        setState(() => _study = value.first),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
