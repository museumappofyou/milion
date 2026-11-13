// P11 evidence: Chora through time (Milestone VI) in each epoch, the guide's
// plan and cycle walk (EN, TR, 200% text), and the hook. Run:
//   flutter test tool/captures/p11_capture_test.dart
// then encode the hook (frames land in the gitignored studio/cache):
//   ffmpeg -framerate 24 -i studio/cache/p11-hook/%04d.png -pix_fmt yuv420p
//     -vf scale=1080:1920 studio/captures/P11/103-scenes-one-small-church-10s.mp4
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/content/guide.dart';
import 'package:milion/content/models.dart';
import 'package:milion/content/registry.dart';
import 'package:milion/content/repository.dart';
import 'package:milion/design/theme.dart';
import 'package:milion/design/tokens.dart';
import 'package:milion/guide/guide_screen.dart';
import 'package:milion/guide/plan_view.dart';
import 'package:milion/l10n/strings.dart';
import 'package:milion/space/capture.dart';
import 'package:milion/space/controller.dart';
import 'package:milion/space/renderer.dart';
import 'package:milion/space/style.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test/helpers.dart' show loadThemeFonts;
import '../../test/space_kit_test.dart' show kitModel, kitStudy;

const out = 'studio/captures/P11';
const hookFrames = 'studio/cache/p11-hook';
const dpr = 2.625; // the A52s: 1080 × 2400 at 411 dp
const _degree = math.pi / 180;

Future<void> still(SpaceRenderer r, SpaceScene scene, String name) async {
  final image = await renderSpaceStill(
    r,
    scene,
    const Size(540, 960),
    pixelRatio: 2,
  );
  File('$out/$name.png').writeAsBytesSync(await encodePng(image));
  image.dispose();
}

Future<void> _shoot(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: dpr);
    final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    File(path).writeAsBytesSync(data.buffer.asUint8List());
    image.dispose();
  });
}

Widget _app({
  required Widget home,
  String language = 'en',
  double textScale = 1,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: DesignTheme.marble,
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: home,
);

void main() {
  late ContentRegistry registry;
  setUpAll(() async {
    registry = ContentRegistry.fromJson(
      await readContent((path) => File(path).readAsString()),
    );
    Directory(out).createSync(recursive: true);
  });

  testWidgets('Milestone VI: Chora in each epoch', (tester) async {
    await tester.runAsync(() async {
      final study = kitStudy('kariye-camii'), model = kitModel(study);
      final c = SpaceController(study, model);
      final r = SpaceRenderer(model);
      final above = c.choisyView.copyWith(
        elevation: 30 * _degree,
        azimuth: 235 * _degree,
      );
      // Each epoch whole: the parts its steps name.
      for (final e in study.epochs) {
        final shown = {for (final step in study.stepsIn(e.year)) ...step.parts};
        await still(
          r,
          SpaceScene(
            view: above,
            style: SpaceStyle.stone,
            parts: [
              for (final part in model.parts)
                shown.contains(part.id)
                    ? const SpacePartState()
                    : SpacePartState.hidden,
            ],
          ),
          'chora-${e.year}',
        );
      }
      await still(r, c.scene(), 'chora-choisy');
      r.dispose();
      c.dispose();
    });
  });

  Future<GlobalKey> guide(
    WidgetTester tester, {
    String language = 'en',
    double textScale = 1,
  }) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.reset);
    await loadThemeFonts(tester);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: _app(
          language: language,
          textScale: textScale,
          home: GuideScreen(
            place: registry.place('chora')!,
            guide: registry.guideFor('chora')!,
            registry: registry,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return key;
  }

  for (final (language, scale, name) in [
    ('en', 1.0, 'guide-plan-en'),
    ('tr', 1.0, 'guide-plan-tr'),
    ('en', 2.0, 'guide-plan-200'),
  ]) {
    testWidgets('the guide: $name', (tester) async {
      final key = await guide(tester, language: language, textScale: scale);
      await _shoot(tester, key, '$out/$name.png');
    });
  }

  testWidgets('the guide: one room, then a cycle walk mid-step', (
    tester,
  ) async {
    final key = await guide(tester);
    final chip = find.byKey(const ValueKey('guide-room-parekklesion'));
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    await _shoot(tester, key, '$out/guide-room-parekklesion.png');
    final all = find.byKey(const ValueKey('guide-room-all'));
    await tester.ensureVisible(all);
    await tester.pumpAndSettle();
    await tester.tap(all);
    await tester.pumpAndSettle();
    final cycle = find.byKey(const ValueKey('guide-cycle-life-of-the-virgin'));
    await tester.ensureVisible(cycle);
    await tester.pumpAndSettle();
    await tester.tap(cycle);
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const ValueKey('cycle-next')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('cycle-next')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    await _shoot(tester, key, '$out/guide-cycle-walk-en.png');
    await tester.pumpAndSettle();
    await _shoot(tester, key, '$out/guide-cycle-stop-en.png');
  });

  // The hook: 10 s at 24 fps. The plan fills with its 103 tesserae, zooms
  // into the inner narthex to the donor panel, and the mosaic takes over,
  // closing on Metochites' hat.
  testWidgets('hook: 103 scenes, one small church', (tester) async {
    final dir = Directory(hookFrames);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.reset);
    await loadThemeFonts(tester);
    final photo = (await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(
        File('assets/plates/metochites/original.jpg').readAsBytesSync(),
      );
      return (await codec.getNextFrame()).image;
    }))!;
    final hat = registry.details.firstWhere(
      (d) => d.id == 'detail-metochites-hat',
    );
    final guide = registry.guideFor('chora')!;
    final artworks = {
      for (final a in registry.artworks)
        if (a.placeId == 'chora') a.id: a,
    };
    // Walking order: the four cycles, then everything else.
    final order = <String>{
      for (final c in guide.cycles) ...c.artworkIds,
      ...guide.anchors.keys,
    }.toList();
    final key = GlobalKey();
    for (var n = 0; n < 240; n++) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: _app(
            home: _HookFrame(
              t: n / 24,
              guide: guide,
              artworks: artworks,
              order: order,
              photo: photo,
              hat: Rect.fromLTRB(
                hat.window.left,
                hat.window.top,
                hat.window.right,
                hat.window.bottom,
              ),
            ),
          ),
        ),
      );
      await _shoot(
        tester,
        key,
        '$hookFrames/${n.toString().padLeft(4, '0')}.png',
      );
    }
    photo.dispose();
  });
}

