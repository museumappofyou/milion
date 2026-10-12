import 'dart:math' as math;

import '../content/json_reader.dart';
import '../content/models.dart';
import '../content/registry.dart' show safeAssetPath;

enum PlateLight { none, gilded, raking, candle }

enum PlateLayerId { original, depth, reconstruction }

/// Honesty a layer must carry; also fixed by the §3 doctrine.
const plateLayerHonesty = {
  PlateLayerId.original: Honesty.ORIGINAL,
  PlateLayerId.depth: Honesty.DEPTH,
  PlateLayerId.reconstruction: Honesty.RECONSTRUCTION,
};

class PlateLayer {
  PlateLayer(JsonReader r)
    : id = r.enumeration('id', PlateLayerId.values),
      asset = r.string('asset'),
      honesty = r.enumeration('honesty', Honesty.values),
      mask = r.nullableString('mask');
  final PlateLayerId id;
  final String asset;
  final Honesty honesty;
  final String? mask;
}

class PlateMaps {
  PlateMaps(JsonReader r)
    : surface = r.string('surface'),
      gold = r.string('gold');

  /// RGB = normal (0..1), A = height (0..1).
  final String surface;

  /// R = gilded coverage.
  final String gold;
}

List<double> _point(JsonReader r, String key) => r.list(key, (v) {
  if (v is! num || !v.isFinite || v < 0 || v > 1) {
    throw FormatException('Invalid $key');
  }
  return v.toDouble();
});

/// MM: flow-map UV scrolling inside a mask (R coverage, GB direction).
class PlateFlow {
  PlateFlow(JsonReader r)
    : mask = r.string('mask'),
      period = r.number('period'),
      distance = r.number('distance');
  final String mask;
  final double period, distance;
}

/// A UV twist inside a mask, pivoting on [center] (normalised plate space).
class PlateSpiral {
  PlateSpiral(JsonReader r)
    : mask = r.string('mask'),
      center = _point(r, 'center');
  final String mask;
  final List<double> center;
}

/// The single-beat figure rig; absent on plates without a gesture.
class PlateRig {
  PlateRig(JsonReader r)
    : path = r.string('path'),
      maxVertices = r.integer('maxVertices');
  final String path;
  final int maxVertices;
}

/// LU: a photograph taken straight up into a dome, mapped back onto it.
/// [center] is where the zenith (the crown) appears. The dome's rim, seen at
/// [rimElevation] degrees, is the ellipse [rimCenter] / [rimRadii] (radii as
/// fractions of the image width): a photographer a little off the axis sees
/// the crown displaced from the rim's centre. Between them the image is read
/// as an ordinary lens: distance grows with tan(zenith angle).
class PlateLookUp {
  PlateLookUp(JsonReader r)
    : center = _point(r, 'center'),
      rimCenter = _point(r, 'rimCenter'),
      rimRadii = r.list('rimRadii', (v) {
        if (v is! num || !v.isFinite || v <= 0 || v > 1) {
          throw const FormatException('Invalid rim radius');
        }
        return v.toDouble();
      }),
      rimElevation = r.number('rimElevation');
  final List<double> center, rimCenter, rimRadii;
  final double rimElevation;
}

class PlateGesture {
  PlateGesture(JsonReader r)
    : start = r.number('start'),
      duration = r.number('duration'),
      strength = r.number('strength'),
      windows = r.list('windows', (j) => NormalRect.fromJson(j as Json));
  final double start, duration, strength;
  final List<NormalRect> windows;
}

class PlateBeat {
  PlateBeat(JsonReader r)
    : id = r.string('id'),
      start = r.number('start'),
      duration = r.number('duration'),
      detailId = r.string('detail'),
      window = NormalRect.fromJson(r.object('window')),
      caption = Localized.fromJson(r.object('caption')),
      sourceIds = r.strings('sources'),
      light = r.enumeration('light', PlateLight.values),
      flow = r.boolean('flow'),
      spiral = r.boolean('spiral'),
      gesture = r.optionalObject('gesture') == null
          ? null
          : decode(r.object('gesture'), PlateGesture.new);
  final String id, detailId;
  final double start, duration;
  double get end => start + duration;
  final NormalRect window;
  final Localized caption;
  final List<String> sourceIds;
  final PlateLight light;
  final bool flow, spiral;
  final PlateGesture? gesture;
}

