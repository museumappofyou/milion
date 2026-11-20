import 'dart:convert';

import 'package:flutter/foundation.dart' hide Category;

import '../content/json_reader.dart';
import '../content/models.dart';
import '../content/registry.dart';

/// The City tab's filters, shared by the map and the list so both always
/// show the same places (P10: map/list parity). An empty set means "any".
@immutable
class AtlasFilter {
  const AtlasFilter({
    this.waves = const {},
    this.eras = const {},
    this.categories = const {},
    this.districts = const {},
    this.openNow = false,
    this.hasMilestone = false,
    this.reviewedOnly = false,
    this.interactiveOnly = false,
  });
  final Set<Wave> waves;
  final Set<Era> eras;
  final Set<Category> categories;
  final Set<District> districts;

  /// Only places whose structured week has them open now (Istanbul time);
  /// places without one are left out, not guessed.
  final bool openNow;

  /// Only places a register Milestone belongs to.
  final bool hasMilestone;

  /// Only deeply authored places (`ReviewStatus.reviewed`).
  final bool reviewedOnly;

  /// Only places hosting a playable Milestone, 3D study, or floor-plan guide.
  final bool interactiveOnly;

  static const none = AtlasFilter();

  int get activeCount =>
      (waves.isEmpty ? 0 : 1) +
      (eras.isEmpty ? 0 : 1) +
      (categories.isEmpty ? 0 : 1) +
      (districts.isEmpty ? 0 : 1) +
      (openNow ? 1 : 0) +
      (hasMilestone ? 1 : 0) +
      (reviewedOnly ? 1 : 0) +
      (interactiveOnly ? 1 : 0);

  bool get isEmpty => activeCount == 0;

  AtlasFilter copyWith({
    Set<Wave>? waves,
    Set<Era>? eras,
    Set<Category>? categories,
    Set<District>? districts,
    bool? openNow,
    bool? hasMilestone,
    bool? reviewedOnly,
    bool? interactiveOnly,
  }) => AtlasFilter(
    waves: waves ?? this.waves,
    eras: eras ?? this.eras,
    categories: categories ?? this.categories,
    districts: districts ?? this.districts,
    openNow: openNow ?? this.openNow,
    hasMilestone: hasMilestone ?? this.hasMilestone,
    reviewedOnly: reviewedOnly ?? this.reviewedOnly,
    interactiveOnly: interactiveOnly ?? this.interactiveOnly,
  );

  bool matches(
    Place p, {
    required DateTime now,
    required Set<String> milestonePlaces,
    Set<String> interactivePlaces = const {},
  }) =>
      (waves.isEmpty || waves.contains(p.wave)) &&
      (eras.isEmpty || p.eras.any(eras.contains)) &&
      (categories.isEmpty || p.categories.any(categories.contains)) &&
      (districts.isEmpty ||
          (p.district != null && districts.contains(p.district))) &&
      (!openNow || isOpenAt(p.visit?.weekly ?? const [], now) == true) &&
      (!hasMilestone || milestonePlaces.contains(p.id)) &&
      (!reviewedOnly || p.review == ReviewStatus.reviewed) &&
      (!interactiveOnly || interactivePlaces.contains(p.id));

  /// For restoration: names only, so a renamed enum value drops silently.
  String encode() => jsonEncode({
    'waves': [for (final w in waves) w.name],
    'eras': [for (final e in eras) e.name],
    'categories': [for (final c in categories) c.name],
    'districts': [for (final d in districts) d.name],
    'openNow': openNow,
    'hasMilestone': hasMilestone,
    'reviewedOnly': reviewedOnly,
    'interactiveOnly': interactiveOnly,
  });

