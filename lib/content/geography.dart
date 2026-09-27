import 'dart:math' as math;

import 'models.dart';

/// Wikidata Q1187329, P625. Evidence and revision in sources.json.
const milion = Coordinates(41.008043, 28.978066);
const earthRadiusKm = 6371.0088; // IUGG mean Earth radius, spherical distance.
/// Approximation, not a claim that ancient routes followed a great circle.
/// Calderini, “Miglio”, Enciclopedia Italiana (1934), sources: roman-mile.
const romanMileKm = 1.480;

class MileMeasurement {
  const MileMeasurement(this.km, this.bearing);
  final double km;

  /// Initial bearing clockwise from true north; null at coincident/antipodal points.
  final double? bearing;
  double get romanMiles => km / romanMileKm;
}

MileMeasurement measure(Coordinates from, Coordinates to) {
  for (final point in [from, to]) {
    if (!point.lat.isFinite ||
        !point.lng.isFinite ||
        point.lat.abs() > 90 ||
        point.lng.abs() > 180) {
      throw ArgumentError('Invalid geographic coordinates');
    }
  }
  final p1 = from.lat * math.pi / 180;
  final p2 = to.lat * math.pi / 180;
  final dl = (to.lng - from.lng) * math.pi / 180;
  final dp = p2 - p1;
  final a =
      (math.pow(math.sin(dp / 2), 2) +
              math.cos(p1) * math.cos(p2) * math.pow(math.sin(dl / 2), 2))
          .clamp(0.0, 1.0);
  final angle = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  final y = math.sin(dl) * math.cos(p2);
  final x =
      math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl);
  final bearing = angle < 1e-12 || (math.pi - angle).abs() < 1e-12
      ? null
      : (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  return MileMeasurement(earthRadiusKm * angle, bearing);
}

MileMeasurement fromMilion(Place place) => measure(milion, place.coordinates);

// Province bounding rectangle, not a polygon membership test.
// Extents from OSM Istanbul province relation 223474, see province-bounds source.
bool insideIstanbulBounds(Coordinates p) =>
    p.lat >= 40.7376735 &&
    p.lat <= 41.671 &&
    p.lng >= 27.9708481 &&
    p.lng <= 29.9588048;

String romanNumeral(int value) {
  if (value < 0) throw ArgumentError.value(value);
  if (value == 0) return '0'; // No invented Roman zero glyph.
  final result = StringBuffer();
  for (final pair in [
    (1000, 'M'),
    (900, 'CM'),
    (500, 'D'),
    (400, 'CD'),
    (100, 'C'),
    (90, 'XC'),
    (50, 'L'),
    (40, 'XL'),
    (10, 'X'),
    (9, 'IX'),
    (5, 'V'),
    (4, 'IV'),
    (1, 'I'),
  ]) {
    while (value >= pair.$1) {
      result.write(pair.$2);
      value -= pair.$1;
    }
  }
  return result.toString();
}

/// Roman miles round to the nearest integer; km retain one decimal.
/// Distances below half a Roman mile use “< I”; only the origin displays “0”.
String formatMilDistance(double km, {String language = 'en'}) {
  if (!km.isFinite || km < 0) throw ArgumentError.value(km);
  final miles = km / romanMileKm;
  final roman = km == 0
      ? '0'
      : miles < .5
      ? '< I'
      : romanNumeral(miles.round());
  final parts = km.toStringAsFixed(1).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => language == 'tr' ? '.' : ',',
  );
  return '$roman mil · $whole${language == 'tr' ? ',' : '.'}${parts[1]} km';
}