/// Pure Dart: strict, versioned input usable by both the app and validator CLI.
class PlateManifest {
  PlateManifest._(JsonReader r)
    : schemaVersion = r.integer('schemaVersion'),
      kind = r.string('kind'),
      id = r.string('id'),
      milestoneId = r.string('milestone'),
      artworkId = r.string('artwork'),
      title = Localized.fromJson(r.object('title')),
      description = Localized.fromJson(r.object('description')),
      dimensions = r.list('size', (v) {
        if (v is! int || v < 1 || v > 4096) {
          throw const FormatException('Invalid plate size');
        }
        return v;
      }),
      manifestPath = r.string('manifestPath'),
      layers = r.list('layers', (j) => decode(j as Json, PlateLayer.new)),
      maps = decode(r.object('maps'), PlateMaps.new),
      flowEffect = _optional(r, 'flow', PlateFlow.new),
      spiralEffect = _optional(r, 'spiral', PlateSpiral.new),
      rig = _optional(r, 'rig', PlateRig.new),
      lookUp = _optional(r, 'lookUp', PlateLookUp.new),
      details = r.list('details', (j) => Detail.fromJson(j as Json)),
      beats = r.list('beats', (j) => decode(j as Json, PlateBeat.new)),
      reveal = decode(r.object('reveal'), PlateBeat.new),
      revealSeconds = r.number('revealSeconds'),
      revealMoment = r.number('revealMoment'),
      storySeconds = r.number('storySeconds'),
      credit = Localized.fromJson(r.object('credit')),
      sourceIds = r.strings('sources'),
      citations = r.list('citations', (j) => Source.fromJson(j as Json)),
      originalSourceUrl = r.nullableString('originalSourceUrl');

  static T? _optional<T>(JsonReader r, String key, T Function(JsonReader) f) {
    final j = r.optionalObject(key);
    return j == null ? null : decode(j, f);
  }

  factory PlateManifest.fromJson(Json j) {
    final manifest = decode(j, PlateManifest._);
    manifest._validate();
    return manifest;
  }
  static const version = 2;
  final int schemaVersion;
  final String kind, id, milestoneId, artworkId, manifestPath;
  final Localized title, description, credit;
  final List<int> dimensions;
  int get width => dimensions[0];
  int get height => dimensions[1];
  final List<PlateLayer> layers;
  final PlateMaps maps;
  final PlateFlow? flowEffect;
  final PlateSpiral? spiralEffect;
  final PlateRig? rig;
  final PlateLookUp? lookUp;
  final List<Detail> details;
  final List<PlateBeat> beats;
  final PlateBeat reveal;
  final double revealSeconds, revealMoment, storySeconds;
  final List<String> sourceIds;
  final List<Source> citations;
  final String? originalSourceUrl;
  PlateLayer? layer(PlateLayerId id) =>
      layers.where((l) => l.id == id).firstOrNull;
  bool has(PlateLayerId id) => layer(id) != null;
  String get original => layer(PlateLayerId.original)!.asset;

  /// The DEPTH state shows the same pixels; a baked relief may replace them.
  String get depthAsset => layer(PlateLayerId.depth)?.asset ?? original;
  bool get hasGesture => beats.any((b) => b.gesture != null);
  Iterable<String> get imagePaths => {
    ...layers.map((l) => l.asset),
    ...layers.map((l) => l.mask).whereType<String>(),
    maps.surface,
    maps.gold,
    ?flowEffect?.mask,
    ?spiralEffect?.mask,
  };

