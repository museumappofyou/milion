// Manifest technique and honesty codes preserve the PHASES §3 vocabulary.
// ignore_for_file: constant_identifier_names

import 'json_reader.dart';

class Localized {
  const Localized({required this.en, this.tr});
  final String en;
  final String? tr;
  String inLanguage(String language) =>
      language == 'tr' && (tr?.trim().isNotEmpty ?? false) ? tr! : en;
  factory Localized.fromJson(Json j) => decode(j, (r) {
    final en = r.string('en');
    // Missing Turkish is measurable debt, never silently invented.
    final tr = j.containsKey('tr') ? r.value('tr') : null;
    if (tr != null && tr is! String) {
      throw const FormatException('tr must be text');
    }
    return Localized(en: en, tr: tr as String?);
  });
}

enum Category {
  byzantine,
  mosque,
  museum,
  palace,
  fortification,
  cistern,
  tower,
  bazaar,
  bath,
  other,
}

enum PlaceStatus { open, closed, restoration, ruin, unknown }

enum ReviewStatus { draft, reviewed }

enum Wave { byzantine, mosques, museums, city, abroad }

enum Era { ancient, roman, byzantine, medieval, ottoman, modern }

enum ArtworkKind {
  mosaic,
  fresco,
  relief,
  painting,
  object,
  inscription,
  other,
}

enum MilestoneStatus { planned, prototype, approved }

// Codes are the stable manifest vocabulary in PHASES §3.
enum Technique {
  DP,
  GL,
  RL,
  PU,
  WR,
  SB,
  MM,
  SR,
  LU,
  CA,
  CS,
  WK,
  TT,
  TM,
  SK,
  VO,
}

enum Honesty { ORIGINAL, DEPTH, RECONSTRUCTION, IMAGINED }

enum MediaKind { image, video, audio, model }

enum District {
  adalar('Adalar'),
  arnavutkoy('Arnavutköy'),
  atasehir('Ataşehir'),
  avcilar('Avcılar'),
  bagcilar('Bağcılar'),
  bahcelievler('Bahçelievler'),
  bakirkoy('Bakırköy'),
  basaksehir('Başakşehir'),
  bayrampasa('Bayrampaşa'),
  besiktas('Beşiktaş'),
  beykoz('Beykoz'),
  beylikduzu('Beylikdüzü'),
  beyoglu('Beyoğlu'),
  buyukcekmece('Büyükçekmece'),
  catalca('Çatalca'),
  cekmekoy('Çekmeköy'),
  esenler('Esenler'),
  esenyurt('Esenyurt'),
  eyupsultan('Eyüpsultan'),
  fatih('Fatih'),
  gaziosmanpasa('Gaziosmanpaşa'),
  gungoren('Güngören'),
  kadikoy('Kadıköy'),
  kagithane('Kağıthane'),
  kartal('Kartal'),
  kucukcekmece('Küçükçekmece'),
  maltepe('Maltepe'),
  pendik('Pendik'),
  sancaktepe('Sancaktepe'),
  sariyer('Sarıyer'),
  sile('Şile'),
  silivri('Silivri'),
  sisli('Şişli'),
  sultanbeyli('Sultanbeyli'),
  sultangazi('Sultangazi'),
  tuzla('Tuzla'),
  umraniye('Ümraniye'),
  uskudar('Üsküdar'),
  zeytinburnu('Zeytinburnu');

  const District(this.spelling);
  final String spelling;
  Localized get label => Localized(en: spelling, tr: spelling);
}

class Coordinates {
  const Coordinates(this.lat, this.lng);
  final double lat;
  final double lng;
  factory Coordinates.fromJson(Json j) =>
      decode(j, (r) => Coordinates(r.number('lat'), r.number('lng')));
}

class HistoricalName {
  HistoricalName(this.name, this.era, this.greek);
  final Localized name;
  final Era era;

  /// Greek is original-language evidence; explanatory labels remain EN/TR.
  final String? greek;
  factory HistoricalName.fromJson(Json j) => decode(
    j,
    (r) => HistoricalName(
      Localized.fromJson(r.object('name')),
      r.enumeration('era', Era.values),
      r.nullableString('greek'),
    ),
  );
}

