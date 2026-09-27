import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/anastasis_capture.dart';
import '../services/conch_geometry.dart';
import '../services/anastasis_relief.dart';

/// Interactive 2.5D view of the Anastasis panel wrapped onto the apse
/// semi-dome.
///
/// The mesh is warped on the CPU (one vertex per grid intersection) and drawn
/// with [Canvas.drawVertices], so the parallax under a moving viewpoint is the
/// true parallax of the reconstructed conch rather than a fake offset.
class AnastasisDomeView extends StatefulWidget {
  const AnastasisDomeView({
    super.key,
    required this.texture,
    required this.params,
    required this.layers,
    required this.reliefControls,
    this.hotspots = const [],
    this.showGuides = false,
    this.sway = false,
    this.sourceWindow,
    this.settleOnRelease = true,
    this.onHotspotTap,
    this.onViewChanged,
  });

  final ui.Image texture;
  final ConchParams params;
  final List<ReliefLayer> layers;
  final ReliefControls reliefControls;
  final List<AnastasisHotspot> hotspots;
  final bool showGuides;

  /// Slow automatic viewpoint drift, for hands-off examination.
  final bool sway;
  final ui.Rect? sourceWindow;
  final bool settleOnRelease;
  final ValueChanged<AnastasisHotspot>? onHotspotTap;
  final VoidCallback? onViewChanged;

  @override
  State<AnastasisDomeView> createState() => AnastasisDomeViewState();
}

