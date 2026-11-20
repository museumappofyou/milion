import 'dart:convert';

import '../atlas/certainty.dart';
import '../content/json_reader.dart';
import '../content/models.dart';
import '../content/registry.dart';
import '../content/repository.dart';

/// Who tells it: the side an account came from (P15, XIX: every claim is
/// attributed, none is the app's own voice).
enum AccountSide {
  byzantine,
  venetian,
  genoese,
  ottoman,
  ottomanGreek,
  slavonic,
  modern,
}

/// One account of an event: who, from which side, saying what.
class SiegeAccount {
  SiegeAccount(JsonReader r)
    : who = Localized.fromJson(r.object('who')),
      side = AccountSide.values.byName(r.string('side')),
      says = Localized.fromJson(r.object('says')),
      sourceIds = r.strings('sources');
  final Localized who;
  final AccountSide side;
  final Localized says;
  final List<String> sourceIds;
}

/// A point or line of the siege map in latitude and longitude.
class SiegeShape {
  SiegeShape(this.points);
  final List<Coordinates> points;
  bool get isPoint => points.length == 1;
}

/// Something that happened or stood on the map from [day] (1 = 6 April
/// 1453) to [until] (inclusive; null: to the end).
class SiegeEvent {
  SiegeEvent(JsonReader r)
    : id = r.string('id'),
      kind = r.string('kind'),
      day = r.integer('day'),
      until = r.optionalInteger('until'),
      shape = SiegeShape(
        r.list('shape', (v) {
          final p = (v as List).cast<num>();
          return Coordinates(p[0].toDouble(), p[1].toDouble());
        }),
      ),
      certainty = Certainty.values.byName(r.string('certainty')),
      label = Localized.fromJson(r.object('label')),
      note = Localized.fromJson(r.object('note')),
      accounts = r.list('accounts', (v) => decode(v as Json, SiegeAccount.new)),
      photo = r.optionalString('photo'),
      sourceIds = r.strings('sources');
  final String id;

  /// camp, gun, chain, fleet, overland, bridge, mine, tower, assault,
  /// breach, fort, legend.
  final String kind;
  final int day;
  final int? until;
  final SiegeShape shape;
  final Certainty certainty;
  final Localized label, note;
  final List<SiegeAccount> accounts;

  /// A media id: the ORIGINAL this event can open (P15: the 1455
  /// miniature of the ships hauled overland).
  final String? photo;
  final List<String> sourceIds;
  bool shownOn(int d) => d >= day && (until == null || d <= until!);
}

/// Where the camera looks: a centre and the width of the view in metres.
class SiegeView {
  SiegeView(JsonReader r)
    : lat = r.number('lat'),
      lng = r.number('lng'),
      width = r.number('width');
  SiegeView.of(this.lat, this.lng, this.width);
  final double lat, lng, width;
}

class SiegeBeat {
  SiegeBeat(JsonReader r)
    : id = r.string('id'),
      day = r.integer('day'),
      seconds = r.number('seconds'),
      view = decode(r.object('view'), SiegeView.new),
      focus = r.strings('focus'),
      label = Localized.fromJson(r.object('label')),
      caption = Localized.fromJson(r.object('caption')),
      sourceIds = r.strings('sources');
  final String id;
  final int day;
  final double seconds;
  final SiegeView view;

  /// Events this beat names: drawn strong, their accounts listed.
  final List<String> focus;
  final Localized label, caption;
  final List<String> sourceIds;
}

/// A name written on the map (a water, a town, a hill), so the base reads
/// without the Atlas's own labels.
class SiegeMapLabel {
  SiegeMapLabel(JsonReader r)
    : lat = r.number('lat'),
      lng = r.number('lng'),
      water = r.boolean('water'),
      text = Localized.fromJson(r.object('text'));
  final double lat, lng;

  /// Waters are set in italic; land names in small capitals.
  final bool water;
  final Localized text;
}

