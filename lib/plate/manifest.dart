import '../content/json_reader.dart';
import '../content/models.dart';
import '../content/registry.dart' show safeAssetPath;

enum PlateLight { none, gilded, raking, candle }

enum PlateLayerId { original, depth, reconstruction }

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
      gold = r.string('gold'),
      flow = r.nullableString('flow'),
      scroll = r.nullableString('scroll');
  final String surface, gold;
  final String? flow, scroll;
}

class PlateMesh {
  PlateMesh(JsonReader r)
    : geometry = r.string('geometry'),
      figures = r.string('figures'),
      maxVertices = r.integer('maxVertices');
  final String geometry, figures;
  final int maxVertices;
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
      dimensions = r.list('size', (v) {
        if (v is! int || v < 1) {
          throw const FormatException('Invalid plate size');
        }
        return v;
      }),
      manifestPath = r.string('manifestPath'),
      layers = r.list('layers', (j) => decode(j as Json, PlateLayer.new)),
      maps = decode(r.object('maps'), PlateMaps.new),
      mesh = decode(r.object('mesh'), PlateMesh.new),
      details = r.list('details', (j) => Detail.fromJson(j as Json)),
      beats = r.list('beats', (j) => decode(j as Json, PlateBeat.new)),
      reveal = decode(r.object('reveal'), PlateBeat.new),
      revealSeconds = r.number('revealSeconds'),
      storySeconds = r.number('storySeconds'),
      credit = Localized.fromJson(r.object('credit')),
      sourceIds = r.strings('sources'),
      citations = r.list('citations', (j) => Source.fromJson(j as Json)),
      originalSourceUrl = r.nullableString('originalSourceUrl'),
      scrollCenter = r.list('scrollCenter', (v) {
        if (v is! num || !v.isFinite || v < 0 || v > 1) {
          throw const FormatException('Invalid scroll center');
        }
        return v.toDouble();
      });

  factory PlateManifest.fromJson(Json j) {
    final manifest = decode(j, PlateManifest._);
    manifest._validate();
    return manifest;
  }
  final int schemaVersion;
  final String kind, id, milestoneId, artworkId, manifestPath;
  final Localized title, credit;
  final List<int> dimensions;
  int get width => dimensions[0];
  int get height => dimensions[1];
  final List<PlateLayer> layers;
  final PlateMaps maps;
  final PlateMesh mesh;
  final List<Detail> details;
  final List<PlateBeat> beats;
  final PlateBeat reveal;
  final double revealSeconds, storySeconds;
  final List<String> sourceIds;
  final List<Source> citations;
  final String? originalSourceUrl;
  final List<double> scrollCenter;
  PlateLayer layer(PlateLayerId id) => layers.singleWhere((l) => l.id == id);
  String get original => layer(PlateLayerId.original).asset;
  Iterable<String> get imagePaths => {
    ...layers.map((l) => l.asset),
    ...layers.map((l) => l.mask).whereType<String>(),
    maps.surface,
    maps.gold,
    if (maps.flow != null) maps.flow!,
    if (maps.scroll != null) maps.scroll!,
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
      schemaVersion == 1 && kind == 'plate',
      'unsupported plate schema/kind',
    );
    require(
      dimensions.length == 2 && scrollCenter.length == 2,
      'invalid dimensions',
    );
    require(
      mesh.maxVertices > 3 && mesh.maxVertices <= 60000,
      'vertex budget exceeds 60k',
    );
    require(
      storySeconds >= 20 && storySeconds <= 40 && revealSeconds == 10,
      'story/reveal duration',
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
      layers.length == 3 && layers.map((l) => l.id).toSet().length == 3,
      'three unique layers required',
    );
    for (final l in layers) {
      require(
        l.honesty == Honesty.values[l.id.index],
        'incorrect layer honesty',
      );
      require(
        l.id != PlateLayerId.reconstruction || l.mask != null,
        'reconstruction requires a damage mask',
      );
    }
    for (final p in [
      ...imagePaths,
      mesh.geometry,
      mesh.figures,
      manifestPath,
    ]) {
      require(safeAssetPath(p), 'unsafe asset path: $p');
    }
    bilingual(title);
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
    require(!reveal.flow || maps.flow != null, 'reveal flow map required');
    require(
      !reveal.spiral || maps.scroll != null,
      'reveal scroll map required',
    );
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
      require(!b.flow || maps.flow != null, 'flow map required');
      require(!b.spiral || maps.scroll != null, 'scroll map required');
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
