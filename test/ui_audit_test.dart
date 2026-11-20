import 'package:flutter_test/flutter_test.dart';
import 'package:milion/atlas/atlas_filter.dart';
import 'package:milion/content/models.dart';
import 'package:milion/content/registry.dart';

import 'p04_content_test.dart' show loadRegistry;

/// Regressions from the 2026-11-20 audit of the Gemini UI session.
void main() {
  late ContentRegistry registry;
  setUpAll(() async => registry = await loadRegistry());

  test('search folds Turkish letters both ways', () {
    expect(foldForSearch('Şehzade'), 'sehzade');
    expect(foldForSearch('KÜÇÜK AYASOFYA'), 'kucuk ayasofya');
    expect(foldForSearch('İstanbul'), 'istanbul');
    expect(foldForSearch('Istanbul'), 'istanbul');
    expect(foldForSearch('Ağa Kapısı'), 'aga kapisi');
  });

  test('ASCII queries find Turkish-named places', () {
    Place byId(String id) => registry.place(id)!;
    expect(placeMatchesQuery(byId('sehzade'), 'sehzade'), isTrue);
    expect(placeMatchesQuery(byId('little-hagia-sophia'), 'kucuk'), isTrue);
    expect(placeMatchesQuery(byId('chora'), 'sehzade'), isFalse);
  });
}