  void _validate() {
    void require(bool valid, String reason) {
      if (!valid) throw FormatException('$id: $reason');
    }

    void bilingual(Localized text) =>
        require(text.tr?.trim().isNotEmpty ?? false, 'TR required');
    void window(NormalRect w) => require(
      w.left >= 0 &&
          w.top >= 0 &&
          w.right <= 1 &&
          w.bottom <= 1 &&
          w.width > 0 &&
          w.height > 0,
      'invalid normalized window',
    );
    require(
      schemaVersion == version && kind == 'plate',
      'unsupported plate schema/kind',
    );
    require(dimensions.length == 2, 'invalid dimensions');
    final r = rig;
    require(
      r == null || (r.maxVertices > 3 && r.maxVertices <= 60000),
      'vertex budget exceeds 60k',
    );
    require(hasGesture == (r != null), 'a rig exists only for a gesture beat');
    final f = flowEffect;
    require(
      f == null || (f.period > 0 && f.distance > 0 && f.distance <= .1),
      'flow period/distance',
    );
    require(
      spiralEffect == null || spiralEffect!.center.length == 2,
      'invalid spiral center',
    );
    final l = lookUp;
    require(
      l == null ||
          (l.center.length == 2 &&
              l.rimCenter.length == 2 &&
              l.rimRadii.length == 2 &&
              l.rimElevation >= 0 &&
              l.rimElevation < 85 &&
              // The crown must lie inside the rim.
              math.pow((l.center[0] - l.rimCenter[0]) / l.rimRadii[0], 2) +
                      math.pow(
                        (l.center[1] - l.rimCenter[1]) *
                            height /
                            width /
                            l.rimRadii[1],
                        2,
                      ) <
                  1),
      'invalid look-up projection',
    );
    require(
      storySeconds >= 20 && storySeconds <= 40 && revealSeconds == 10,
      'story/reveal duration',
    );
    require(
      revealMoment >= 0 && revealMoment <= revealSeconds,
      'reveal moment outside the reveal',
    );
    require(
      reveal.start == 0 &&
          reveal.duration == revealSeconds &&
          reveal.gesture == null,
      'reveal must be ten seconds without a figure gesture',
    );
    window(reveal.window);
    bilingual(reveal.caption);
    require(
      layers.map((l) => l.id).toSet().length == layers.length &&
          has(PlateLayerId.original),
      'unique layers including the original required',
    );
    for (final l in layers) {
      require(l.honesty == plateLayerHonesty[l.id], 'incorrect layer honesty');
      require(
        (l.id == PlateLayerId.reconstruction) == (l.mask != null),
        'only reconstruction carries a damage mask, and it must',
      );
    }
    for (final p in [...imagePaths, ?r?.path, manifestPath]) {
      require(safeAssetPath(p), 'unsafe asset path: $p');
    }
    bilingual(title);
    bilingual(description);
    bilingual(credit);
    require(
      sourceIds.isNotEmpty && details.isNotEmpty && beats.isNotEmpty,
      'sources/details/beats required',
    );
    final refs = {
      ...sourceIds,
      ...details.expand((d) => d.sourceIds),
      ...beats.expand((b) => b.sourceIds),
      ...reveal.sourceIds,
    };
    require(
      citations.map((s) => s.id).toSet().containsAll(refs),
      'citations required for every claim',
    );
    require(
      citations.map((s) => s.id).toSet().length == citations.length,
      'duplicate citation',
    );
    require(
      details.any((d) => d.id == reveal.detailId) &&
          reveal.sourceIds.isNotEmpty,
      'reveal detail/sources required',
    );
    for (final b in [reveal, ...beats]) {
      require(!b.flow || flowEffect != null, 'flow effect required');
      require(!b.spiral || spiralEffect != null, 'spiral effect required');
    }
    require(
      details.map((d) => d.id).toSet().length == details.length,
      'duplicate detail',
    );
    for (final d in details) {
      window(d.window);
      bilingual(d.title);
      bilingual(d.sentence);
      require(
        d.milestoneId == milestoneId && d.artworkId == artworkId,
        'foreign detail',
      );
      require(
        d.anchorX >= d.window.left &&
            d.anchorX <= d.window.right &&
            d.anchorY >= d.window.top &&
            d.anchorY <= d.window.bottom,
        'anchor outside detail',
      );
      require(
        d.honesty == Honesty.ORIGINAL && d.sourceIds.isNotEmpty,
        'detail honesty/sources',
      );
    }
    var end = 0.0, gestures = 0;
    final ids = <String>{};
    for (final b in beats) {
      require(
        ids.add(b.id) && (b.start - end).abs() < .0001 && b.duration > 0,
        'non-contiguous/duplicate beat',
      );
      require(details.any((d) => d.id == b.detailId), 'unknown beat detail');
      window(b.window);
      bilingual(b.caption);
      require(b.sourceIds.isNotEmpty, 'beat sources required');
      final g = b.gesture;
      if (g != null) {
        gestures++;
        require(
          g.duration > 0 &&
              g.duration <= 1.2 &&
              g.strength > 0 &&
              g.strength <= .35 &&
              g.start >= b.start &&
              g.start + g.duration <= b.end &&
              g.windows.isNotEmpty,
          'gesture must be a single gentle beat',
        );
        for (final w in g.windows) {
          window(w);
        }
      }
      end = b.end;
    }
    require(
      gestures <= 1 && (end - storySeconds).abs() < .0001,
      'story endpoint/gesture count',
    );
    final url = originalSourceUrl == null
        ? null
        : Uri.tryParse(originalSourceUrl!);
    require(
      originalSourceUrl == null ||
          (url != null &&
              ['https', 'http'].contains(url.scheme) &&
              url.host.isNotEmpty),
      'invalid image source URL',
    );
  }
}
