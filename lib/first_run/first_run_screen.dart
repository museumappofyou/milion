import 'package:flutter/material.dart';

import '../content/geography.dart';
import '../design/motion.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../shell/app_scope.dart';
import 'first_run_painter.dart';

/// The five places that light up, with label side (left) and placement (below).
const firstRunPlaces = [
  ('chora', false, false),
  ('yedikule', false, false),
  ('suleymaniye', true, false),
  ('galata-tower', false, false),
  ('maidens-tower', true, true),
];

Future<void> replayFirstRun(NavigatorState navigator) => navigator.push(
  PageRouteBuilder<void>(
    transitionDuration: MotionToken.durations[MeasureMotion.sweep]!,
    pageBuilder: (context, _, _) =>
        FirstRunScreen(onDone: () => Navigator.of(context).pop()),
    transitionsBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  ),
);

enum FirstRunMode { animated, stills, spoken }

/// Milestone 0 lite: once on first launch, replayable from About.
class FirstRunScreen extends StatefulWidget {
  const FirstRunScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  static const length = Duration(seconds: 12);
  static const skippableAfter = 2.0;

  /// Reduced motion: the stone, the rings with five places, the line.
  static const stills = [4.6, 10.1, 11.6];
  @override
  State<FirstRunScreen> createState() => FirstRunScreenState();
}

class FirstRunScreenState extends State<FirstRunScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController clock =
      AnimationController(vsync: this, duration: FirstRunScreen.length)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _finish();
        });
  FirstRunMode mode = FirstRunMode.animated;
  int still = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    final wanted = media.accessibleNavigation
        ? FirstRunMode.spoken
        : media.disableAnimations
        ? FirstRunMode.stills
        : FirstRunMode.animated;
    // Leaving motion is one-way: a screen reader or reduced motion that
    // appears mid-sequence never restarts the clock if it flickers off.
    if (wanted.index > mode.index) mode = wanted;
    if (mode == FirstRunMode.animated) {
      if (!_done && !clock.isAnimating) clock.forward();
    } else {
      clock.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mode != FirstRunMode.animated || _done) return;
    state == AppLifecycleState.resumed ? clock.forward() : clock.stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    clock.dispose();
    super.dispose();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    clock.stop();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n, lang = context.language;
    final registry = AppScope.of(context).registry;
    final places = [
      for (final (id, left, below) in firstRunPlaces)
        if (registry?.place(id) case final p?)
          LitPlace(
            p.names.inLanguage(lang),
            formatMilDistance(fromMilion(p).km, language: lang),
            metresFromMilion(p.coordinates),
            left: left,
            below: below,
          ),
    ];
    FirstRunPainter painter(double t, {bool still = false}) => FirstRunPainter(
      t: t,
      line: s.firstRunLine,
      stone: TypeRole.capitals(
        registry?.place('milion')?.names.inLanguage(lang) ?? s.brandName,
        lang,
      ),
      street: s.firstRunStone,
      coordinates: s.milionCoordinates,
      places: places,
      scaler: MediaQuery.textScalerOf(context),
      still: still,
    );
    final last = still == FirstRunScreen.stills.length - 1;
    return Theme(
      data: DesignTheme.lamp,
      child: AnnotatedRegion(
        value: DesignTheme.overlay(Brightness.dark),
        child: Scaffold(
          backgroundColor: Pigment.lamp,
          // The drawing and the controls never overlap, so touch exploration
          // reaches the button as its own node.
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Semantics(
                  container: true,
                  label: s.firstRunSentence,
                  child: ExcludeSemantics(
                    child: mode == FirstRunMode.animated
                        ? AnimatedBuilder(
                            animation: clock,
                            builder: (context, _) => CustomPaint(
                              painter: painter(
                                clock.value *
                                    FirstRunScreen.length.inMilliseconds /
                                    1000,
                              ),
                            ),
                          )
                        : CustomPaint(
                            key: ValueKey('first-run-still-$still'),
                            painter: painter(
                              FirstRunScreen.stills[mode == FirstRunMode.spoken
                                  ? 2
                                  : still],
                              still: true,
                            ),
                          ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: switch (mode) {
                    FirstRunMode.animated => Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedBuilder(
                        animation: clock,
                        builder: (context, child) {
                          final shown =
                              clock.value * 12 >= FirstRunScreen.skippableAfter;
                          return IgnorePointer(
                            ignoring: !shown,
                            child: AnimatedOpacity(
                              opacity: shown ? 1 : 0,
                              duration:
                                  MotionToken.durations[MeasureMotion.settle]!,
                              child: ExcludeSemantics(
                                excluding: !shown,
                                child: child!,
                              ),
                            ),
                          );
                        },
                        child: TextButton(
                          key: const ValueKey('first-run-skip'),
                          onPressed: _finish,
                          child: Text(s.skip),
                        ),
                      ),
                    ),
                    FirstRunMode.stills => Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Text(
                          s.firstRunStill('${still + 1}'),
                          style: TypeRole.measurement.copyWith(
                            color: Pigment.marble,
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (!last)
                              TextButton(
                                onPressed: _finish,
                                child: Text(s.skip),
                              ),
                            FilledButton(
                              key: const ValueKey('first-run-next'),
                              onPressed: last
                                  ? _finish
                                  : () => setState(() => still++),
                              child: Text(last ? s.openToday : s.next),
                            ),
                          ],
                        ),
                      ],
                    ),
                    FirstRunMode.spoken => Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        key: const ValueKey('first-run-continue'),
                        onPressed: _finish,
                        child: Text(s.openToday),
                      ),
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
