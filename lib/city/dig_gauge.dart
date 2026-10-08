import 'package:flutter/material.dart';

import '../content/models.dart';
import '../design/motion.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';

/// The edge rail of the dig. The thumb's year is shown in the readout; a
/// drag previews a layer (with a light detent), a release or tap snaps the
/// page to it. TalkBack gets one adjustable node that announces the year.
class DigGauge extends StatefulWidget {
  const DigGauge({
    super.key,
    required this.strata,
    required this.selected,
    required this.displayYear,
    required this.onPreview,
    required this.onCommit,
    this.onCancel,
  });
  final List<Stratum> strata;
  final int selected;
  final int displayYear;

  /// While the finger is down: update the plate/readout only.
  final ValueChanged<int> onPreview;

  /// Tap or release: snap the page to the layer.
  final ValueChanged<int> onCommit;

  /// Abandon a drag preview and return to the year under the reading line.
  final VoidCallback? onCancel;
  @override
  State<DigGauge> createState() => _DigGaugeState();
}

class _DigGaugeState extends State<DigGauge> {
  int? _dragIndex;

  void _cancelPreview() {
    if (_dragIndex == null) return;
    setState(() => _dragIndex = null);
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n, c = MeasureColors.of(context);
    final n = widget.strata.length;
    final year = widget.displayYear;
    final newer = widget.selected > 0
        ? widget.strata[widget.selected - 1].gaugeYear
        : year;
    final older = widget.selected < n - 1
        ? widget.strata[widget.selected + 1].gaugeYear
        : year;
    int indexAt(double y, double height) {
      const pad = 24.0;
      final step = (height - pad * 2) / (n - 1);
      return ((y - pad) / step).round().clamp(0, n - 1);
    }

    return Semantics(
      container: true,
      label: s.digDepthGauge,
      value: '$year',
      increasedValue: '$newer',
      decreasedValue: '$older',
      hint: s.digDepthHint,
      onIncrease: widget.selected > 0
          ? () => widget.onCommit(widget.selected - 1)
          : null,
      onDecrease: widget.selected < n - 1
          ? () => widget.onCommit(widget.selected + 1)
          : null,
      child: ExcludeSemantics(
        child: SizedBox(
          width: 56,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${widget.displayYear}',
                    maxLines: 1,
                    style: TypeRole.measurement.copyWith(color: c.accent),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  // Flutter ends an accepted drag even on PointerCancelEvent.
                  // Clear the preview at the raw-pointer boundary first.
                  builder: (context, constraints) => Listener(
                    onPointerCancel: (_) => _cancelPreview(),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) => widget.onCommit(
                        indexAt(
                          details.localPosition.dy,
                          constraints.maxHeight,
                        ),
                      ),
                      onVerticalDragStart: (details) {
                        final index = indexAt(
                          details.localPosition.dy,
                          constraints.maxHeight,
                        );
                        setState(() => _dragIndex = index);
                        widget.onPreview(index);
                      },
                      onVerticalDragUpdate: (details) {
                        final index = indexAt(
                          details.localPosition.dy,
                          constraints.maxHeight,
                        );
                        if (index != _dragIndex) {
                          setState(() => _dragIndex = index);
                          MotionToken.detent();
                          widget.onPreview(index);
                        }
                      },
                      onVerticalDragEnd: (_) {
                        final index = _dragIndex;
                        setState(() => _dragIndex = null);
                        if (index != null) widget.onCommit(index);
                      },
                      onVerticalDragCancel: _cancelPreview,
                      child: CustomPaint(
                        painter: _GaugePainter(
                          count: n,
                          selected: _dragIndex ?? widget.selected,
                          accent: c.accent,
                          line: c.line,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.count,
    required this.selected,
    required this.accent,
    required this.line,
  });
  final int count, selected;
  final Color accent, line;
  @override
  void paint(Canvas canvas, Size size) {
    const pad = 24.0;
    final x = size.width / 2;
    final top = pad, bottom = size.height - pad;
    final step = (bottom - top) / (count - 1);
    canvas.drawLine(
      Offset(x, top - 8),
      Offset(x, bottom + 8),
      Paint()
        ..color = line
        ..strokeWidth = 1,
    );
    for (var i = 0; i < count; i++) {
      final y = top + step * i;
      final active = i == selected;
      final half = active ? 17.0 : 11.0;
      canvas.drawLine(
        Offset(x - half, y),
        Offset(x + half, y),
        Paint()
          ..color = active ? accent : line
          ..strokeWidth = active ? 2 : 1,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.count != count ||
      old.selected != selected ||
      old.accent != accent ||
      old.line != line;
}
