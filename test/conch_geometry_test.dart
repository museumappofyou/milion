import 'dart:ui' show Offset, Rect, Size;

import 'package:milion/services/conch_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Geometry invariants of the Anastasis conch reconstruction. These pin the
/// behaviour the artifact tab depends on: a framed panel, a fixed orbit pivot
/// with real parallax at the rim, and a curvature control that changes the
/// shape of the bowl without changing the framing.
void main() {
  const textureSize = Size(2048, 1091);
  const viewSize = Size(1100, 660);

  ConchRenderer renderer([ConchParams params = const ConchParams()]) =>
      ConchRenderer(params: params, textureSize: textureSize);

  group('reference semi-dome', () {
    test(
      'the panel maps the traced outline extremes to the calibrated edges',
      () {
        final surface = renderer().surface;
        final extent = surface.panelExtent;
        expect(extent.left, closeTo(0.024, 0.002));
        expect(extent.top, closeTo(0.046, 0.002));
        expect(extent.right, closeTo(0.988, 0.002));
        expect(extent.bottom, closeTo(0.886, 0.002));

        final top = surface.texelForPanelFraction(0.5, 0.0);
        final bottom = surface.texelForPanelFraction(0.5, 1.0);
        final left = surface.texelForPanelFraction(0.0, 0.5);
        final right = surface.texelForPanelFraction(1.0, 0.5);
        expect(top.alpha, closeTo(const ConchParams().alphaTop, 1e-6));
        expect(bottom.alpha, closeTo(const ConchParams().alphaBottom, 1e-6));
        expect(left.theta, closeTo(-const ConchParams().thetaPanel, 1e-6));
        expect(right.theta, closeTo(const ConchParams().thetaPanel, 1e-6));
      },
    );

    test('texture coordinates outside the outline are never lifted', () {
      final surface = renderer().surface;
      // Corners of the photograph belong to the surrounding vault.
      for (final corner in const [
        Offset(0.02, 0.02),
        Offset(0.98, 0.02),
        Offset(0.02, 0.98),
        Offset(0.98, 0.98),
      ]) {
        expect(surface.texelForPhoto(corner.dx, corner.dy), isNull);
      }
      expect(surface.texelForPhoto(0.5, 0.5), isNotNull);
    });

    test('the default view frames the panel in the viewer', () {
      final mesh = renderer().build(viewSize: viewSize);
      expect(mesh.visibleVertices, greaterThan(3000));
      expect(mesh.indices.length ~/ 3, greaterThan(6000));
      final bounds = mesh.bounds!;
      expect(bounds.width, greaterThan(viewSize.width * 0.85));
      expect(bounds.width, lessThan(viewSize.width * 1.05));
      expect(bounds.height, greaterThan(viewSize.height * 0.6));
      expect(bounds.height, lessThan(viewSize.height * 1.05));
    });

    test('every hotspot anchor lands on the reconstructed surface', () {
      final mesh = renderer().build(
        viewSize: viewSize,
        anchors: const [
          ConchAnchor('christ', 0.513, 0.500),
          ConchAnchor('adam', 0.427, 0.673),
          ConchAnchor('eve', 0.663, 0.667),
          ConchAnchor('kings', 0.197, 0.493),
          ConchAnchor('righteous', 0.700, 0.480),
          ConchAnchor('satan', 0.573, 0.793),
          ConchAnchor('gates', 0.497, 0.870),
        ],
      );
      expect(mesh.anchors.length, 7);
      for (final anchor in mesh.anchors.values) {
        expect(anchor.dx, inInclusiveRange(0, viewSize.width));
        expect(anchor.dy, inInclusiveRange(0, viewSize.height));
      }
    });
  });

  group('parallax', () {
    test('the pivot holds while the rim swings', () {
      final surface = renderer().surface;
      final pivot = surface.texelForPanelFraction(0.5, 0.5).world;
      final rim = surface.texelForPanelFraction(0.03, 0.5).world;

      final pivotStart = surface.project(pivot, viewSize)!;
      final pivotMoved = surface.project(pivot, viewSize, yaw: 0.3)!;
      final rimStart = surface.project(rim, viewSize)!;
      final rimMoved = surface.project(rim, viewSize, yaw: 0.3)!;

      expect((pivotMoved - pivotStart).distance, lessThan(1));
      expect((rimMoved - rimStart).distance, greaterThan(25));
    });

    test(
      'pitching the viewpoint moves the crown end more than the springing end',
      () {
        final surface = renderer().surface;
        final top = surface.texelForPanelFraction(0.5, 0.05).world;
        final bottom = surface.texelForPanelFraction(0.5, 0.95).world;
        final topStart = surface.project(top, viewSize)!;
        final topMoved = surface.project(top, viewSize, pitch: -0.35)!;
        final bottomStart = surface.project(bottom, viewSize)!;
        final bottomMoved = surface.project(bottom, viewSize, pitch: -0.35)!;
        // The crown end of the panel is nearer the viewer, so pitching the
        // viewpoint shifts it much more than the springing end.
        final topShift = topMoved.dy - topStart.dy;
        final bottomShift = bottomMoved.dy - bottomStart.dy;
        expect(topShift.abs(), greaterThan(10));
        expect((topShift - bottomShift).abs(), greaterThan(10));
      },
    );
  });

  group('curvature control', () {
    test('a tighter apse deepens the sag of the lower edge', () {
      double sag(double radius) {
        final surface = renderer(ConchParams(radius: radius)).surface;
        final centre = surface.project(
          surface.texelForPanelFraction(0.5, 0.97).world,
          viewSize,
        )!;
        final side = surface.project(
          surface.texelForPanelFraction(0.06, 0.97).world,
          viewSize,
        )!;
        return centre.dy - side.dy;
      }

      final tight = sag(0.5);
      final reference = sag(1.0);
      final flat = sag(1.9);
      expect(tight, greaterThan(reference + 2));
      expect(reference, greaterThan(flat + 2));
    });

    test('changing the radius keeps the framing', () {
      Rect boundsFor(double radius) =>
          renderer(ConchParams(radius: radius))
              .build(viewSize: viewSize)
              .bounds!;

      final tight = boundsFor(0.5);
      final reference = boundsFor(1.0);
      final flat = boundsFor(1.9);
      expect((tight.width - reference.width).abs(), lessThan(60));
      expect((flat.width - reference.width).abs(), lessThan(60));
      expect((tight.height - reference.height).abs(), lessThan(60));
      expect((flat.height - reference.height).abs(), lessThan(60));
    });
  });

  test('the mesh drops grazing texels at the panel edge', () {
    final surface = renderer().surface;
    // A point on the extreme side of the panel is nearly edge-on to the
    // default viewpoint and must not be lifted.
    expect(surface.texelForPhoto(0.988, 0.42), anyOf(isNull, isNotNull));
    final rim = surface.texelForPanelFraction(0.999, 0.5);
    expect(
      rim.normal.dot((surface.cameraPosition - rim.world).normalized),
      greaterThan(0),
    );
  });
}