class VisitStatus {
  VisitStatus(this.value, this.checkedAt);
  final PlaceStatus value;
  final DateTime? checkedAt;
  factory VisitStatus.fromJson(Json j) => decode(
    j,
    (r) => VisitStatus(
      r.enumeration('value', PlaceStatus.values),
      r.date('checkedAt', nullable: true),
    ),
  );
}

class Source {
  Source(
    this.id,
    this.title,
    this.url,
    this.author,
    this.accessedAt,
    this.licence,
  );
  final String id;
  final Localized title;
  final String url;
  final Localized author;
  final DateTime accessedAt;
  final Localized? licence;
  factory Source.fromJson(Json j) => decode(
    j,
    (r) => Source(
      r.string('id'),
      Localized.fromJson(r.object('title')),
      r.string('url'),
      Localized.fromJson(r.object('author')),
      r.date('accessedAt')!,
      r.value('licence') == null
          ? null
          : Localized.fromJson(r.object('licence')),
    ),
  );
}

class Media {
  Media(
    this.id,
    this.path,
    this.kind,
    this.credit,
    this.sourceId,
    this.era,
    this.historicalPhoto,
  );
  final String id;
  final String path;
  final MediaKind kind;
  final Localized credit;
  final String sourceId;
  final Era era;
  final bool historicalPhoto;
  factory Media.fromJson(Json j) => decode(
    j,
    (r) => Media(
      r.string('id'),
      r.string('path'),
      r.enumeration('kind', MediaKind.values),
      Localized.fromJson(r.object('credit')),
      r.string('source'),
      r.enumeration('era', Era.values),
      r.boolean('historicalPhoto'),
    ),
  );
}

class Stratum {
  Stratum(
    this.id,
    this.fromYear,
    this.toYear,
    this.era,
    this.title,
    this.body,
    this.mediaIds,
    this.artworkIds,
    this.sourceIds, {
    this.anchorYear,
  });
  final String id;
  final int fromYear;
  final int? toYear;
  final Era era;
  final Localized title;

  /// Two to four short paragraphs, separated by a blank line. The validator
  /// and the P05 content tests enforce the range.
  final Localized body;
  final List<String> mediaIds;

  /// Artworks of the owning place shown inside this layer.
  final List<String> artworkIds;
  final List<String> sourceIds;

  /// The gauge's tick year; defaults to [fromYear].
  final int? anchorYear;
  int get gaugeYear => anchorYear ?? fromYear;
  List<String> paragraphs(String language) =>
      body.inLanguage(language).split('\n\n');
  factory Stratum.fromJson(Json j) => decode(
    j,
    (r) => Stratum(
      r.string('id'),
      r.integer('fromYear'),
      r.nullableInteger('toYear'),
      r.enumeration('era', Era.values),
      Localized.fromJson(r.object('title')),
      Localized.fromJson(r.object('body')),
      r.strings('media'),
      r.optionalStrings('artworks'),
      r.strings('sources'),
      anchorYear: r.optionalInteger('anchorYear'),
    ),
  );
}

enum TransitKind { tram, metro, metrobus, ferry, bus }

class TransitStop {
  TransitStop(this.kind, this.stop, this.minutes);
  final TransitKind kind;
  final Localized stop;

  /// Walking minutes from the stop to the entrance, as published.
  final int minutes;
  factory TransitStop.fromJson(Json j) => decode(
    j,
    (r) => TransitStop(
      r.enumeration('kind', TransitKind.values),
      Localized.fromJson(r.object('stop')),
      r.integer('minutes'),
    ),
  );
}

