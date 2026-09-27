import 'dart:io';
import 'dart:ui' as ui;

import 'package:milion/screens/last_judgment_v5_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const out = 'last_judgment_25d/v5/flutter';

void main() {
  testWidgets('F05 fixed camera, phone and desktop captures', (tester) async {
    Directory(out).createSync(recursive: true);
    final key = GlobalKey();
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
      if (font.existsSync()) {
        final loader = FontLoader('CaptureFont')
          ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
        await loader.load();
      }
      for (final (w, h) in [
        (390.0, 844.0),
        (360.0, 800.0),
        (430.0, 932.0),
        (1440.0, 900.0),
      ]) {
        tester.view.physicalSize = Size(w, h);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: 'CaptureFont',
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1F3B73),
              ),
            ),
            home: RepaintBoundary(
              key: key,
              child: const LastJudgmentV5Screen(),
            ),
          ),
        );
        for (var i = 0; i < 30; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pump();
        }
        expect(find.byType(FixedReliefFrame), findsOneWidget);
        final size = '${w.toInt()}x${h.toInt()}';
        final center = await capture(key, 'relief_$size.png');
        if (w == 390) {
          await tester.drag(
            find.byType(FixedReliefFrame),
            const Offset(100, 50),
          );
          await tester.pump(const Duration(milliseconds: 800));
          expect(
            await capture(key, null),
            center,
            reason: 'Camera must remain frozen',
          );
          for (final focus in [
            'Overview',
            'Deesis',
            'Christ',
            'Heavens',
            'Throne',
          ]) {
            await tester.ensureVisible(find.text(focus));
            await tester.tap(find.text(focus));
            await tester.pump();
            await capture(key, '${focus.toLowerCase()}_$size.png');
            await tester.tap(find.text('Original'));
            await Future<void>.delayed(const Duration(milliseconds: 300));
            await tester.pump();
            await capture(key, '${focus.toLowerCase()}_original_$size.png');
            await tester.tap(find.text('Relief'));
            await tester.pump();
          }
          final gesture = await tester.startGesture(
            tester.getCenter(find.text('LAST JUDGMENT')),
          );
          await Future<void>.delayed(const Duration(milliseconds: 650));
          await tester.pump();
          await gesture.up();
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 500));
          await tester.tap(find.text('45° surface'));
          await tester.pump(const Duration(milliseconds: 500));
          await Future<void>.delayed(const Duration(milliseconds: 300));
          await tester.pump();
          await capture(key, 'side45_$size.png');
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });
}

Future<Uint8List> capture(GlobalKey key, String? name) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final bytes = data!.buffer.asUint8List();
  if (name != null) File('$out/$name').writeAsBytesSync(bytes);
  return bytes;
}
