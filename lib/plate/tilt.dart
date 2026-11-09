import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

typedef GyroStream = Stream<GyroscopeEvent> Function();

/// Angular-velocity integration with a low-pass output and a ±6° hard bound.
/// The integrated angle relaxes back to centre (time constant [settle]), so
/// gyro drift cannot pin the plate at the bound; smoothing is time-based, not
/// per sample. The stream is opened only after an explicit opt-in.
///
/// Listeners hear only what a control shows (on, off, unavailable); every
/// reading or drag that moves the picture ticks [motion] instead. Rebuilding
/// the plate's Semantics per reading sent TalkBack an update every frame on
/// the A52s (2026-11-09), so only the painter follows [motion].
class PlateTilt extends ChangeNotifier {
  PlateTilt({GyroStream? events})
    : _events =
          events ??
          (() => gyroscopeEventStream(samplingPeriod: samplingPeriod));
  final GyroStream _events;
  StreamSubscription<GyroscopeEvent>? _subscription;

  /// Readings must come faster than the display, since each one repaints:
  /// the 20 ms game interval left ~10 dropped frames a second at 60 Hz on
  /// the A52s (2026-11-09). Matches the look-up's native rate.
  static const samplingPeriod = Duration(milliseconds: 10);
  static const maxRadians = math.pi / 30;
  static const settle = 2.5, smoothing = .08;
  bool enabled = false, unavailable = false, _active = true, _disposed = false;
  Offset _angle = Offset.zero, _filtered = Offset.zero;
  DateTime? _last;
  Offset get normalized => _filtered / maxRadians;
  bool get subscribed => _subscription != null;

  /// Ticks whenever [normalized] may have changed.
  final ValueNotifier<int> motion = ValueNotifier(0);
  void _moved() {
    if (!_disposed) motion.value++;
  }

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
    final decay = math.exp(-dt / settle);
    _angle = Offset(
      (_angle.dx * decay + event.y * dt).clamp(-maxRadians, maxRadians),
      (_angle.dy * decay + event.x * dt).clamp(-maxRadians, maxRadians),
    );
    _filtered += (_angle - _filtered) * (1 - math.exp(-dt / smoothing));
    _moved();
  }

  void drag(Offset normalized) {
    if (_disposed) return;
    _angle = _filtered =
        Offset(normalized.dx.clamp(-1, 1), normalized.dy.clamp(-1, 1)) *
        maxRadians;
    _moved();
  }

  void recenter() {
    _angle = _filtered = Offset.zero;
    _last = null;
    _moved();
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
    motion.dispose();
    super.dispose();
  }
}