double _ease(double a, double b, double t) =>
    Curves.easeInOutCubic.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

class _HookFrame extends StatelessWidget {
  const _HookFrame({
    required this.t,
    required this.guide,
    required this.artworks,
    required this.order,
    required this.photo,
    required this.hat,
  });
  final double t;
  final PlaceGuide guide;
  final Map<String, Artwork> artworks;
  final List<String> order;
  final ui.Image photo;
  final Rect hat;

  @override
  Widget build(BuildContext context) {
    final colors = MeasureColors.of(context);
    final text = Theme.of(context).textTheme;
    // 0–2.8 s the tesserae light up; 2.6–5.4 s the plan zooms to M11;
    // 5.2–6.4 s the mosaic fades in; 6.4–9.2 s it closes on the hat.
    final shown = (order.length * _ease(0.2, 2.8, t)).round();
    final zoom = _ease(2.6, 5.4, t);
    final fade = _ease(5.2, 6.4, t);
    final close = _ease(6.4, 9.2, t);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest;
          // The plan above the caption.
          final plan = Size(size.width, size.height - 170);
          final frame = PlanFrame(guide, plan);
          final focus = frame.toScreen(guide.anchors['M11']!.at);
          final centre = plan.center(Offset.zero);
          final p = Offset.lerp(centre, focus, zoom)!;
          final s = 1 + 7 * zoom;
          final m = Matrix4.identity()
            ..translateByDouble(centre.dx, centre.dy, 0, 1)
            ..scaleByDouble(s, s, 1, 1)
            ..translateByDouble(-p.dx, -p.dy, 0, 1);
          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: colors.ground),
              Positioned(
                left: 0,
                top: 0,
                width: plan.width,
                height: plan.height,
                child: Transform(
                  transform: m,
                  child: CustomPaint(
                    size: plan,
                    painter: PlanPainter(
                      guide: guide,
                      artworks: artworks,
                      colors: colors,
                      language: 'en',
                      state: PlanState(
                        focus: zoom > 0 ? 'M11' : null,
                        dimmed: {
                          ...order.skip(shown),
                          if (zoom > 0.5)
                            for (final id in order)
                              if (id != 'M11') id,
                        },
                      ),
                    ),
                  ),
                ),
              ),
              if (fade > 0)
                Opacity(
                  opacity: fade,
                  child: CustomPaint(
                    size: size,
                    painter: _PhotoPainter(photo, hat, close),
                  ),
                ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: _ease(0.3, 1.0, t),
                      child: Text(
                        '$shown scenes,',
                        style: text.displaySmall?.copyWith(
                          color: fade > 0.5 ? Colors.white : colors.ink,
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: _ease(3.0, 3.8, t),
                      child: Text(
                        'one small church.',
                        style: text.displaySmall?.copyWith(
                          color: fade > 0.5 ? Colors.white : colors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Opacity(
                      opacity: _ease(8.6, 9.4, t),
                      child: Text(
                        'Theodore Metochites’ hat · Chora, c. 1321',
                        style: text.bodyMedium?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              if (fade > 0)
                Positioned(
                  right: 12,
                  top: 36,
                  child: Opacity(
                    opacity: fade,
                    child: Text(
                      '© Caner Cangül / Kültür Envanteri',
                      style: text.labelSmall?.copyWith(color: Colors.white70),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The mosaic, cropped to fill the frame, closing from the panel's donor
/// figure onto the hat window as [close] goes 0 → 1.
class _PhotoPainter extends CustomPainter {
  _PhotoPainter(this.photo, this.hat, this.close);
  final ui.Image photo;
  final Rect hat;
  final double close;

  @override
  void paint(Canvas canvas, Size size) {
    final w = photo.width.toDouble(), h = photo.height.toDouble();
    final aspect = size.width / size.height;
    // Start: a full-height crop centred on the hat; end: the hat window,
    // widened to the frame's aspect.
    final startH = h, startW = startH * aspect;
    final c0 = Offset(hat.center.dx * w, h / 2);
    final endH = hat.height * h * 1.25, endW = endH * aspect;
    final c1 = Offset(hat.center.dx * w, hat.center.dy * h);
    final cw = ui.lerpDouble(startW, endW, close)!;
    final ch = ui.lerpDouble(startH, endH, close)!;
    final c = Offset.lerp(c0, c1, close)!;
    final left = (c.dx - cw / 2).clamp(0.0, w - cw);
    final top = (c.dy - ch / 2).clamp(0.0, h - ch);
    canvas.drawImageRect(
      photo,
      Rect.fromLTWH(left, top, cw, ch),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(_PhotoPainter old) => old.close != close;
}
