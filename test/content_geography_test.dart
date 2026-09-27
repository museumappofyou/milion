import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:milion/content/geography.dart';
import 'package:milion/content/models.dart';

void main() {
  test('two places match GeographicLib and independently calculated vector references', () {
    final data = jsonDecode(
      File('test/fixtures/content/geography.json').readAsStringSync(),
    );
    for (final row in data['records']) {
      final m = measure(milion, Coordinates(row['lat'], row['lng']));
      for (final method in ['geographicLib', 'vector']) {
        expect(m.km, closeTo(row[method]['km'], 1e-8));
        expect(m.bearing, closeTo(row[method]['bearing'], 1e-8));
      }
      expect(m.romanMiles * 1.480, closeTo(m.km, 1e-12));
    }
  });
  test('zero, poles, antimeridian and antipodes stay finite', () {
    final zero = measure(milion, milion);
    expect(zero.km, 0);
    expect(zero.bearing, isNull);
    expect(
      measure(
        const Coordinates(0, 179.9),
        const Coordinates(0, -179.9),
      ).bearing,
      closeTo(90, 1e-9),
    );
    expect(
      measure(const Coordinates(0, 0), const Coordinates(0, 180)).bearing,
      isNull,
    );
    expect(
      measure(const Coordinates(90, 0), const Coordinates(80, 0)).km.isFinite,
      isTrue,
    );
    expect(
      () => measure(const Coordinates(91, 0), milion),
      throwsArgumentError,
    );
  });
  test('Roman miles round explicitly; EN/TR decimals and grouping differ', () {
    expect(formatMilDistance(5.9, language: 'tr'), 'IV mil · 5,9 km');
    expect(formatMilDistance(5.9), 'IV mil · 5.9 km');
    expect(formatMilDistance(0), '0 mil · 0.0 km');
    expect(formatMilDistance(.2), '< I mil · 0.2 km');
    expect(formatMilDistance(1480, language: 'tr'), 'M mil · 1.480,0 km');
    expect(formatMilDistance(1480), 'M mil · 1,480.0 km');
    expect(romanNumeral(47), 'XLVII');
    expect(() => formatMilDistance(-1), throwsArgumentError);
  });
}