  static AtlasFilter decode(String? text) {
    if (text == null) return none;
    try {
      final j = jsonDecode(text) as Json;
      Set<T> names<T extends Enum>(String key, List<T> values) => {
        for (final n in (j[key] as List? ?? const []))
          if (values.asNameMap()[n] case final T v) v,
      };
      return AtlasFilter(
        waves: names('waves', Wave.values),
        eras: names('eras', Era.values),
        categories: names('categories', Category.values),
        districts: names('districts', District.values),
        openNow: j['openNow'] == true,
        hasMilestone: j['hasMilestone'] == true,
        reviewedOnly: j['reviewedOnly'] == true,
        interactiveOnly: j['interactiveOnly'] == true,
      );
    } on Object {
      return none;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is AtlasFilter &&
      setEquals(other.waves, waves) &&
      setEquals(other.eras, eras) &&
      setEquals(other.categories, categories) &&
      setEquals(other.districts, districts) &&
      other.openNow == openNow &&
      other.hasMilestone == hasMilestone &&
      other.reviewedOnly == reviewedOnly &&
      other.interactiveOnly == interactiveOnly;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(waves),
    Object.hashAllUnordered(eras),
    Object.hashAllUnordered(categories),
    Object.hashAllUnordered(districts),
    openNow,
    hasMilestone,
    reviewedOnly,
    interactiveOnly,
  );
}

/// Folds Turkish and Latin letters for search: İ/I/ı → i, ş → s, ğ → g,
/// ü → u, ö → o, ç → c, â/î/û → a/i/u, so "sehzade" finds "Şehzade" and
/// "istanbul" finds "İstanbul" (Dart lowercases İ to i plus a combining dot).
String foldForSearch(String text) {
  final b = StringBuffer();
  for (final r in text.runes) {
    final ch = String.fromCharCode(r);
    b.write(switch (ch) {
      'İ' || 'I' || 'ı' || 'î' || 'Î' => 'i',
      'Ş' || 'ş' => 's',
      'Ğ' || 'ğ' => 'g',
      'Ü' || 'ü' || 'û' || 'Û' => 'u',
      'Ö' || 'ö' => 'o',
      'Ç' || 'ç' => 'c',
      'Â' || 'â' => 'a',
      '\u0307' => '',
      _ => ch.toLowerCase(),
    });
  }
  return b.toString();
}

/// Case- and diacritic-insensitive text match across English, Turkish,
/// district, and historical names of [p].
bool placeMatchesQuery(Place p, String query) {
  final q = foldForSearch(query.trim());
  if (q.isEmpty) return true;
  bool has(String? text) => text != null && foldForSearch(text).contains(q);
  if (has(p.names.en) || has(p.names.tr)) return true;
  if (has(p.district?.spelling)) return true;
  for (final h in p.historicalNames) {
    if (has(h.name.en) || has(h.name.tr)) return true;
  }
  return false;
}

/// The places the City tab shows, map and list alike, nearest mile zero
/// first. The time slider never removes a place; it only changes how the
/// map draws one that did not stand yet.
List<Place> atlasPlaces(
  ContentRegistry registry,
  AtlasFilter filter,
  DateTime now, {
  Set<String> interactivePlaces = const {},
  String query = '',
}) {
  final milestonePlaces = {for (final m in registry.milestones) ...m.placeIds};
  return [
    for (final p in registry.plottablePlaces)
      if (filter.matches(
            p,
            now: now,
            milestonePlaces: milestonePlaces,
            interactivePlaces: interactivePlaces,
          ) &&
          placeMatchesQuery(p, query))
        p,
  ];
}

/// Districts that hold at least one plottable place, for the filter sheet.
List<District> atlasDistricts(ContentRegistry registry) {
  final used = {for (final p in registry.plottablePlaces) ?p.district};
  return [
    for (final d in District.values)
      if (used.contains(d)) d,
  ]..sort((a, b) => a.spelling.compareTo(b.spelling));
}

/// When each place first stood, for the time slider: Wikidata inception
/// (assets/atlas/place_years.json), else the start of its earliest era.
class PlaceYears {
  PlaceYears(this._years);
  final Map<String, int> _years;

  static const assetPath = 'assets/atlas/place_years.json';

  /// Conventional starts, used only when Wikidata has no inception.
  static const eraStart = {
    Era.ancient: -667,
    Era.roman: 196,
    Era.byzantine: 330,
    Era.medieval: 1204,
    Era.ottoman: 1453,
    Era.modern: 1923,
  };

  factory PlaceYears.fromJsonText(String text) {
    final j = jsonDecode(text) as Json;
    return decode(j, (r) {
      if (r.integer('schemaVersion') != 1 ||
          r.string('kind') != 'atlas-place-years') {
        throw const FormatException('place_years.json: wrong kind');
      }
      r.string('source');
      r.value('overrides');
      final places = r.object('places');
      return PlaceYears({
        for (final e in places.entries) e.key: (e.value as num).toInt(),
      });
    });
  }

  /// The sourced year, or null.
  int? sourced(Place p) => _years[p.id];

  /// The year the map treats the place as standing from.
  int standsFrom(Place p) =>
      _years[p.id] ??
      (p.eras.isEmpty
          ? 1923
          : p.eras.map((e) => eraStart[e]!).reduce((a, b) => a < b ? a : b));
}
