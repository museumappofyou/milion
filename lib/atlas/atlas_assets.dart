import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'atlas_data.dart';
import 'atlas_filter.dart';
import 'atlas_tiles.dart';
import 'historic.dart';

/// Everything the Atlas draws, bundled with the app: it never touches the
/// network (P10 acceptance: works in airplane mode).
class AtlasAssets {
  AtlasAssets(this.data, this.index, this.historic, this.years);
  final AtlasData data;
  final AtlasIndex index;
  final HistoricAtlas historic;
  final PlaceYears years;

  static Future<AtlasAssets>? _loading;
  static AtlasAssets? _loaded;

  /// Loads once per process. Once loaded the result comes back as a
  /// synchronous future, so the map appears in the first frame of a revisit
  /// (and a future from another zone is never awaited).
  static Future<AtlasAssets> load([AssetBundle? bundle]) {
    final loaded = _loaded;
    if (loaded != null) return SynchronousFuture(loaded);
    return _loading ??= _load(bundle ?? rootBundle).then(
      (a) => _loaded = a,
      onError: (Object e) {
        _loading = null;
        throw e;
      },
    );
  }

  /// Forgets an unfinished load. Widget tests run each test in its own
  /// fake-async zone, where a load started by an earlier test never ends.
  @visibleForTesting
  static void debugForgetPendingLoad() {
    if (_loaded == null) _loading = null;
  }

  static Future<AtlasAssets> _load(AssetBundle bundle) async {
    final bytes = await bundle.load(AtlasData.assetPath);
    // Read once per process, so not cached by the bundle (whose cached
    // futures would also outlive a widget test's zone).
    final historicText = await bundle.loadString(
      HistoricAtlas.assetPath,
      cache: false,
    );
    final yearsText = await bundle.loadString(
      PlaceYears.assetPath,
      cache: false,
    );
    // Decoding and indexing take a few hundred ms; keep them off the UI.
    final list = bytes.buffer.asUint8List(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    final transfer = TransferableTypedData.fromList([list]);
    final (data, index) = await Isolate.run(() {
      final b = transfer.materialize().asByteData();
      final data = AtlasData.decode(b);
      return (data, AtlasIndex(data));
    });
    return AtlasAssets(
      data,
      index,
      HistoricAtlas.fromJsonText(historicText),
      PlaceYears.fromJsonText(yearsText),
    );
  }

  /// Synchronous decoding for tests.
  static AtlasAssets decodeSync(
    ByteData bytes,
    String historicText,
    String yearsText,
  ) {
    final data = AtlasData.decode(bytes);
    return AtlasAssets(
      data,
      AtlasIndex(data),
      HistoricAtlas.fromJsonText(historicText),
      PlaceYears.fromJsonText(yearsText),
    );
  }
}