class AnastasisDomeViewState extends State<AnastasisDomeView>
    with TickerProviderStateMixin {
  late final AnimationController _swayController;
  late final AnimationController _settleController;
  ConchRenderer? _renderer;
  ConchParams? _rendererParams;

  double _yaw = 0;
  double _pitch = 0;
  double _baseYaw = 0;
  double _basePitch = 0;
  double _zoom = 1;
  double _gestureZoom = 1;
  Map<String, Offset> _anchorScreen = const {};
  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    _settleController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 650),
        )..addListener(() {
          if (!mounted) return;
          setState(() {
            final t = Curves.easeOutCubic.transform(_settleController.value);
            _yaw = _baseYaw * (1 - t);
            _pitch = _basePitch * (1 - t);
          });
          widget.onViewChanged?.call();
        });
    if (widget.sway) {
      _swayController.repeat(reverse: true);
    }
    _swayController.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _yaw = _baseYaw + math.sin(_swayController.value * math.pi * 2) * 0.16;
        _pitch =
            _basePitch + math.cos(_swayController.value * math.pi * 2) * 0.05;
      });
    });
  }

  @override
  void didUpdateWidget(AnastasisDomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sway != oldWidget.sway) {
      if (widget.sway) {
        _swayController.repeat(reverse: true);
      } else {
        _swayController.stop();
      }
    }
  }

  @override
  void dispose() {
    _swayController.dispose();
    _settleController.dispose();
    super.dispose();
  }

  /// Resets the viewpoint to the default capture framing.
  void resetView() {
    _settleController.stop();
    setState(() {
      _baseYaw = 0;
      _basePitch = 0;
      _yaw = 0;
      _pitch = 0;
      _zoom = 1;
    });
    widget.onViewChanged?.call();
  }

  /// Used by visual QA to capture reproducible viewpoints without a drag.
  void setViewAnglesForDebug(double yawDegrees, double pitchDegrees) {
    _settleController.stop();
    setState(() {
      _baseYaw = (yawDegrees * math.pi / 180).clamp(
        -widget.reliefControls.maxYaw,
        widget.reliefControls.maxYaw,
      );
      _basePitch = (pitchDegrees * math.pi / 180).clamp(
        -widget.reliefControls.maxPitch,
        widget.reliefControls.maxPitch,
      );
      _yaw = _baseYaw;
      _pitch = _basePitch;
    });
    widget.onViewChanged?.call();
  }

  /// Current viewpoint offsets in degrees, for the read-out under the viewer.
  (double, double) get viewAnglesDeg =>
      (_yaw * 180 / math.pi, _pitch * 180 / math.pi);

  ConchRenderer _rendererFor(ConchParams params) {
    if (_renderer == null || _rendererParams != params) {
      _rendererParams = params;
      _renderer = ConchRenderer(
        params: params,
        textureSize: Size(
          widget.texture.width.toDouble(),
          widget.texture.height.toDouble(),
        ),
        columns: 120,
        rows: 80,
      );
    }
    return _renderer!;
  }

  void _moveView(Offset delta) {
    if (_settleController.isAnimating) {
      _baseYaw = _yaw;
      _basePitch = _pitch;
    }
    _settleController.stop();
    final size = _lastSize;
    if (size.isEmpty) {
      return;
    }
    setState(() {
      _baseYaw = (_baseYaw + delta.dx / size.width * .55).clamp(
        -widget.reliefControls.maxYaw,
        widget.reliefControls.maxYaw,
      );
      _basePitch = (_basePitch + delta.dy / size.height * .38).clamp(
        -widget.reliefControls.maxPitch,
        widget.reliefControls.maxPitch,
      );
      if (!widget.sway) {
        _yaw = _baseYaw;
        _pitch = _basePitch;
      }
    });
    widget.onViewChanged?.call();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _gestureZoom = _zoom;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount > 1) {
      setState(() => _zoom = (_gestureZoom * details.scale).clamp(1.0, 3.0));
    } else {
      _moveView(details.focalPointDelta);
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (!widget.settleOnRelease) return;
    _settleController.forward(from: 0);
  }

  void _handleTap(TapUpDetails details) {
    AnastasisHotspot? best;
    var bestDistance = 30.0;
    for (final hotspot in widget.hotspots) {
      final anchor = _anchorScreen[hotspot.id];
      if (anchor == null) {
        continue;
      }
      final distance = (anchor - details.localPosition).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = hotspot;
      }
    }
    if (best != null) {
      widget.onHotspotTap?.call(best);
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = widget.params;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _lastSize = size;
        final effectiveControls = widget.reliefControls.copyWith(
          fov: widget.reliefControls.fov / _zoom,
        );
        final needsConch = widget.reliefControls.projection == 'conch';
        final renderer = needsConch ? _rendererFor(params) : null;
        final mesh = renderer?.build(
          viewSize: size,
          yaw: _yaw * widget.reliefControls.parallax,
          pitch: _pitch * widget.reliefControls.parallax,
          anchors: [
            for (final hotspot in widget.hotspots)
              ConchAnchor(hotspot.id, hotspot.u, hotspot.v),
          ],
        );
        final anchorPositions = widget.reliefControls.projection == 'photo'
            ? <String, Offset>{
                for (final hotspot in widget.hotspots)
                  hotspot.id: _photoAnchor(hotspot, size),
              }
            : mesh!.anchors;
        if (!_mapEquals(anchorPositions, _anchorScreen)) {
          _anchorScreen = anchorPositions;
        }
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          onScaleEnd: _handleScaleEnd,
          onTapUp: _handleTap,
          onDoubleTap: resetView,
          child: CustomPaint(
            size: size,
            painter: _ConchPainter(
              mesh: mesh,
              texture: widget.texture,
              showGuides: widget.showGuides,
              hotspots: widget.hotspots,
              anchors: anchorPositions,
              renderer: renderer,
              layers: widget.layers,
              controls: effectiveControls,
              yaw: _yaw,
              pitch: _pitch,
              sourceWindow: widget.sourceWindow,
            ),
          ),
        );
      },
    );
  }

  bool _mapEquals(Map<String, Offset> a, Map<String, Offset> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null || (other - entry.value).distance > 0.01) {
        return false;
      }
    }
    return true;
  }

  Offset _photoAnchor(AnastasisHotspot hotspot, Size size) {
    final window =
        widget.sourceWindow ??
        Rect.fromLTWH(
          0,
          0,
          widget.texture.width.toDouble(),
          widget.texture.height.toDouble(),
        );
    final scale =
        math.min(size.width / window.width, size.height / window.height) /
        (widget.reliefControls.fov / _zoom);
    return Offset(
      (size.width - window.width * scale) / 2 -
          window.left * scale +
          hotspot.u * widget.texture.width * scale,
      (size.height - window.height * scale) / 2 -
          window.top * scale +
          hotspot.v * widget.texture.height * scale,
    );
  }
}

class _ConchPainter extends CustomPainter {
  _ConchPainter({
    required this.mesh,
    required this.texture,
    required this.showGuides,
    required this.hotspots,
    required this.anchors,
    required this.renderer,
    required this.layers,
    required this.controls,
    required this.yaw,
    required this.pitch,
    required this.sourceWindow,
  });

