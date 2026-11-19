import 'dart:convert';

import '../content/json_reader.dart';
import '../content/models.dart';
import '../content/registry.dart';
import '../content/repository.dart';

/// A band of the section between two depths (metres relative to today's
/// sea level, up positive).
class SectionStratum {
  SectionStratum(JsonReader r)
    : id = r.string('id'),
      from = r.number('from'),
      to = r.number('to'),
      hatch = r.string('hatch'),
      years = Localized.fromJson(r.object('years')),
      label = Localized.fromJson(r.object('label')),
      sourceIds = r.strings('sources');
  final String id, hatch;
  final double from, to;
  final Localized years, label;
  final List<String> sourceIds;
  bool contains(double depth) => depth <= from && depth >= to;
}

/// Something found in a stratum, drawn as a card that pops up.
class SectionFind {
  SectionFind(JsonReader r)
    : id = r.string('id'),
      kind = r.string('kind'),
      depth = r.number('depth'),
      x = r.number('x'),
      length = r.optionalNumber('length') ?? .12,
      label = Localized.fromJson(r.object('label')),
      photo = r.optionalString('photo'),
      sourceIds = r.strings('sources');
  final String id, kind;
  final double depth, x, length;
  final Localized label;

  /// A media id: a photograph of the find (ORIGINAL).
  final String? photo;
  final List<String> sourceIds;
}

enum ShipType { galley, round }

/// One of the Yenikapı wrecks; [type], [date] and size only where a source
/// read here gives them.
class SectionShip {
  SectionShip(JsonReader r)
    : yk = r.integer('yk'),
      type = switch (r.optionalString('type')) {
        null => null,
        final t => ShipType.values.byName(t),
      },
      date = switch (r.optionalObject('date')) {
        null => null,
        final d => Localized.fromJson(d),
      },
      length = r.optionalNumber('length'),
      breadth = r.optionalNumber('breadth'),
      team = r.string('team'),
      cargo = r.optionalBoolean('cargo'),
      x = r.number('x'),
      depth = r.number('depth'),
      glyph = r.number('glyph');
  final int yk;
  final ShipType? type;
  final Localized? date;
  final double? length, breadth;

  /// 'ina' (Institute of Nautical Archaeology) or 'iu' (Istanbul University).
  final String team;
  final bool cargo;

  /// Where the drawing puts it (0..1 across, metres deep): for legibility.
  final double x, depth, glyph;
}

class SectionBeat {
  SectionBeat(JsonReader r)
    : id = r.string('id'),
      depth = r.number('depth'),
      seconds = r.number('seconds'),
      label = Localized.fromJson(r.object('label')),
      caption = Localized.fromJson(r.object('caption')),
      lift = r.strings('lift'),
      sourceIds = r.strings('sources');
  final String id;
  final double depth, seconds;
  final Localized label, caption;

  /// Finds this beat lifts; 'ships' lifts every ship.
  final List<String> lift;
  final List<String> sourceIds;
}

/// A drawn excavation section (`assets/section/<id>/section.json`, P14).
class SectionManifest {
  SectionManifest._(JsonReader r)
    : id = r.string('id'),
      placeId = r.string('placeId'),
      milestoneId = r.string('milestoneId'),
      honesty = Honesty.values.byName(r.string('honesty')),
      top = r.number('top'),
      bottom = r.number('bottom'),
      topEstimated = r.boolean('topEstimated'),
      title = Localized.fromJson(r.object('title')),
      description = Localized.fromJson(r.object('description')),
      talkback = Localized.fromJson(r.object('talkback')),
      sourceIds = r.strings('sources'),
      strata = r.list('strata', (v) => decode(v as Json, SectionStratum.new)),
      finds = r.list('finds', (v) => decode(v as Json, SectionFind.new)),
      ships = r.list('ships', (v) => decode(v as Json, SectionShip.new)),
      shipSourceIds = r.strings('shipSources'),
      shipsPlaced = r.boolean('shipsPlaced'),
      revealSeconds = (r.object('reveal')['seconds'] as num).toDouble(),
      revealFrom = (r.object('reveal')['from'] as num).toDouble(),
      revealTo = (r.object('reveal')['to'] as num).toDouble(),
      revealCaption = Localized.fromJson(r.object('reveal')['caption'] as Json),
      beats = r.list('beats', (v) => decode(v as Json, SectionBeat.new)),
      stills = r.strings('stills') {
    for (final s in stills) {
      beat(s);
    }
  }

