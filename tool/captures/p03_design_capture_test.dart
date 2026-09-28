// Widget tests live under tool/captures to keep capture generation opt-in.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/content/bundled_content.dart';
import 'package:milion/content/repository.dart';
import 'package:milion/design/design_sheet.dart';
import 'package:milion/design/theme.dart';
import 'package:milion/design/tokens.dart';

import '../../test/design/design_contract_test.dart' show contrast;

import 'package:milion/l10n/strings.dart';
import 'package:milion/main.dart';
import 'package:milion/screens/anastasis_relief_screen.dart';
import 'package:milion/screens/last_judgment_relief_screen.dart';
import 'package:milion/screens/scan_tab.dart';
import 'package:milion/services/classifier.dart';
import 'package:milion/widgets/scene_detail_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test/frontier_navigation_test.dart'
    show loadThemeFonts, ready, destination;
import '../../test/scene_explorer_test.dart'
    show assetsReady, openGesture, visibleTap;

const out = 'studio/captures/P03';
Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  expect(tester.takeException(), isNull, reason: name);
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    File('$out/$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
    image.dispose();
  });
}

Widget harness(
  Widget home, {
  bool lamp = false,
  String language = 'en',
  double scale = 1,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: lamp ? DesignTheme.lamp : DesignTheme.marble,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: home,
);

void main() {
  test('P03 contrast evidence from runtime themes', () {
    final records = <Map<String, Object>>[];
    for (final (name, theme) in [
      ('marble', DesignTheme.marble),
      ('lamp', DesignTheme.lamp),
    ]) {
      final c = theme.extension<MeasureColors>()!, s = theme.colorScheme;
      for (final (bgName, bg) in [('ground', c.ground), ('poche', c.poche)]) {
        for (final (fgName, fg) in [
          ('ink', c.ink),
          ('secondary', c.secondary),
          ('accent', c.accent),
        ]) {
          final ratio = contrast(fg, bg);
          expect(ratio, greaterThanOrEqualTo(4.5));
          records.add({
            'scheme': name,
            'foreground': fgName,
            'background': bgName,
            'ratio': ratio,
          });
        }
      }
      for (final (label, a, b) in [
        ('primary', s.primary, s.onPrimary),
        ('error', s.error, s.onError),
        ('collected-chip', Pigment.gold, Pigment.lamp),
        ('collected-numeral', Pigment.porphyry, Pigment.gold),
      ]) {
        final ratio = contrast(a, b);
        expect(ratio, greaterThanOrEqualTo(4.5));
        records.add({'scheme': name, 'pair': label, 'ratio': ratio});
      }
    }
    File('$out/contrast.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(records)}\n',
    );
  });
  testWidgets('P03 shipped phone surfaces at 360, 390, 430 dp and 200% EN/TR', (
    tester,
  ) async {
    Directory(out).createSync(recursive: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await loadThemeFonts(tester);
    for (final width in [360.0, 390.0, 430.0]) {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      for (final language in ['en', 'tr']) {
        for (final scale in [1.0, 2.0]) {
          SharedPreferences.setMockInitialValues({'milion_language': language});
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          final key = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(key: key, child: const MilionApp()),
          );
          await ready(tester);
          final label = '${width.toInt()}-$language-${(scale * 100).round()}';
          await capture(tester, key, 'home-$label');
          await tester.tap(
            destination(language == 'en' ? 'Collection' : 'Koleksiyon'),
          );
          await ready(tester);
          await capture(tester, key, 'collection-$label');
          await tester.tap(
            destination(language == 'en' ? 'About' : 'Hakkında'),
          );
          await tester.pumpAndSettle();
          await capture(tester, key, 'about-$label');
          await tester.scrollUntilVisible(
            find.byType(DropdownButtonFormField<ThemeMode>),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await capture(tester, key, 'settings-$label');
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    }
  });
  testWidgets(
    'P03 direction trials, lamp home, complete design galleries and scanner',
    (tester) async {
      Directory(out).createSync(recursive: true);
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      await loadThemeFonts(tester);
      for (final lamp in [false, true]) {
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: harness(TodayDirection(lampFirst: lamp)),
          ),
        );
        await ready(tester);
        await capture(tester, key, 'direction-${lamp ? 'A' : 'B'}-390');
        // The proposed composition links to a real, original-first artwork view.
        await tester.tap(find.byType(Image).first);
        await assetsReady(tester);
        expect(find.byType(AnastasisReliefScreen), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        for (final scale in [1.0, 2.0]) {
          final sheetKey = GlobalKey();
          // An unconstrained vertical sheet records all components, not just the first viewport.
          await tester.pumpWidget(
            harness(
              Scaffold(
                body: SingleChildScrollView(
                  child: RepaintBoundary(
                    key: sheetKey,
                    child: DesignGallery(lamp: lamp, scale: scale),
                  ),
                ),
              ),
              lamp: lamp,
              language: 'tr',
              scale: scale,
            ),
          );
          await tester.pumpAndSettle();
          await capture(
            tester,
            sheetKey,
            'design-${lamp ? 'lamp' : 'marble'}-${(scale * 100).round()}',
          );
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
      SharedPreferences.setMockInitialValues({'milion_scheme': 'lamp'});
      final lampKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: lampKey, child: const MilionApp()),
      );
      await ready(tester);
      await capture(tester, lampKey, 'home-lamp-390');
      await tester.pumpWidget(const SizedBox.shrink());
      final classifier = Classifier();
      final cameraKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: cameraKey,
          child: harness(
            ScanTab(classifier: classifier),
            language: 'tr',
            scale: 2,
          ),
        ),
      );
      await ready(tester);
      await capture(tester, cameraKey, 'scanner-unavailable-tr-200');
      await tester.pumpWidget(const SizedBox.shrink());
      classifier.close();
    },
  );
  testWidgets('P03 lamp artworks, labels, detail callout and 200% note sheet', (
    tester,
  ) async {
    Directory(out).createSync(recursive: true);
    addTearDown(tester.view.reset);
    await loadThemeFonts(tester);
    tester.view.devicePixelRatio = 1;
    for (final (name, home) in [
      ('anastasis', const AnastasisReliefScreen()),
      ('judgment', const LastJudgmentReliefScreen()),
    ]) {
      for (final width in [360.0, 390.0, 430.0]) {
        for (final scale in [1.0, 2.0]) {
          tester.view.physicalSize = Size(width, 844);
          final key = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: key,
              child: harness(home, scale: scale),
            ),
          );
          await assetsReady(tester);
          await capture(
            tester,
            key,
            '$name-${width.toInt()}-${(scale * 100).round()}',
          );
          if (width == 390 && scale == 1) {
            await tester.tap(find.byType(DropdownButtonFormField<String>));
            await tester.pumpAndSettle();
            await tester.tap(
              find.text(name == 'anastasis' ? 'Christ' : 'Deesis').last,
            );
            await tester.pumpAndSettle();
            await capture(tester, key, '$name-detail');
            await visibleTap(tester, 'Reconstruction');
            await assetsReady(tester);
            await capture(tester, key, '$name-reconstruction');
            await visibleTap(tester, 'Original');
            await tester.pumpAndSettle();
            await openGesture(tester);
            await visibleTap(tester, 'Play one gesture');
            await tester.pump();
            await tester.pump(const Duration(seconds: 2));
            await capture(tester, key, '$name-imagined');
          }
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    }
    tester.view.physicalSize = const Size(360, 844);
    SharedPreferences.setMockInitialValues({
      'scene_note_F02': 'P03 · Âdem / Η ΑΝΑϹΤΑϹΙϹ',
    });
    final registry = await tester.runAsync(
      () => ContentRepository((path) => File(path).readAsString()).load(),
    );
    final scene = sceneForArtwork(
      registry!.artworks.firstWhere((a) => a.id == 'F02'),
    );
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: harness(
          Scaffold(body: SceneDetailSheet(scene: scene)),
          language: 'tr',
          scale: 2,
        ),
      ),
    );
    await ready(tester);
    await tester.ensureVisible(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'P03 · Âdem / Η ΑΝΑϹΤΑϹΙϹ');
    await tester.ensureVisible(find.text('Notu kaydet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notu kaydet'));
    await tester.pumpAndSettle();
    await capture(tester, key, 'note-tr-200');
    expect(find.text('Kaydedildi'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('scene_note_F02'),
      'P03 · Âdem / Η ΑΝΑϹΤΑϹΙϹ',
    );
  });
}
