import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

typedef GyroStream = Stream<GyroscopeEvent> Function();

/// Angular-velocity integration with a low-pass output and a ±6° hard bound.
/// The stream is opened only after an explicit opt-in.
class PlateTilt extends ChangeNotifier {
  PlateTilt({GyroStream? events})
    : _events =
          events ??
          (() => gyroscopeEventStream(
            samplingPeriod: SensorInterval.gameInterval,
          ));
  final GyroStream _events;
  StreamSubscription<GyroscopeEvent>? _subscription;
  static const maxRadians = math.pi / 30;
  bool enabled = false, unavailable = false, _active = true, _disposed = false;
  Offset _angle = Offset.zero, _filtered = Offset.zero;
  DateTime? _last;
  Offset get normalized => _filtered / maxRadians;
  bool get subscribed => _subscription != null;
  void setEnabled(bool value) {
    enabled = value;
    unavailable = false;
    recenter();
    if (enabled && _active) {
      _start();
    } else {
      _stop();
    }
    notifyListeners();
  }

  void _start() {
    if (_disposed || _subscription != null) return;
    try {
      _subscription = _events().listen(
        accept,
        onError: (Object _) {
          if (_disposed) return;
          unavailable = true;
          enabled = false;
          _stop();
          recenter();
          notifyListeners();
        },
      );
    } catch (_) {
      unavailable = true;
      enabled = false;
      notifyListeners();
    }
  }

  void _stop() {
    _subscription?.cancel();
    _subscription = null;
    _last = null;
  }

  void accept(GyroscopeEvent event) {
    if (_disposed ||
        !enabled ||
        !_active ||
        !event.x.isFinite ||
        !event.y.isFinite) {
      return;
    }
    final last = _last;
    _last = event.timestamp;
    if (last == null) return;
    final dt = event.timestamp.difference(last).inMicroseconds / 1000000;
    if (dt <= 0 || dt > .2) return;
    _angle = Offset(
      (_angle.dx + event.y * dt).clamp(-maxRadians, maxRadians),
      (_angle.dy + event.x * dt).clamp(-maxRadians, maxRadians),
    );
    _filtered += (_angle - _filtered) * .18;
    notifyListeners();
  }

  void drag(Offset normalized) {
    if (_disposed) return;
    _angle = _filtered =
        Offset(normalized.dx.clamp(-1, 1), normalized.dy.clamp(-1, 1)) *
        maxRadians;
    notifyListeners();
  }

  void recenter() {
    _angle = _filtered = Offset.zero;
    _last = null;
    if (!_disposed) notifyListeners();
  }

  void suspend() {
    _active = false;
    _stop();
    recenter();
  }

  void resume() {
    _active = true;
    if (enabled) _start();
  }

  @override
  void dispose() {
    _disposed = true;
    _stop();
    super.dispose();
  }
}
