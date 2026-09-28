import 'package:flutter/material.dart';

import '../models/explorable_scene.dart';
import '../content/models.dart' show Honesty;
import '../design/theme.dart';
import '../design/components.dart';
import '../l10n/strings.dart';

class RestorationStudiesScreen extends StatefulWidget {
  const RestorationStudiesScreen({super.key, required this.scene});
  final ExplorableScene scene;
  @override
  State<RestorationStudiesScreen> createState() =>
      _RestorationStudiesScreenState();
}

class _RestorationStudiesScreenState extends State<RestorationStudiesScreen> {
  final _transform = TransformationController();
  bool _study = false;
  double _amount = 1;
  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: DesignTheme.lamp,
    child: Builder(
      builder: (context) {
        final s = context.l10n, study = widget.scene.studies.first;
        return Scaffold(
          appBar: AppBar(
            title: Text(s.studies),
            toolbarHeight: MediaQuery.textScalerOf(context).scale(24) + 40,
            actions: [
              IconButton(
                tooltip: s.resetView,
                onPressed: () => _transform.value = Matrix4.identity(),
                icon: const Icon(Icons.center_focus_strong_outlined),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: HonestyLabel(
                  _study ? Honesty.RECONSTRUCTION : Honesty.ORIGINAL,
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
                              errorBuilder: (_, _, _) => ContentState(
                                error: true,
                                title: s.studyUnavailable,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .4,
                ),
                child: SingleChildScrollView(
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.scene.id == 'F02'
                                ? s.restoredFresco
                                : s.restoredVault,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(s.studyNotice),
                          Row(
                            children: [
                              Text(s.blend),
                              Expanded(
                                child: Slider(
                                  value: _amount,
                                  onChanged: (v) => setState(() => _amount = v),
                                ),
                              ),
                              Text('${(_amount * 100).round()}%'),
                            ],
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: () => setState(() => _study = false),
                                child: Text(s.original),
                              ),
                              OutlinedButton(
                                onPressed: () => setState(() => _study = true),
                                child: Text(s.reconstruction),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