  factory SectionManifest.fromJson(Json json) {
    if (json['schemaVersion'] != 1 || json['kind'] != 'section') {
      throw const FormatException('not a section manifest');
    }
    return decode(json, (r) {
      r.integer('schemaVersion');
      r.string('kind');
      return SectionManifest._(r);
    });
  }

  final String id, placeId, milestoneId;
  final Honesty honesty;
  final double top, bottom;
  final bool topEstimated, shipsPlaced;
  final Localized title, description, talkback;
  final List<String> sourceIds, shipSourceIds;
  final List<SectionStratum> strata;
  final List<SectionFind> finds;
  final List<SectionShip> ships;
  final double revealSeconds, revealFrom, revealTo;
  final Localized revealCaption;
  final List<SectionBeat> beats;
  final List<String> stills;

  double get storySeconds => beats.fold(0.0, (t, b) => t + b.seconds);
  SectionBeat beat(String id) => beats.firstWhere(
    (b) => b.id == id,
    orElse: () => throw FormatException('${this.id}: unknown beat $id'),
  );
  SectionStratum stratumAt(double depth) => strata.firstWhere(
    (s) => s.contains(depth),
    orElse: () => depth > top ? strata.first : strata.last,
  );

  Set<String> get allSourceIds => {
    ...sourceIds,
    ...shipSourceIds,
    for (final s in strata) ...s.sourceIds,
    for (final f in finds) ...f.sourceIds,
    for (final b in beats) ...b.sourceIds,
  };
}

/// Sections parsed once at start from `assets/section/index.json`.
class SectionCatalog {
  const SectionCatalog.empty() : _sections = const {}, errors = const [];
  SectionCatalog._(Map<String, SectionManifest> s, this.errors)
    : _sections = Map.unmodifiable(s);
  final Map<String, SectionManifest> _sections;
  final List<String> errors;
  Iterable<SectionManifest> get sections => _sections.values;
  SectionManifest? section(String id) => _sections[id];
  static String manifestPath(String id) => 'assets/section/$id/section.json';
  static const indexPath = 'assets/section/index.json';

  SectionManifest? forMilestone(Milestone m) {
    final path = m.manifestPath;
    if (m.status == MilestoneStatus.planned || path == null) return null;
    for (final s in sections) {
      if (manifestPath(s.id) == path) return s;
    }
    return null;
  }

  static Future<SectionCatalog> load(
    ContentRegistry registry,
    LoadText loadText, {
    bool strict = true,
  }) async {
    final out = <String, SectionManifest>{};
    final errors = <String>[];
    List<String> ids;
    try {
      ids = decode(
        jsonDecode(await loadText(indexPath)) as Map<String, dynamic>,
        (r) {
          if (r.integer('schemaVersion') != 1 ||
              r.string('kind') != 'sections') {
            throw const FormatException('not a section index');
          }
          return r.strings('sections');
        },
      );
    } on Object catch (e) {
      if (strict) rethrow;
      return SectionCatalog._(const {}, ['index: $e']);
    }
    for (final id in ids) {
      try {
        final s = SectionManifest.fromJson(
          jsonDecode(await loadText(manifestPath(id))) as Map<String, dynamic>,
        );
        if (s.id != id) throw FormatException('$id: manifest id mismatch');
        if (registry.place(s.placeId) == null) {
          throw FormatException('$id: unknown place ${s.placeId}');
        }
        if (registry.milestone(s.milestoneId) == null) {
          throw FormatException('$id: unknown milestone ${s.milestoneId}');
        }
        for (final source in s.allSourceIds) {
          if (registry.source(source) == null) {
            throw FormatException('$id: unknown source $source');
          }
        }
        for (final f in s.finds) {
          if (f.photo case final photo?
              when registry.mediaItem(photo) == null) {
            throw FormatException('$id: ${f.id} names unknown media $photo');
          }
        }
        out[id] = s;
      } on Object catch (e) {
        if (strict) rethrow;
        errors.add('$id: $e');
      }
    }
    return SectionCatalog._(out, errors);
  }
}