/// The visit card of a reviewed place or a remotely checked draft. Every
/// field is optional; the UI shows an honest empty state for what is missing.
class VisitInfo {
  VisitInfo(
    this.checkedAt,
    this.hours,
    this.hoursCheckedAt,
    this.entry,
    this.etiquette,
    this.accessibility,
    this.transit,
    this.sourceIds,
  );
  final DateTime? checkedAt;
  final Localized? hours;
  final DateTime? hoursCheckedAt;
  final Localized? entry;
  final Localized? etiquette;
  final Localized? accessibility;
  final List<TransitStop> transit;
  final List<String> sourceIds;
  factory VisitInfo.fromJson(Json j) => decode(
    j,
    (r) => VisitInfo(
      r.optionalDate('checkedAt'),
      r.optionalObject('hours') == null
          ? null
          : Localized.fromJson(r.object('hours')),
      r.optionalDate('hoursCheckedAt'),
      r.optionalObject('entry') == null
          ? null
          : Localized.fromJson(r.object('entry')),
      r.optionalObject('etiquette') == null
          ? null
          : Localized.fromJson(r.object('etiquette')),
      r.optionalObject('accessibility') == null
          ? null
          : Localized.fromJson(r.object('accessibility')),
      r.optionalList('transit', (j) => TransitStop.fromJson(j as Json)),
      r.optionalStrings('sources'),
    ),
  );
}

class Place {
  Place(JsonReader r)
    : id = r.string('id'),
      names = Localized.fromJson(r.object('names')),
      historicalNames = r.list(
        'historicalNames',
        (j) => HistoricalName.fromJson(j as Json),
      ),
      categories = Set.unmodifiable(
        r.list('categories', (v) => Category.values.byName(v as String)),
      ),
      eras = Set.unmodifiable(
        r.list('eras', (v) => Era.values.byName(v as String)),
      ),
      district = r.value('district') == null
          ? null
          : r.enumeration('district', District.values),
      coordinates = Coordinates.fromJson(r.object('coordinates')),
      entrance = r.value('entrance') == null
          ? null
          : Coordinates.fromJson(r.object('entrance')),
      currentFunction = Localized.fromJson(r.object('currentFunction')),
      status = VisitStatus.fromJson(r.object('status')),
      qid = r.string('qid'),
      tags = r.strings('tags'),
      hook = Localized.fromJson(r.object('hook')),
      review = r.enumeration('review', ReviewStatus.values),
      wave = r.enumeration('wave', Wave.values),
      reviewPhase = r.string('reviewPhase'),
      outsideProvince = r.boolean('outsideProvince'),
      visit = r.optionalObject('visit') == null
          ? null
          : VisitInfo.fromJson(r.object('visit')),
      strata = r.list('strata', (j) => Stratum.fromJson(j as Json)),
      sourceIds = r.strings('sources');
  factory Place.fromJson(Json j) => decode(j, Place.new);
  final String id;
  final Localized names;
  final List<HistoricalName> historicalNames;
  final Set<Category> categories;
  final Set<Era> eras;
  final District? district;
  final Coordinates coordinates;
  final Coordinates? entrance;
  final Localized currentFunction;
  final VisitStatus status;
  final String qid;
  final List<String> tags;
  final Localized hook;
  final ReviewStatus review;
  final Wave wave;
  final String reviewPhase;
  final bool outsideProvince;
  final VisitInfo? visit;
  final List<Stratum> strata;
  final List<String> sourceIds;
}

class Artwork {
  Artwork(JsonReader r)
    : id = r.string('id'),
      placeId = r.string('place'),
      title = Localized.fromJson(r.object('title')),
      room = Localized.fromJson(r.object('room')),
      position = Localized.fromJson(r.object('position')),
      kind = r.enumeration('kind', ArtworkKind.values),
      surface = Localized.fromJson(r.object('surface')),
      summary = Localized.fromJson(r.object('summary')),
      cues = r.list('cues', (j) => Localized.fromJson(j as Json)),
      folder = r.string('folder'),
      mediaIds = r.strings('media'),
      sourceIds = r.strings('sources');
  factory Artwork.fromJson(Json j) => decode(j, Artwork.new);
  final String id;
  final String placeId;
  final Localized title;
  final Localized room;
  final Localized position;
  final ArtworkKind kind;
  final Localized surface;
  final Localized summary;
  final List<Localized> cues;
  final String folder;
  final List<String> mediaIds;
  final List<String> sourceIds;
}

