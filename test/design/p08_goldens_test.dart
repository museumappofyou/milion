import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/space/player.dart';
import 'package:milion/space/style.dart';

import '../space_player_test.dart' show openStudy, space;
import 'p06_goldens_test.dart' show repaint;

void main() {
  testWidgets(
    "P08: Choisy's drawing, a stone section, night in 1548, a reduced still",
    (tester) async {
      final boundary = GlobalKey();
      Future<void> golden(String name) async {
        await repaint(tester, boundary);
        await expectLater(
          find.byType(SpacePlayer),
          matchesGoldenFile('../goldens/P08/$name.png'),
        );
      }

      await openStudy(tester, boundary: boundary);
      var c = space(tester).controller!;
      await golden('choisy-drawing');
      c
        ..setStyle(SpaceStyle.stone)
        ..setSectionAxis(1)
        ..setView(c.view.copyWith(elevation: .45));
      await tester.pump();
      await golden('stone-east-west-section');
      c
        ..setStyle(SpaceStyle.night)
        ..setEpoch(1)
        ..setSectionAxis(2)
        ..setView(c.choisyView);
      await tester.pumpAndSettle();
      await golden('night-1548');

      await tester.pumpWidget(const SizedBox.shrink());
      await openStudy(
        tester,
        boundary: boundary,
        reduced: true,
        locale: const Locale('tr'),
      );
      c = space(tester).controller!;
      c
        ..step(1)
        ..step(1)
        ..step(1);
      await tester.pump();
      await golden('reduced-pendentives-tr');
      expect(tester.takeException(), isNull);
    },
  );
}
