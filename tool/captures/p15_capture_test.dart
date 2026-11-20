// P15 evidence on the host: Milestone XVIII's wall strip (its reveal, the
// story's stills in both languages, a gate's sheet) and XIX's map sequence
// (its reveal over the ships' hill, the stills, the accounts). Run:
//   flutter test tool/captures/p15_capture_test.dart
// P15_ONLY=strip or P15_ONLY=siege limits it to one.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/atlas/atlas_assets.dart';
import 'package:milion/atlas/atlas_data.dart';
import 'package:milion/atlas/historic.dart';
import 'package:milion/atlas/atlas_filter.dart' show PlaceYears;
import 'package:milion/content/registry.dart';
import 'package:milion/content/repository.dart';
import 'package:milion/l10n/app_localizations.dart';
import 'package:milion/shell/app_scope.dart';
import 'package:milion/siege/siege.dart';
import 'package:milion/siege/siege_player.dart';
import 'package:milion/walls/wall_player.dart';
import 'package:milion/walls/wall_strip.dart';

import '../../test/helpers.dart' show loadThemeFonts;

const out = 'studio/captures/P15';
final only = Platform.environment['P15_ONLY'];

Future<void> shot(WidgetTester tester, GlobalKey key, String name) async {
  expect(tester.takeException(), isNull, reason: name);
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    File('$out/$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
    image.dispose();
  });
}

/// Lets the asset decode of a pushed photograph finish in real time.
Future<void> settleImages(WidgetTester tester) async {
  await tester.pumpAndSettle();
  for (final e in find.byType(Image).evaluate()) {
    final image = (e.widget as Image).image;
    await tester.runAsync(() => precacheImage(image, e, onError: (_, _) {}));
  }
  await tester.pumpAndSettle();
}

Widget host(
  ContentRegistry registry,
  Widget child,
  GlobalKey key, {
  Locale locale = const Locale('en'),
}) => RepaintBoundary(
  key: key,
  child: AppScope(
    registry: registry,
    error: null,
    retry: () {},
    clock: DateTime.now,
    recognised: const {},
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  ),
);

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  late ContentRegistry registry;
  setUpAll(() async {
    Directory(out).createSync(recursive: true);
    registry = await ContentRepository((p) => File(p).readAsString()).load();
  });

  testWidgets('XVIII: the strip\'s reveal, stills and a gate', (tester) async {
    if (only != null && only != 'strip') return;
    await loadThemeFonts(tester);
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final strip = WallStripManifest.fromJson(
      _json('assets/walls/land-walls/strip.json'),
    );
    final key = GlobalKey();
    for (final locale in const [Locale('en'), Locale('tr')]) {
      await tester.pumpWidget(
        host(registry, WallPlayer(strip: strip), key, locale: locale),
      );
      await tester.pumpAndSettle();
      final player = tester.state<WallPlayerState>(find.byType(WallPlayer));
      final c = player.controller;
      if (locale.languageCode == 'en') {
        await shot(tester, key, 'xviii-open');
        c.play();
        for (final t in [1.0, 5.0, 9.0, 13.5]) {
          c.advance(t - c.seconds);
          await tester.pump();
          await shot(tester, key, 'xviii-reveal-${t.toStringAsFixed(1)}s');
        }
        c.advance(60);
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < strip.stills.length; i++) {
        c.stills(i);
        await tester.pumpAndSettle();
        await shot(
          tester,
          key,
          'xviii-${strip.stills[i]}-${locale.languageCode}',
        );
      }
      if (locale.languageCode == 'en') {
        c.explore();
        for (final id in ['golden-gate', 'kerkoporta']) {
          final g = strip.gates.firstWhere((g) => g.id == id);
          c.goTo(g.at);
          await tester.pumpAndSettle();
          unawaited(player.showGate(g));
          await tester.pumpAndSettle();
          await shot(tester, key, 'xviii-gate-$id');
          final photo = find.byKey(ValueKey('gate-photo-$id'));
          if (photo.evaluate().isNotEmpty) {
            await tester.ensureVisible(photo);
            await tester.pumpAndSettle();
            await tester.tap(photo);
            await settleImages(tester);
            await shot(tester, key, 'xviii-gate-$id-photo');
            Navigator.of(
              tester.element(find.byType(WallPlayer, skipOffstage: false)),
            ).pop();
            await tester.pumpAndSettle();
          }
          Navigator.of(tester.element(find.byType(WallPlayer))).pop();
          await tester.pumpAndSettle();
        }
      }
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('XIX: the map\'s reveal, stills and accounts', (tester) async {
    if (only != null && only != 'siege') return;
    await loadThemeFonts(tester);
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final siege = SiegeManifest.fromJson(_json('assets/siege/1453/siege.json'));
    final atlas = AtlasAssets.decodeSync(
      ByteData.sublistView(File(AtlasData.assetPath).readAsBytesSync()),
      File(HistoricAtlas.assetPath).readAsStringSync(),
      File(PlaceYears.assetPath).readAsStringSync(),
    );
    final key = GlobalKey();
    for (final locale in const [Locale('en'), Locale('tr')]) {
      await tester.pumpWidget(
        host(
          registry,
          SiegePlayer(siege: siege, atlas: Future.value(atlas)),
          key,
          locale: locale,
        ),
      );
      final player = tester.state<SiegePlayerState>(find.byType(SiegePlayer));
      await tester.runAsync(() async {
        for (var i = 0; i < 100 && player.base == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pumpAndSettle();
      final c = player.controller;
      if (locale.languageCode == 'en') {
        await shot(tester, key, 'xix-open');
        c.play();
        for (final t in [1.0, 4.0, 7.0, 11.0]) {
          c.advance(t - c.seconds);
          await tester.pump();
          await shot(tester, key, 'xix-reveal-${t.toStringAsFixed(1)}s');
        }
        c.advance(60);
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < siege.stills.length; i++) {
        c.stills(i);
        await tester.pumpAndSettle();
        await shot(
          tester,
          key,
          'xix-${siege.stills[i]}-${locale.languageCode}',
        );
      }
      if (locale.languageCode == 'en') {
        c.goTo(siege.beat('overland'));
        player.controls(SiegePanel.accounts);
        await tester.pumpAndSettle();
        await shot(tester, key, 'xix-accounts-overland');
        await tester.tap(
          find.byKey(const ValueKey('siege-original-ships-overland')),
        );
        await settleImages(tester);
        await shot(tester, key, 'xix-original-overland');
        Navigator.of(
          tester.element(find.byType(SiegePlayer, skipOffstage: false)),
        ).pop();
        await tester.pumpAndSettle();
        player.closeControls();
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox());
    }
  });
}
