import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../content/models.dart';
import 'atlas_view.dart';
import 'historic.dart';

/// The Atlas's state. Following P09, continuous changes (the camera moving,
/// the year animating) tick [motion] so only the painters repaint; discrete
/// changes (toggles, a gesture settling) notify listeners, which may rebuild
/// widgets and semantics.
class AtlasController extends ChangeNotifier {
  AtlasController({this._view = AtlasView.peninsula, this._year = 2026});

  final motion = ValueNotifier<int>(0);

  AtlasView _view;
  AtlasView get view => _view;

  /// Moves the camera; listeners hear of it when it settles ([settle]).
  set view(AtlasView v) {
    if (v == _view) return;
    _view = v;
    motion.value++;
  }

  /// Bumped when the camera comes to rest, for marker semantics.
  int get settled => _settled;
  int _settled = 0;
  void settle() {
    _settled++;
    notifyListeners();
  }

  double _year;
  double get year => _year;

  /// The slider's continuous year while it animates between stops.
  set year(double y) {
    if (y == _year) return;
    _year = y;
    motion.value++;
  }

  /// The stop the slider points at.
  int get stop => _stop;
  int _stop = atlasYears.length - 1;
  set stop(int i) {
    if (i == _stop) return;
    _stop = i;
    notifyListeners();
  }

  bool _below = false;
  bool get below => _below;
  set below(bool v) {
    if (v == _below) return;
    _below = v;
    notifyListeners();
  }

  bool _rings = true;
  bool get rings => _rings;
  set rings(bool v) {
    if (v == _rings) return;
    _rings = v;
    notifyListeners();
  }

  /// The user's position (metres), only after they tapped "From me" and
  /// granted location; rings then centre on it.
  Offset? _me;
  Offset? get me => _me;
  Coordinates? _meCoordinates;
  Coordinates? get meCoordinates => _meCoordinates;
  void locate(Coordinates? c) {
    _meCoordinates = c;
    _me = c == null ? null : projectMetres(c.lat, c.lng);
    notifyListeners();
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }
}