class Milestone {
  Milestone(JsonReader r)
    : id = r.string('id'),
      numeral = r.string('numeral'),
      title = Localized.fromJson(r.object('title')),
      placeIds = r.strings('places'),
      artworkIds = r.strings('artworks'),
      techniques = Set.unmodifiable(
        r.list('techniques', (v) => Technique.values.byName(v as String)),
      ),
      honesty = Set.unmodifiable(
        r.list('honesty', (v) => Honesty.values.byName(v as String)),
      ),
      status = r.enumeration('status', MilestoneStatus.values),
      manifestPath = r.nullableString('manifestPath'),
      packId = r.string('packId'),
      flagship = r.optionalBoolean('flagship'),
      sourceIds = r.strings('sources');
  factory Milestone.fromJson(Json j) => decode(j, Milestone.new);
  final String id;
  final String numeral;
  final Localized title;
  final List<String> placeIds;
  final List<String> artworkIds;
  final Set<Technique> techniques;
  final Set<Honesty> honesty;
  final MilestoneStatus status;
  final String? manifestPath;
  final String packId;

  /// The ★ pieces in PHASES §3; every one must be approved to ship.
  final bool flagship;
  final List<String> sourceIds;

  /// Integer value of [numeral]; the register is ordered by it.
  int get number => romanValue(numeral);

  /// The furthest honesty state this piece reaches; ORIGINAL is always present.
  Honesty get furthestHonesty =>
      honesty.reduce((a, b) => a.index >= b.index ? a : b);
}

int romanValue(String numeral) {
  const digits = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100};
  var total = 0;
  for (var i = 0; i < numeral.length; i++) {
    final v = digits[numeral[i]] ?? 0;
    final next = i + 1 < numeral.length ? digits[numeral[i + 1]] ?? 0 : 0;
    total += v < next ? -v : v;
  }
  return total;
}

class NormalRect {
  const NormalRect(this.left, this.top, this.right, this.bottom);
  final double left, top, right, bottom;
  double get width => right - left;
  double get height => bottom - top;
  bool contains(double x, double y) =>
      x >= left && x <= right && y >= top && y <= bottom;
  factory NormalRect.fromJson(Json j) => decode(
    j,
    (r) => NormalRect(
      r.number('left'),
      r.number('top'),
      r.number('right'),
      r.number('bottom'),
    ),
  );
}

/// A curated artwork detail: a crop window and anchor in the Milestone's
/// master photograph, one checkable sentence and its sources.
class Detail {
  Detail(JsonReader r)
    : id = r.string('id'),
      milestoneId = r.string('milestone'),
      artworkId = r.string('artwork'),
      title = Localized.fromJson(r.object('title')),
      sentence = Localized.fromJson(r.object('sentence')),
      window = NormalRect.fromJson(r.object('window')),
      anchorX = r.number('anchorX'),
      anchorY = r.number('anchorY'),
      honesty = r.enumeration('honesty', Honesty.values),
      sourceIds = r.strings('sources');
  factory Detail.fromJson(Json j) => decode(j, Detail.new);
  final String id;
  final String milestoneId;
  final String artworkId;
  final Localized title;
  final Localized sentence;
  final NormalRect window;
  final double anchorX, anchorY;
  final Honesty honesty;
  final List<String> sourceIds;
}

class Route {
  Route(this.id, this.title, this.body, this.placeIds, this.sourceIds);
  final String id;
  final Localized title;
  final Localized body;
  final List<String> placeIds;
  final List<String> sourceIds;
  factory Route.fromJson(Json j) => decode(
    j,
    (r) => Route(
      r.string('id'),
      Localized.fromJson(r.object('title')),
      Localized.fromJson(r.object('body')),
      r.strings('places'),
      r.strings('sources'),
    ),
  );
}

class Hunt {
  Hunt(
    this.id,
    this.title,
    this.routeId,
    this.clues,
    this.artworkIds,
    this.sourceIds,
  );
  final String id;
  final Localized title;
  final String routeId;
  final List<Localized> clues;
  final List<String> artworkIds;
  final List<String> sourceIds;
  factory Hunt.fromJson(Json j) => decode(
    j,
    (r) => Hunt(
      r.string('id'),
      Localized.fromJson(r.object('title')),
      r.string('route'),
      r.list('clues', (j) => Localized.fromJson(j as Json)),
      r.strings('artworks'),
      r.strings('sources'),
    ),
  );
}
