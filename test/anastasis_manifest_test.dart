import 'dart:convert';
import 'dart:ui' as ui;

import 'package:milion/models/anastasis_capture.dart';
import 'package:milion/services/anastasis_assets.dart';
import 'package:milion/services/conch_geometry.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// The artifact tab is data-driven from the prepared manifest; these checks
/// make sure the shipped assets and the manifest agree, and that every
/// hotspot can actually be lifted onto the conch.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('manifest describes every prepared capture', () async {
    final json = jsonDecode(
      await rootBundle.loadString(AnastasisAssets.manifestAsset),
    );
    final artifact = AnastasisArtifact.fromJson(
      (json as Map).cast<String, dynamic>(),
    );

    expect(artifact.id, 'F02');
    expect(artifact.room, 'Parekklesion');
    expect(artifact.surface, contains('semi-dome'));
    expect(artifact.captures.length, greaterThanOrEqualTo(20));

    const roles = {
      'texture',
      'wide',
      'flat-reference',
      'detail',
      'context',
      'historical',
      'capture',
      'guide',
    };
    for (final capture in artifact.captures) {
      expect(capture.file, startsWith('assets/anastasis/'));
      expect(roles, contains(capture.role));
      expect(capture.title, isNotEmpty);
      expect(capture.credit, isNotEmpty);
      expect(capture.width, greaterThan(0));
      expect(capture.height, greaterThan(0));
      // Every listed file must exist in the bundle.
      final data = await rootBundle.load(capture.file);
      expect(
        data.lengthInBytes,
        greaterThan(1000),
        reason: '${capture.file} looks empty',
      );
    }

    // The viewer texture is one of the captures and decodes to its stated
    // size.
    final texture = artifact.captures.firstWhere(
      (capture) => capture.file == artifact.textureFile,
    );
    final bytes = await rootBundle.load(texture.file);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    expect(frame.image.width, texture.width);
    expect(frame.image.height, texture.height);
    expect(texture.role, 'texture');

    // The flat reference is a separate, clean capture.
    final flat = artifact.captures.firstWhere(
      (capture) => capture.file == artifact.flatReferenceFile,
    );
    expect(flat.role, 'flat-reference');
    expect(flat.credit, contains('Caner'));
  });

  test(
    'hotspots are inside the painted panel and point at real captures',
    () async {
      final json = jsonDecode(
        await rootBundle.loadString(AnastasisAssets.manifestAsset),
      );
      final artifact = AnastasisArtifact.fromJson(
        (json as Map).cast<String, dynamic>(),
      );
      final surface = ConchSurface(
        params: const ConchParams(),
        textureSize: const ui.Size(2048, 1091),
      );

      expect(anastasisHotspots, isNotEmpty);
      for (final hotspot in anastasisHotspots) {
        expect(
          surface.isInsideField(hotspot.u, hotspot.v),
          isTrue,
          reason: '${hotspot.id} must sit on the painted panel',
        );
        expect(
          surface.texelForPhoto(hotspot.u, hotspot.v),
          isNotNull,
          reason: '${hotspot.id} must be liftable onto the conch',
        );
        expect(
          artifact.captureById(hotspot.captureId),
          isNotNull,
          reason: '${hotspot.id} needs its detail capture',
        );
        expect(hotspot.detail, isNotEmpty);
      }
    },
  );

  test('the prepared texture is the documented reference capture', () async {
    final json = jsonDecode(
      await rootBundle.loadString(AnastasisAssets.manifestAsset),
    );
    final artifact = AnastasisArtifact.fromJson(
      (json as Map).cast<String, dynamic>(),
    );
    final texture = artifact.captures.firstWhere(
      (capture) => capture.role == 'texture',
    );
    expect(texture.source, contains('17.18.48'));
    expect(texture.width, 2048);
    // The traced outline is in this capture's normalized coordinates.
    final surface = ConchSurface(
      params: const ConchParams(),
      textureSize: ui.Size(texture.width.toDouble(), texture.height.toDouble()),
    );
    final extent = surface.panelExtent;
    expect(extent.left, greaterThan(0));
    expect(extent.right, lessThan(1));
    expect(extent.bottom, lessThan(0.95));
  });
}
