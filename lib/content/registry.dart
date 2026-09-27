import 'geography.dart';
import 'json_reader.dart';
import 'models.dart';

const contentSchemaVersion = 1;
const recordKinds = [
  'places',
  'artworks',
  'milestones',
  'sources',
  'media',
  'routes',
  'hunts',
];

/// A complete immutable snapshot. Public place queries exclude drafts by default.
class ContentRegistry {
  ContentRegistry._(Json data)
    : places = _records(data, 'places', Place.fromJson),
      artworks = _records(data, 'artworks', Artwork.fromJson),
      milestones = _records(data, 'milestones', Milestone.fromJson),
      sources = _records(data, 'sources', Source.fromJson),
      media = _records(data, 'media', Media.fromJson),
      routes = _records(data, 'routes', Route.fromJson),
      hunts = _records(data, 'hunts', Hunt.fromJson);
  factory ContentRegistry.fromJson(Json data) {
    final report = validateContent(data);
    if (!report.isValid) throw FormatException(report.errors.join('\n'));
    return ContentRegistry._(data);
  }
  final List<Place> places;
  final List<Artwork> artworks;
  final List<Milestone> milestones;
  final List<Source> sources;
  final List<Media> media;
  final List<Route> routes;
  final List<Hunt> hunts;

  List<Place> placesByDistance({bool includeDrafts = false}) =>
      [
        for (final p in places)
          if (includeDrafts || p.review == ReviewStatus.reviewed) p,
      ]..sort((a, b) {
        final distance = fromMilion(a).km.compareTo(fromMilion(b).km);
        return distance == 0 ? a.id.compareTo(b.id) : distance;
      });

  Artwork artwork(String id) => artworks.firstWhere((a) => a.id == id);
}

List<T> _records<T>(Json data, String kind, T Function(Json) parse) =>
    List.unmodifiable((data[kind] as List).map((j) => parse(j as Json)));

class ValidationReport {
  final List<String> errors = [];
  final List<String> missingTurkish = [];
  int localizedCount = 0;
  final Map<String, int> categories = {
    for (final c in Category.values) c.name: 0,
  };
  final Map<String, int> districts = {
    for (final d in District.values) d.name: 0,
    'outside': 0,
  };
  final Map<String, int> eras = {for (final e in Era.values) e.name: 0};
  final Map<String, int> waves = {for (final w in Wave.values) w.name: 0};
  bool get isValid => errors.isEmpty;
}

