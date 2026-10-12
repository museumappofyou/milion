import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../content/models.dart';
import '../content/registry.dart';

String detailHeroTag(Detail d) => 'detail-${d.id}';

/// The pool rotates by calendar date: same day, same detail, on every device.
/// [playable] keeps only details whose Milestone can open (its plate loaded);
/// null when nothing in the pool can.
Detail? detailOfDay(
  ContentRegistry registry,
  DateTime now, {
  bool Function(Detail)? playable,
}) {
  final pool = [
    for (final d in registry.details)
      if (playable?.call(d) ?? true) d,
  ];
  if (pool.isEmpty) return null;
  final day = DateTime.utc(now.year, now.month, now.day);
  final index = day.difference(DateTime.utc(2026)).inDays % pool.length;
  return pool[index];
}

/// Placement of a normalised [window] of a [source]-sized photo covering a box.
class CropGeometry {
  CropGeometry(Size box, Size source, NormalRect window) {
    final w = Size(window.width * source.width, window.height * source.height);
    scale = math.max(box.width / w.width, box.height / w.height);
    final shown = Size(box.width / scale, box.height / scale);
    final cx = (window.left + window.width / 2) * source.width;
    final cy = (window.top + window.height / 2) * source.height;
    origin = Offset(
      (cx - shown.width / 2).clamp(0, math.max(0, source.width - shown.width)),
      (cy - shown.height / 2).clamp(
        0,
        math.max(0, source.height - shown.height),
      ),
    );
    this.source = source;
  }
  late final double scale;

  /// Top-left of the visible region in source pixels.
  late final Offset origin;
  late final Size source;
  Offset toBox(double nx, double ny) =>
      (Offset(nx * source.width, ny * source.height) - origin) * scale;
}

/// A detail of an untouched photograph, cropped to cover its box. Used on both
/// ends of the Today → Milestone shared-element flight.
class DetailCrop extends StatelessWidget {
  const DetailCrop({
    super.key,
    required this.asset,
    required this.source,
    required this.window,
  });
  final String asset;
  final Size source;
  final NormalRect window;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final box = constraints.biggest;
      if (box.isEmpty) return const SizedBox.shrink();
      final g = CropGeometry(box, source, window);
      return ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: -g.origin.dx * g.scale,
              top: -g.origin.dy * g.scale,
              width: source.width * g.scale,
              height: source.height * g.scale,
              child: Image.asset(
                asset,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                excludeFromSemantics: true,
              ),
            ),
          ],
        ),
      );
    },
  );
}