  final ConchMeshData? mesh;
  final ui.Image texture;
  final bool showGuides;
  final List<AnastasisHotspot> hotspots;
  final Map<String, Offset> anchors;
  final ConchRenderer? renderer;
  final List<ReliefLayer> layers;
  final ReliefControls controls;
  final double yaw, pitch;
  final ui.Rect? sourceWindow;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackdrop(canvas, size);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    Rect? photoTarget;
    if (controls.projection == 'photo') {
      final window =
          sourceWindow ??
          Rect.fromLTWH(
            0,
            0,
            texture.width.toDouble(),
            texture.height.toDouble(),
          );
      final scale =
          math.min(size.width / window.width, size.height / window.height) /
          controls.fov;
      final target = Rect.fromLTWH(
        (size.width - window.width * scale) / 2,
        (size.height - window.height * scale) / 2,
        window.width * scale,
        window.height * scale,
      );
      photoTarget = target;
      if (controls.mode == 'sideAngle') {
        canvas.save();
        canvas.translate(size.width / 2, 0);
        canvas.scale(.573576436, 1);
        canvas.translate(-size.width / 2, 0);
      }
      canvas.drawImageRect(
        texture,
        window,
        target,
        Paint()..filterQuality = FilterQuality.medium,
      );
      if (controls.mode == 'sideAngle') canvas.restore();
    } else {
      _paintMesh(canvas);
    }
    if (controls.mode == 'masks' ||
        controls.mode == 'colors' ||
        controls.mode == 'depth' ||
        controls.mode == 'semanticDepth' ||
        controls.mode == 'localDepth' ||
        controls.mode == 'combinedDepth' ||
        controls.mode == 'normals' ||
        controls.mode == 'aoOnly' ||
        controls.mode == 'shadowOnly') {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = controls.mode == 'masks'
              ? Colors.black
              : const Color(0xC9000000),
      );
    }
    if (sourceWindow != null && photoTarget != null) {
      canvas.clipRect(photoTarget);
    }
    _paintRelief(canvas, size);
    canvas.restore();
    if (showGuides) {
      if (renderer != null) {
        _paintGuides(canvas, size);
      } else {
        _paintPhotoGuides(canvas, size);
      }
    }
    _paintAnchors(canvas);
  }

  void _paintBackdrop(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          rect.center,
          size.longestSide * 0.72,
          const [Color(0xFF2A2723), Color(0xFF100F12)],
        ),
    );
    // A hinted apse opening behind the panel, so the panel does not float.
    final opening = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.58),
      width: size.width * 0.92,
      height: size.height * 0.86,
    );
    canvas.drawOval(
      opening,
      Paint()
        ..shader = ui.Gradient.radial(
          opening.center,
          opening.height * 0.62,
          const [Color(0x1AFFF3D6), Color(0x00000000)],
        ),
    );
  }

  void _paintMesh(Canvas canvas) {
    final mesh = this.mesh!;
    final positions = Float32List(mesh.vertexCount * 2);
    final indices = <int>[];
    // Rebuild compacted vertex buffers: NaN vertices are dropped.
    final remap = List<int>.filled(mesh.vertexCount, -1);
    var count = 0;
    for (var i = 0; i < mesh.vertexCount; i++) {
      final x = mesh.positions[i * 2];
      final y = mesh.positions[i * 2 + 1];
      if (x.isNaN || y.isNaN) {
        continue;
      }
      remap[i] = count;
      positions[count * 2] = x;
      positions[count * 2 + 1] = y;
      count++;
    }
    for (var t = 0; t < mesh.indices.length; t += 3) {
      final a = remap[mesh.indices[t]];
      final b = remap[mesh.indices[t + 1]];
      final c = remap[mesh.indices[t + 2]];
      if (a < 0 || b < 0 || c < 0) {
        continue;
      }
      indices
        ..add(a)
        ..add(b)
        ..add(c);
    }
    if (indices.isEmpty) {
      return;
    }
    final compactPositions = Float32List(count * 2);
    compactPositions.setRange(0, count * 2, positions);
    final compactTexCoords = Float32List(count * 2);
    final compactColors = Int32List(count);
    for (var i = 0; i < mesh.vertexCount; i++) {
      final target = remap[i];
      if (target < 0) {
        continue;
      }
      compactTexCoords[target * 2] = mesh.texCoords[i * 2];
      compactTexCoords[target * 2 + 1] = mesh.texCoords[i * 2 + 1];
      compactColors[target] = mesh.colors[i];
    }
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      compactPositions,
      textureCoordinates: compactTexCoords,
      colors: compactColors,
      indices: Uint16List.fromList(indices),
    );
    final paint = Paint()
      ..shader = ui.ImageShader(
        texture,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
        filterQuality: FilterQuality.medium,
      )
      ..isAntiAlias = true;
    canvas.drawVertices(vertices, BlendMode.modulate, paint);
  }

  void _paintRelief(Canvas canvas, Size size) {
    if (controls.preset == 'FLAT_ORIGINAL' || controls.mode == 'flat') {
      return;
    }
    final conchProjector = renderer == null
        ? null
        : ReliefProjector(renderer!.surface);
    final photoProjector = PhotoReliefProjector(
      Size(texture.width.toDouble(), texture.height.toDouble()),
      sourceWindow: sourceWindow,
    );
    final textureFilter = controls.textureQuality >= .75
        ? FilterQuality.medium
        : FilterQuality.low;
    final staticReliefBlend = controls.reliefScale.clamp(0.0, 1.0);
    final staticReliefGain = math.max(1.0, controls.reliefScale);
    for (final layer in layers) {
      if (controls.visibility[layer.id] == false) continue;
      if (controls.solo.isNotEmpty && controls.solo != layer.id) continue;
      final geometry = controls.projection == 'photo'
          ? photoProjector.build(layer, size, yaw, pitch, controls)
          : conchProjector!.build(layer, size, yaw, pitch, controls);
      if (geometry == null) continue;
      final mode = controls.mode;
      final paintedRelief = mode == 'relief' || mode == 'sideAngle';
      if (paintedRelief && controls.contactShadow > 0) {
        final shadow = Paint()
          ..shader = ui.ImageShader(
            layer.shadowTexture,
            TileMode.clamp,
            TileMode.clamp,
            Matrix4.identity().storage,
            filterQuality: textureFilter,
          )
          ..color = Color.fromRGBO(
            255,
            255,
            255,
            (controls.contactShadow *
                    (.5 + .5 * controls.bevel) *
                    staticReliefBlend *
                    staticReliefGain)
                .clamp(0, 1),
          )
          ..isAntiAlias = true;
        canvas.drawVertices(geometry.vertices, BlendMode.modulate, shadow);
      }
      if (mode == 'original' &&
          controls.projection == 'photo' &&
          controls.depthScale > 0 &&
          (layer.id == 'christ' || layer.id == 'adam' || layer.id == 'eve')) {
        final strength = layer.id == 'christ'
            ? .17 * controls.christEdgeSeparation
            : .09;
        final shadow = Paint()
          ..shader = ui.ImageShader(
            layer.edge,
            TileMode.clamp,
            TileMode.clamp,
            Matrix4.identity().storage,
            filterQuality: textureFilter,
          )
          ..colorFilter = ColorFilter.mode(
            Color.fromRGBO(45, 33, 23, strength),
            BlendMode.srcIn,
          )
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, controls.feather)
          ..isAntiAlias = true;
        canvas.save();
        canvas.translate(0, 1.5);
        canvas.drawVertices(geometry.vertices, BlendMode.modulate, shadow);
        canvas.restore();
      }
      final image = switch (mode) {
        'edges' => layer.edge,
        'relief' || 'sideAngle' => layer.litTexture,
        'normals' => layer.normalTexture,
        'aoOnly' => layer.aoTexture,
        'shadowOnly' => layer.shadowTexture,
        'localDepth' => layer.heightViz,
        'combinedDepth' => layer.combinedViz,
        _ => layer.texture,
      };
      final opacity = controls.opacities[layer.id] ?? 1.0;
      if (paintedRelief && staticReliefBlend < 1) {
        final sourcePaint = Paint()
          ..shader = ui.ImageShader(
            layer.texture,
            TileMode.clamp,
            TileMode.clamp,
            Matrix4.identity().storage,
            filterQuality: textureFilter,
          )
          ..color = Color.fromRGBO(255, 255, 255, opacity)
          ..isAntiAlias = true;
        canvas.drawVertices(geometry.vertices, BlendMode.modulate, sourcePaint);
      }
      final paint = Paint()
        ..shader = ui.ImageShader(
          image,
          TileMode.clamp,
          TileMode.clamp,
          Matrix4.identity().storage,
          filterQuality: textureFilter,
        )
        ..isAntiAlias = true
        ..color = Color.fromRGBO(
          255,
          255,
          255,
          paintedRelief ? opacity * staticReliefBlend : opacity,
        );
      if (mode == 'colors') {
        paint.colorFilter = ColorFilter.mode(layer.color, BlendMode.srcIn);
      } else if (mode == 'masks') {
        paint.colorFilter = const ColorFilter.mode(
          Colors.white,
          BlendMode.srcIn,
        );
      } else if (mode == 'depth' || mode == 'semanticDepth') {
        final t = ((controls.depths[layer.id] ?? layer.depth) / .4).clamp(
          0.0,
          1.0,
        );
        paint.colorFilter = ColorFilter.mode(
          Color.lerp(Colors.blue, Colors.red, t)!,
          BlendMode.srcIn,
        );
      } else if ((mode == 'original' || paintedRelief) &&
          (controls.saturation != 1 ||
              controls.contrast != 1 ||
              controls.brightness != 0 ||
              layer.id == 'christ')) {
        final s =
                controls.saturation *
                (layer.id == 'christ' ? controls.christSaturation : 1),
            c =
                controls.contrast *
                (layer.id == 'christ' ? controls.christContrast : 1),
            b =
                (controls.brightness +
                    (layer.id == 'christ' ? controls.christBrightness : 0)) *
                255;
        final rw = .213 * (1 - s), gw = .715 * (1 - s), bw = .072 * (1 - s);
        paint.colorFilter = ColorFilter.matrix([
          c * (rw + s),
          c * gw,
          c * bw,
          0,
          128 * (1 - c) + b,
          c * rw,
          c * (gw + s),
          c * bw,
          0,
          128 * (1 - c) + b,
          c * rw,
          c * gw,
          c * (bw + s),
          0,
          128 * (1 - c) + b,
          0,
          0,
          0,
          1,
          0,
        ]);
      }
      canvas.drawVertices(geometry.vertices, BlendMode.modulate, paint);
      if (paintedRelief && controls.aoIntensity > 0) {
        final aoPaint = Paint()
          ..shader = ui.ImageShader(
            layer.aoOverlay,
            TileMode.clamp,
            TileMode.clamp,
            Matrix4.identity().storage,
            filterQuality: textureFilter,
          )
          ..color = Color.fromRGBO(
            255,
            255,
            255,
            (controls.aoIntensity * staticReliefBlend * staticReliefGain).clamp(
              0,
              1,
            ),
          )
          ..isAntiAlias = true;
        canvas.drawVertices(geometry.vertices, BlendMode.modulate, aoPaint);
        if (controls.aoIntensity * staticReliefBlend * staticReliefGain > 1) {
          aoPaint.color = Color.fromRGBO(
            255,
            255,
            255,
            (controls.aoIntensity * staticReliefBlend * staticReliefGain - 1)
                .clamp(0, 1),
          );
          canvas.drawVertices(geometry.vertices, BlendMode.modulate, aoPaint);
        }
      }
      if (mode == 'wireframe') {
        // Geometry is visualized with transparent source and a grid over each
        // tight crop. The mesh itself, including local displacement, remains
        // the one used for the painted render.
        final coords = geometry.positions;
        final line = Paint()
          ..color = layer.color.withValues(alpha: .45)
          ..strokeWidth = .55
          ..style = PaintingStyle.stroke;
        for (var i = 0; i < coords.length - 4; i += 10) {
          if (coords[i].isFinite && coords[i + 2].isFinite) {
            canvas.drawLine(
              Offset(coords[i], coords[i + 1]),
              Offset(coords[i + 2], coords[i + 3]),
              line,
            );
          }
        }
      }
    }
  }

  void _paintGuides(Canvas canvas, Size size) {
    final surface = renderer!.surface;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0x66F2D48A);
    final boundary = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xAAF2D48A);

    // Meridians and parallels of the conch.
    for (var thetaDeg = -60; thetaDeg <= 60; thetaDeg += 30) {
      _drawCurve(
        canvas,
        size,
        [
          for (var i = 0; i <= 24; i++)
            (
              surface.params.alphaBottom +
                  (surface.params.alphaTop - surface.params.alphaBottom) *
                      i /
                      24,
              thetaDeg * math.pi / 180,
            ) as (double, double)?,
        ],
        stroke,
        surface,
      );
    }
    for (var alphaDeg = 10; alphaDeg <= 50; alphaDeg += 10) {
      _drawCurve(
        canvas,
        size,
        [
          for (var i = 0; i <= 40; i++)
            (
              alphaDeg * math.pi / 180,
              -surface.params.thetaPanel +
                  2 * surface.params.thetaPanel * i / 40,
            ) as (double, double)?,
        ],
        stroke,
        surface,
      );
    }
    // The panel's outer edge.
    _drawCurve(
      canvas,
      size,
      [for (var i = 0; i <= 60; i++) _panelBoundaryPoint(surface, i / 60)],
      boundary,
      surface,
      wrap: true,
    );
  }

  void _paintPhotoGuides(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / texture.width,
      size.height / texture.height,
    );
    final left = (size.width - texture.width * scale) / 2;
    final top = (size.height - texture.height * scale) / 2;
    final width = texture.width * scale, height = texture.height * scale;
    final paint = Paint()
      ..color = const Color(0x99F2D48A)
      ..strokeWidth = .7;
    for (var i = 1; i < 10; i++) {
      final x = left + width * i / 10, y = top + height * i / 10;
      canvas.drawLine(Offset(x, top), Offset(x, top + height), paint);
      canvas.drawLine(Offset(left, y), Offset(left + width, y), paint);
    }
  }

  (double, double)? _panelBoundaryPoint(ConchSurface surface, double t) {
    // Sample the traced outline in photograph space, then lift it to the
    // conch exactly like the texture mapping does.
    final outline = surface.fieldOutline;
    final scaled = (t * outline.length) % outline.length;
    final index = scaled.floor() % outline.length;
    final next = (index + 1) % outline.length;
    final local = scaled - scaled.floor();
    final point = Offset(
      outline[index].dx + (outline[next].dx - outline[index].dx) * local,
      outline[index].dy + (outline[next].dy - outline[index].dy) * local,
    );
    final texel = surface.texelForPhoto(point.dx, point.dy);
    if (texel == null) {
      return null;
    }
    return (texel.alpha, texel.theta);
  }

  void _drawCurve(
    Canvas canvas,
    Size size,
    List<(double, double)?> points,
    Paint paint,
    ConchSurface surface, {
    bool wrap = false,
  }) {
    final path = Path();
    var started = false;
    for (final point in points) {
      if (point == null) {
        started = false;
        continue;
      }
      final (alpha, theta) = point;
      final projected = surface.project(surface.conchPoint(alpha, theta), size);
      if (projected == null) {
        started = false;
        continue;
      }
      if (!started) {
        path.moveTo(projected.dx, projected.dy);
        started = true;
      } else {
        path.lineTo(projected.dx, projected.dy);
      }
    }
    if (wrap) {
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  void _paintAnchors(Canvas canvas) {
    for (final hotspot in hotspots) {
      final position = anchors[hotspot.id];
      if (position == null) {
        continue;
      }
      final marker = Paint()..color = const Color(0xFFF2D48A);
      canvas.drawCircle(position, 5.5, marker);
      canvas.drawCircle(
        position,
        9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0x88F2D48A),
      );
      if (!showGuides) {
        continue;
      }
      final label = TextPainter(
        text: TextSpan(
          text: hotspot.label,
          style: const TextStyle(
            fontSize: 11.5,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Color(0xCC000000), blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelPosition = Offset(
        position.dx - label.width / 2,
        position.dy - label.height - 14,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            labelPosition.dx - 5,
            labelPosition.dy - 2,
            label.width + 10,
            label.height + 4,
          ),
          const Radius.circular(6),
        ),
        Paint()..color = const Color(0xB3121214),
      );
      label.paint(canvas, labelPosition);
    }
  }

  @override
  bool shouldRepaint(_ConchPainter oldDelegate) {
    return oldDelegate.mesh != mesh ||
        oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.controls != controls ||
        oldDelegate.sourceWindow != sourceWindow ||
        oldDelegate.layers != layers ||
        oldDelegate.texture != texture ||
        oldDelegate.showGuides != showGuides ||
        oldDelegate.hotspots != hotspots;
  }
}