ValidationReport validateContent(Json data) {
  final report = ValidationReport();
  void error(String message) => report.errors.add(message);
  if (data['schemaVersion'] is! int ||
      data['schemaVersion'] != contentSchemaVersion) {
    error(
      'Unsupported schemaVersion: ${data['schemaVersion']} (expected $contentSchemaVersion)',
    );
  }
  for (final key in data.keys) {
    if (key != 'schemaVersion' && !recordKinds.contains(key)) {
      error('Unknown root field: $key');
    }
  }
  final ids = <String>{};
  final byKind = <String, Set<String>>{};
  final parsed = <String, List<dynamic>>{};
  final parsers = <String, dynamic Function(Json)>{
    'places': Place.fromJson,
    'artworks': Artwork.fromJson,
    'milestones': Milestone.fromJson,
    'sources': Source.fromJson,
    'media': Media.fromJson,
    'routes': Route.fromJson,
    'hunts': Hunt.fromJson,
  };
  void localizations(dynamic value, String path) {
    if (value is Map) {
      if (value.containsKey('en')) {
        report.localizedCount++;
        if (value['tr'] == null ||
            (value['tr'] is String && (value['tr'] as String).trim().isEmpty)) {
          report.missingTurkish.add(path);
        }
      }
      value.forEach((key, child) => localizations(child, '$path.$key'));
    } else if (value is List) {
      for (var i = 0; i < value.length; i++) {
        localizations(value[i], '$path[$i]');
      }
    }
  }

  localizations(data, 'content');
  for (final kind in recordKinds) {
    byKind[kind] = {};
    parsed[kind] = [];
    final records = data[kind];
    if (records is! List) {
      error('$kind must be an array');
      continue;
    }
    for (var i = 0; i < records.length; i++) {
      final j = records[i];
      final path = '$kind[$i]';
      if (j is! Json) {
        error('$path must be an object');
        continue;
      }
      final id = j['id'];
      if (id is! String ||
          !RegExp(
            kind == 'artworks'
                ? r'^(?:[MF]\d{2,3}|M49_[1-4]|[a-z][a-z0-9]*(?:-[a-z0-9]+)*)$'
                : r'^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$',
          ).hasMatch(id)) {
        error('$path invalid id: $id');
      } else {
        if (!ids.add(id)) error('$path duplicate global id: $id');
        byKind[kind]!.add(id);
      }
      for (final key in [
        'categories',
        'eras',
        'techniques',
        'honesty',
        'tags',
      ]) {
        if (j[key] is List &&
            (j[key] as List).toSet().length != (j[key] as List).length) {
          error('$path.$key contains duplicates');
        }
      }
      try {
        parsed[kind]!.add(parsers[kind]!(j));
      } catch (e) {
        error('$path ($id): $e');
      }
    }
  }
  void refs(
    String owner,
    Iterable<String> values,
    String kind, {
    bool required = false,
  }) {
    if (required && values.isEmpty) error('$owner requires $kind');
    for (final id in values) {
      if (!byKind[kind]!.contains(id)) {
        error('$owner references unknown $kind id: $id');
      }
    }
  }

  void coordinate(String owner, Coordinates p, bool outside) {
    if (p.lat.abs() > 90 || p.lng.abs() > 180) {
      error('$owner invalid world coordinates');
    }
    if (!outside && !insideIstanbulBounds(p)) {
      error('$owner outside Istanbul bounds without outsideProvince flag');
    }
  }

  final strataIds = <String>{};
  final qids = <String>{};
  for (final p in parsed['places']!.cast<Place>()) {
    if (!RegExp(r'^Q[1-9]\d*$').hasMatch(p.qid)) {
      error('${p.id} invalid Wikidata QID');
    }
    if (!qids.add(p.qid)) {
      error('${p.id} duplicates place QID ${p.qid}; use a layered record');
    }
    if (p.categories.isEmpty || p.eras.isEmpty) {
      error('${p.id} requires a category and era');
    }
    if (p.district == null && !p.outsideProvince) {
      error('${p.id} requires a known district');
    }
    if (p.outsideProvince && p.district != null) {
      error('${p.id} outside bonus must not claim an Istanbul district');
    }
    if (!RegExp(r'^P\d{2}$').hasMatch(p.reviewPhase)) {
      error('${p.id} invalid reviewPhase');
    }
    coordinate(p.id, p.coordinates, p.outsideProvince);
    if (p.entrance != null) {
      coordinate('${p.id}.entrance', p.entrance!, p.outsideProvince);
    }
    if (p.status.value != PlaceStatus.unknown && p.status.checkedAt == null) {
      error('${p.id} known status requires checkedAt');
    }
    if (p.review == ReviewStatus.reviewed &&
        (p.entrance == null || p.status.checkedAt == null)) {
      error('${p.id} reviewed place needs verified entrance and dated status');
    }
    refs(p.id, p.sourceIds, 'sources', required: true);
    for (final c in p.categories) {
      report.categories[c.name] = report.categories[c.name]! + 1;
    }
    final district = p.district?.name ?? 'outside';
    report.districts[district] = report.districts[district]! + 1;
    report.waves[p.wave.name] = report.waves[p.wave.name]! + 1;
    final eras = <Era>{...p.eras};
    for (final s in p.strata) {
      if (!strataIds.add(s.id) || ids.contains(s.id)) {
        error('Duplicate stratum id ${s.id}');
      }
      if (!RegExp(r'^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$').hasMatch(s.id)) {
        error('Invalid stratum id ${s.id}');
      }
      if (s.toYear != null && s.fromYear > s.toYear!) {
        error('${s.id} reversed year range');
      }
      refs(s.id, s.mediaIds, 'media');
      refs(s.id, s.sourceIds, 'sources', required: true);
      eras.add(s.era);
    }
    // Count each place once per era, including name evidence before full strata are authored.
    eras.addAll(p.historicalNames.map((n) => n.era));
    for (final era in eras) {
      report.eras[era.name] = report.eras[era.name]! + 1;
    }
  }
  for (final a in parsed['artworks']!.cast<Artwork>()) {
    refs(a.id, [a.placeId], 'places');
    refs(a.id, a.mediaIds, 'media');
    refs(a.id, a.sourceIds, 'sources', required: true);
  }
  final numerals = <String>{};
  for (final m in parsed['milestones']!.cast<Milestone>()) {
    if (!numerals.add(m.numeral) ||
        ![for (var n = 0; n < 48; n++) romanNumeral(n)].contains(m.numeral)) {
      error('${m.id} duplicate or invalid numeral ${m.numeral}');
    }
    if (m.techniques.isEmpty || !m.honesty.contains(Honesty.ORIGINAL)) {
      error('${m.id} requires techniques and ORIGINAL');
    }
    if (m.status != MilestoneStatus.planned && m.manifestPath == null) {
      error('${m.id} requires a manifest');
    }
    if (m.manifestPath != null && !safeAssetPath(m.manifestPath!)) {
      error('${m.id} unsafe manifest path');
    }
    if (!RegExp(r'^[a-z][a-z0-9-]*$').hasMatch(m.packId)) {
      error('${m.id} invalid packId');
    }
    refs(m.id, m.placeIds, 'places');
    refs(m.id, m.artworkIds, 'artworks');
    refs(m.id, m.sourceIds, 'sources', required: true);
    for (final a in parsed['artworks']!.cast<Artwork>().where(
      (a) => m.artworkIds.contains(a.id),
    )) {
      if (!m.placeIds.contains(a.placeId)) {
        error('${m.id} artwork ${a.id} belongs to an unlisted place');
      }
    }
  }
  for (final s in parsed['sources']!.cast<Source>()) {
    final url = Uri.tryParse(s.url);
    if (url == null ||
        !['http', 'https'].contains(url.scheme) ||
        url.host.isEmpty) {
      error('${s.id} invalid source URL');
    }
  }
  for (final m in parsed['media']!.cast<Media>()) {
    if (!safeAssetPath(m.path)) error('${m.id} unsafe media path');
    if (m.historicalPhoto && m.kind != MediaKind.image) {
      error('${m.id} historicalPhoto only applies to images');
    }
    refs(m.id, [m.sourceId], 'sources');
  }
  for (final r in parsed['routes']!.cast<Route>()) {
    refs(r.id, r.placeIds, 'places', required: true);
    refs(r.id, r.sourceIds, 'sources', required: true);
  }
  for (final h in parsed['hunts']!.cast<Hunt>()) {
    refs(h.id, [h.routeId], 'routes');
    refs(h.id, h.artworkIds, 'artworks');
    refs(h.id, h.sourceIds, 'sources', required: true);
    if (h.clues.isEmpty) error('${h.id} requires clues');
  }
  return report;
}

bool safeAssetPath(String path) =>
    path.startsWith('assets/') &&
    !path.contains('\\') &&
    !path.split('/').any((s) => s.isEmpty || s == '..' || s == '.');