/// A map sequence over the 53 days (`assets/siege/<id>/siege.json`, P15).
class SiegeManifest {
  SiegeManifest._(JsonReader r)
    : id = r.string('id'),
      placeId = r.string('placeId'),
      milestoneId = r.string('milestoneId'),
      honesty = Honesty.values.byName(r.string('honesty')),
      title = Localized.fromJson(r.object('title')),
      description = Localized.fromJson(r.object('description')),
      talkback = Localized.fromJson(r.object('talkback')),
      sourceIds = r.strings('sources'),
      firstDay = DateTime.parse(r.string('firstDay')),
      days = r.integer('days'),
      frame = (
        south: (r.object('frame')['south'] as num).toDouble(),
        west: (r.object('frame')['west'] as num).toDouble(),
        north: (r.object('frame')['north'] as num).toDouble(),
        east: (r.object('frame')['east'] as num).toDouble(),
      ),
      home = decode(r.object('home'), SiegeView.new),
      labels = r.list('labels', (v) => decode(v as Json, SiegeMapLabel.new)),
      events = r.list('events', (v) => decode(v as Json, SiegeEvent.new)),
      revealSeconds = (r.object('reveal')['seconds'] as num).toDouble(),
      revealCaption = Localized.fromJson(r.object('reveal')['caption'] as Json),
      revealEvent = r.object('reveal')['event'] as String,
      revealView = decode(r.object('reveal')['view'] as Json, SiegeView.new),
      beats = r.list('beats', (v) => decode(v as Json, SiegeBeat.new)),
      stills = r.strings('stills') {
    for (final s in stills) {
      beat(s);
    }
    event(revealEvent);
    for (final b in beats) {
      for (final f in b.focus) {
        event(f);
      }
    }
  }

  factory SiegeManifest.fromJson(Json json) {
    if (json['schemaVersion'] != 1 || json['kind'] != 'siege') {
      throw const FormatException('not a siege manifest');
    }
    return decode(json, (r) {
      r.integer('schemaVersion');
      r.string('kind');
      return SiegeManifest._(r);
    });
  }

  final String id, placeId, milestoneId;
  final Honesty honesty;
  final Localized title, description, talkback;
  final List<String> sourceIds;
  final DateTime firstDay;
  final int days;
  final ({double south, double west, double north, double east}) frame;
  final SiegeView home;
  final List<SiegeMapLabel> labels;
  final List<SiegeEvent> events;
  final double revealSeconds;
  final Localized revealCaption;
  final String revealEvent;
  final SiegeView revealView;
  final List<SiegeBeat> beats;
  final List<String> stills;

  double get storySeconds => beats.fold(0.0, (t, b) => t + b.seconds);
  DateTime dateOf(int day) => firstDay.add(Duration(days: day - 1));
  SiegeBeat beat(String id) => beats.firstWhere(
    (b) => b.id == id,
    orElse: () => throw FormatException('${this.id}: unknown beat $id'),
  );
  SiegeEvent event(String id) => events.firstWhere(
    (e) => e.id == id,
    orElse: () => throw FormatException('${this.id}: unknown event $id'),
  );

  Set<String> get allSourceIds => {
    ...sourceIds,
    for (final e in events) ...e.sourceIds,
    for (final e in events)
      for (final a in e.accounts) ...a.sourceIds,
    for (final b in beats) ...b.sourceIds,
  };
}

/// Map sequences parsed once at start from `assets/siege/index.json`.
class SiegeCatalog {
  const SiegeCatalog.empty() : _maps = const {}, errors = const [];
  SiegeCatalog._(Map<String, SiegeManifest> s, this.errors)
    : _maps = Map.unmodifiable(s);
  final Map<String, SiegeManifest> _maps;
  final List<String> errors;
  Iterable<SiegeManifest> get maps => _maps.values;
  SiegeManifest? map(String id) => _maps[id];
  static String manifestPath(String id) => 'assets/siege/$id/siege.json';
  static const indexPath = 'assets/siege/index.json';

  SiegeManifest? forMilestone(Milestone m) {
    final path = m.manifestPath;
    if (m.status == MilestoneStatus.planned || path == null) return null;
    for (final s in maps) {
      if (manifestPath(s.id) == path) return s;
    }
    return null;
  }

  static Future<SiegeCatalog> load(
    ContentRegistry registry,
    LoadText loadText, {
    bool strict = true,
  }) async {
    final out = <String, SiegeManifest>{};
    final errors = <String>[];
    List<String> ids;
    try {
      ids = decode(
        jsonDecode(await loadText(indexPath)) as Map<String, dynamic>,
        (r) {
          if (r.integer('schemaVersion') != 1 || r.string('kind') != 'sieges') {
            throw const FormatException('not a siege index');
          }
          return r.strings('maps');
        },
      );
    } on Object catch (e) {
      if (strict) rethrow;
      return SiegeCatalog._(const {}, ['index: $e']);
    }
    for (final id in ids) {
      try {
        final s = SiegeManifest.fromJson(
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
        for (final e in s.events) {
          if (e.photo case final m? when registry.mediaItem(m) == null) {
            throw FormatException('$id: ${e.id} names unknown media $m');
          }
        }
        out[id] = s;
      } on Object catch (e) {
        if (strict) rethrow;
        errors.add('$id: $e');
      }
    }
    return SiegeCatalog._(out, errors);
  }
}
