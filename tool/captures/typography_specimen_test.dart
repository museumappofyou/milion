import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const specimen =
    'İstanbul Ayasofya Süleymaniye Eyüpsultan Kılıç Ali Paşa Şehzadebaşı ığüşöçİĞÜŞÖÇ · Η ΑΝΑϹΤΑϹΙϹ ΙϹ ΧϹ · XLVII · 3,4 mil';
const display = [
  'cinzel',
  'forum',
  'marcellus',
  'gfsneohellenic',
  'notoserifdisplay',
];
const body = [
  'literata',
  'sourceserif4',
  'alegreya',
  'notoserif',
  'notosans',
  'ibmplexsans',
];
void main() {
  testWidgets('P03 requested font specimens', (tester) async {
    await tester.runAsync(() async {
      for (final family in [...display, ...body]) {
        final bytes = await File('studio/design/fonts/$family.ttf')
            .readAsBytes();
        await (FontLoader(
          family,
        )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      }
    });
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (name, families) in [('display', display), ('text', body)]) {
      tester.view.physicalSize = Size(1000, families.length * 268);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: const Color(0xFFEEE7DB),
              body: Column(
                children: [
                  for (final family in families)
                    Container(
                      height: 268,
                      width: 1000,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF4E1B2B)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            family,
                            style: const TextStyle(
                              fontFamily: 'notosans',
                              fontSize: 16,
                              color: Color(0xFF4E1B2B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            specimen,
                            style: TextStyle(
                              fontFamily: family,
                              fontSize: name == 'display' ? 28 : 20,
                              height: 1.4,
                              color: const Color(0xFF151314),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'MİLİON · XLVII · 3,4 mil    Η ΑΝΑϹΤΑϹΙϹ',
                            style: TextStyle(
                              fontFamily: family,
                              fontSize: 32,
                              color: const Color(0xFF4E1B2B),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('studio/captures/P03/type-$name.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }
  });
}
