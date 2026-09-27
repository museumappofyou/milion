import 'dart:convert';

import 'package:milion/models/scene.dart';
import 'package:milion/screens/last_judgment_relief_screen.dart';
import 'package:milion/screens/scene_explorer_screen.dart';
import 'package:milion/screens/last_judgment_tab.dart';
import 'package:milion/screens/scenes_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

Future<img.Image> decode(String path) async =>
    img.decodeImage((await rootBundle.load(path)).buffer.asUint8List())!;

Future<void> settleAssets(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'F05 assets share the source grid, with bounded focus windows',
    () async {
      final manifest = jsonDecode(
        await rootBundle.loadString(
          'assets/last_judgment/relief_v5/manifest.json',
        ),
      ) as Map<String, dynamic>;
      expect(manifest['sceneId'], 'F05');
      final source = await decode(manifest['master'] as String);
      expect([source.width, source.height], manifest['size']);
      for (final view in manifest['views'] as List) {
        final frame = await decode(view['file'] as String);
        if (view['id'] != 'side') {
          expect([frame.width, frame.height], manifest['size']);
        }
      }
      for (final focus in manifest['focus'] as List) {
        final r = focus['rect'] as List?;
        if (r == null) continue;
        expect(r[0], greaterThanOrEqualTo(0));
        expect(r[1], greaterThanOrEqualTo(0));
        expect(r[2], lessThanOrEqualTo(source.width));
        expect(r[3], lessThanOrEqualTo(source.height));
        expect(r[2], greaterThan(r[0]));
        expect(r[3], greaterThan(r[1]));
      }
    },
  );

  test(
    'relief retains source color and separates meaningful depth groups',
    () async {
      final original = await decode('assets/last_judgment/vault_reference.jpg');
      final relief = await decode(
        'assets/last_judgment/relief_v5/relief_front.jpg',
      );
      final semantic = await decode(
        'assets/last_judgment/relief_v5/semantic_layers.png',
      );
      var samples = 0, glow = 0, changed = 0;
      final left = <int>{}, right = <int>{};
      for (var y = 3; y < original.height; y += 7) {
        for (var x = 3; x < original.width; x += 7) {
          final o = original.getPixel(x, y), r = relief.getPixel(x, y);
          final lo = o.r + o.g + o.b, lr = r.r + r.g + r.b;
          samples++;
          if (lr > lo * 1.08 + 18) glow++;
          if ((lr - lo).abs() > 12) changed++;
          final p = semantic.getPixel(x, y);
          (x < original.width / 2 ? left : right).add(
            (p.r.toInt() << 16) | (p.g.toInt() << 8) | p.b.toInt(),
          );
        }
      }
      expect(glow / samples, lessThan(.01));
      expect(changed / samples, greaterThan(.12));
      for (final side in [left, right]) {
        expect(side, containsAll([0x7c48aa, 0x3c6ed7, 0x28aa50]));
      }
      expect({...left, ...right}, containsAll([0xf58c1e, 0x28d7e1, 0xe12828]));
    },
  );

  testWidgets('Judgment tab opens relief, focus comparison and references', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LastJudgmentTab()));
    await settleAssets(tester);
    await tester.scrollUntilVisible(
      find.text('Explore painted relief'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore painted relief'));
    await settleAssets(tester);
    expect(find.byType(LastJudgmentReliefScreen), findsOneWidget);
    final explorer = tester.state<SceneExplorerScreenState>(
      find.byType(SceneExplorerScreen),
    );
    await tester.tap(find.text('Original'));
    await tester.pumpAndSettle();
    expect(explorer.variant, 'Original');
    await tester.ensureVisible(find.text('Christ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Christ'));
    await tester.pumpAndSettle();
    expect(explorer.selectedDetail, 'christ');
    expect(explorer.zoom, greaterThan(1));
    await tester.tap(find.byTooltip('Reset view'));
    await tester.pumpAndSettle();
    expect(explorer.selectedDetail, isNull);
    expect(explorer.zoom, closeTo(1, .001));
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('The prepared throne'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('The prepared throne'));
    await settleAssets(tester);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('Photograph: Caner Cangül'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'F05 catalog action opens its relief without changing F02 routing',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      var opened = '';
      await tester.pumpWidget(
        MaterialApp(
          home: ScenesTab(
            scenes: const [
              Scene(
                id: 'F02',
                title: 'Anastasis',
                room: 'Parekklesion',
                surface: 'dome',
                folder: '',
              ),
              Scene(
                id: 'F05',
                title: 'Last Judgment',
                room: 'Parekklesion',
                surface: 'vault',
                folder: '',
              ),
            ],
            onExamineAnastasis: () => opened = 'F02',
            onExamineLastJudgment: () => opened = 'F05',
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final (title, id) in [
        ('Last Judgment', 'F05'),
        ('Anastasis', 'F02'),
      ]) {
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Explore painted relief'));
        await tester.pumpAndSettle();
        expect(opened, id);
      }
    },
  );
}
