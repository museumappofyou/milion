import '../content/models.dart';
import 'manifest.dart';

class PlateSample {
  const PlateSample(this.index, this.beat, this.window, this.gesturePhase);
  final int index;
  final PlateBeat beat;
  final NormalRect window;
  final double gesturePhase;
}

/// Seekable, deterministic camera/beat sampling, independent of frame rate.
class PlateTimeline {
  const PlateTimeline(this.manifest);
  final PlateManifest manifest;
  PlateSample at(double seconds, {bool reduced = false, bool reveal = false}) {
    if (!seconds.isFinite) throw const FormatException('Non-finite story time');
    final beats = reveal ? [manifest.reveal] : manifest.beats;
    final t = seconds.clamp(
      0.0,
      reveal ? manifest.revealSeconds : manifest.storySeconds,
    );
    final index = beats.indexWhere((b) => t < b.end);
    final i = index < 0 ? beats.length - 1 : index;
    final beat = beats[i];
    final from = i == 0 ? const NormalRect(0, 0, 1, 1) : beats[i - 1].window;
    final x = ((t - beat.start) / 2).clamp(0.0, 1.0);
    final blend = reduced ? 1.0 : x * x * (3 - 2 * x);
    double lerp(double a, double b) => a + (b - a) * blend;
    final window = NormalRect(
      lerp(from.left, beat.window.left),
      lerp(from.top, beat.window.top),
      lerp(from.right, beat.window.right),
      lerp(from.bottom, beat.window.bottom),
    );
    final g = beat.gesture;
    final phase =
        reduced || g == null || t < g.start || t >= g.start + g.duration
        ? 0.0
        : (t - g.start) / g.duration;
    return PlateSample(i, beat, window, phase);
  }
}
