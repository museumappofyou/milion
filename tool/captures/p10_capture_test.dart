// P10 evidence: the Atlas at every stop of the time slider, Below, Turkish,
// 200% text and the list, as 1080×1920 stills, and the hook. Run:
//   flutter test tool/captures/p10_capture_test.dart
// then encode the hook (frames land in the gitignored studio/cache):
//   ffmpeg -framerate 24 -i studio/cache/p10-hook/%04d.png -pix_fmt yuv420p
//     -vf scale=1080:1920 studio/captures/P10/peninsula-330-to-today-10s.mp4
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/atlas/atlas_assets.dart';
import 'package:milion/atlas/atlas_controller.dart';
import 'package:milion/atlas/atlas_data.dart';
import 'package:milion/atlas/atlas_filter.dart';
import 'package:milion/atlas/atlas_map.dart';
import 'package:milion/atlas/atlas_view.dart';
import 'package:milion/atlas/historic.dart';
import 'package:milion/content/registry.dart';
import 'package:milion/content/repository.dart';
import 'package:milion/design/theme.dart';
import 'package:milion/l10n/strings.dart';
import 'package:milion/shell/app_scope.dart';

import '../../test/helpers.dart' show loadThemeFonts;

const out = 'studio/captures/P10';
const hookFrames = 'studio/cache/p10-hook';
const dpr = 2.625; // the A52s: 1080 × 2400 at 411 dp

AtlasAssets _assets() => AtlasAssets.decodeSync(
  ByteData.sublistView(File(AtlasData.assetPath).readAsBytesSync()),
  File(HistoricAtlas.assetPath).readAsStringSync(),
  File(PlaceYears.assetPath).readAsStringSync(),
);

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

/// Pumps until the tile cache has rendered what the view needs.
Future<void> _settleTiles(WidgetTester tester, [int frames = 30]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  late AtlasAssets assets;
  late ContentRegistry registry;
  setUpAll(() async {
    assets = _assets();
    registry = ContentRegistry.fromJson(
      await readContent((path) => File(path).readAsString()),
    );
    Directory(out).createSync(recursive: true);
  });

  Future<(GlobalKey, AtlasController)> mount(
    WidgetTester tester, {
    String language = 'en',
    double textScale = 1,
    AtlasView view = AtlasView.peninsula,
  }) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.reset);
    await loadThemeFonts(tester);
    final key = GlobalKey();
    final controller = AtlasController(view: view);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      AppScope(
        registry: registry,
        error: null,
        retry: () {},
        clock: () => DateTime.utc(2026, 11, 9, 9),
        recognised: const {},
        child: MaterialApp(
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
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: AtlasMap(
                assets: assets,
                controller: controller,
                places: atlasPlaces(
                  registry,
                  AtlasFilter.none,
                  DateTime.utc(2026, 11, 9, 9),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await _settleTiles(tester);
    return (key, controller);
  }

  void at(AtlasController c, int stop) {
    c
      ..stop = stop
      ..year = atlasYears[stop].toDouble()
      ..settle();
  }

  testWidgets('every stop of the slider, EN', (tester) async {
    final (key, c) = await mount(tester);
    for (var i = 0; i < atlasYears.length; i++) {
      at(c, i);
      await _settleTiles(tester);
      await _shoot(tester, key, '$out/atlas-${atlasYears[i]}-en.png');
    }
  });

  testWidgets('close in: the walls at the Gate of St Romanus, 1453', (
    tester,
  ) async {
    final (key, c) = await mount(
      tester,
      view: const AtlasView(center: Offset(-4300, 1400), scale: 1 / 3.2),
    );
    at(c, 3);
    await _settleTiles(tester, 60);
    await _shoot(tester, key, '$out/atlas-1453-land-walls-close.png');
    at(c, 6);
    await _settleTiles(tester, 60);
    await _shoot(tester, key, '$out/atlas-today-land-walls-close.png');
  });

  testWidgets('the shore at Yenikapı moves: 330, 1560, today', (tester) async {
    final (key, c) = await mount(
      tester,
      view: const AtlasView(center: Offset(-2232, -150), scale: 1 / 4.5),
    );
    for (final stop in [0, 4, 6]) {
      at(c, stop);
      await _settleTiles(tester, 60);
      await _shoot(tester, key, '$out/atlas-yenikapi-${atlasYears[stop]}.png');
    }
  });

  testWidgets('Below, 537 and today', (tester) async {
    final (key, c) = await mount(
      tester,
      view: const AtlasView(center: Offset(-1200, 300), scale: 1 / 6),
    );
    c.below = true;
    for (final stop in [1, 6]) {
      at(c, stop);
      await _settleTiles(tester, 60);
      await _shoot(tester, key, '$out/atlas-below-${atlasYears[stop]}.png');
    }
  });

  testWidgets('Turkish and 200% text', (tester) async {
    final (key, c) = await mount(tester, language: 'tr');
    at(c, 4);
    await _settleTiles(tester);
    await _shoot(tester, key, '$out/atlas-1560-tr.png');
    await tester.pumpWidget(const SizedBox());
    final (key2, c2) = await mount(tester, textScale: 2);
    at(c2, 3);
    await _settleTiles(tester);
    await _shoot(tester, key2, '$out/atlas-1453-en-200.png');
  });

  // The hook: 10 s at 24 fps, 330 → today, holding on each stop.
  testWidgets('hook: the peninsula from 330 to today', (tester) async {
    final (key, c) = await mount(tester);
    final dir = Directory(hookFrames);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final years = <(double, int)>[];
    const hold = 14, move = 20;
    for (var i = 0; i < atlasYears.length; i++) {
      for (var f = 0; f < hold; f++) {
        years.add((atlasYears[i].toDouble(), i));
      }
      if (i == atlasYears.length - 1) break;
      for (var f = 1; f <= move; f++) {
        final t = Curves.easeInOutCubic.transform(f / move);
        final y = atlasYears[i] + (atlasYears[i + 1] - atlasYears[i]) * t;
        years.add((y, t < .5 ? i : i + 1));
      }
    }
    while (years.length < 240) {
      years.add((2026, atlasYears.length - 1));
    }
    var n = 0;
    for (final (year, stop) in years) {
      c
        ..stop = stop
        ..year = year;
      await _settleTiles(tester, n == 0 ? 40 : 3);
      await _shoot(
        tester,
        key,
        '$hookFrames/${(n++).toString().padLeft(4, '0')}.png',
      );
    }
  });
}
