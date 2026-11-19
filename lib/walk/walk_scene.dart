import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart' as fs;
import 'package:vector_math/vector_math.dart' as vm;

import 'walk.dart';
import 'walk_controller.dart';

typedef LoadBytes = Future<ByteData> Function(String asset);

/// Whether this build can draw an immersive walk: Flutter GPU must be on
/// (AndroidManifest `EnableFlutterGPU`) and Impeller running. Widget tests
/// and devices without it get the plan and the stills' captions instead.
bool walkBackendAvailable() {
  try {
    gpu.gpuContext;
    return true;
  } on Object {
    return false;
  }
}

/// The walk as a flutter_scene scene (P14's immersive backend): the
/// prototypes from the model, instanced on the hall's grid and again upside
/// down under the water, with unlit materials whose light is baked into the
/// vertex colours, distance fog, a translucent rippling water plane and, on
/// request, fish.
class WalkScene {
  WalkScene._(this.manifest, this.scene);
  final WalkManifest manifest;
  final fs.Scene scene;

  /// flutter_scene's camera is left-handed (right = up × forward) while the
  /// walk's model and plan are glTF's right-handed frame: everything hangs
  /// under a z mirror, and [camera] mirrors the eye to match, so the hall is
  /// not drawn back to front and the leader lines (vector_math, right-handed)
  /// land on what they name. The renderer flips culling under the mirror.
  final world = fs.Node(
    name: 'world',
    localTransform: vm.Matrix4.diagonal3Values(1, 1, -1),
  );

  // The hall, the carved heads and the weeping column, each with its
  // reflection's own dimmed material, so the reveal can light them apart.
  final hall = fs.UnlitMaterial(), hallMirror = fs.UnlitMaterial();
  final heads = fs.UnlitMaterial(), headsMirror = fs.UnlitMaterial();
  final water = fs.UnlitMaterial(), fishMaterial = fs.UnlitMaterial();
  final faces = <fs.UnlitMaterial>[];
  final _fish = <fs.Node>[];
  final _fishPhase = <double>[];
  int instances = 0;
  int triangles = 0;

  static Future<WalkScene> load(WalkManifest m, {LoadBytes? loadBytes}) async {
    await fs.Scene.initializeStaticResources();
    final bytes = await (loadBytes ?? rootBundle.load)(m.model);
    final root = await fs.Node.fromGlbBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    final scene = fs.Scene()
      ..antiAliasingMode = fs.AntiAliasingMode.auto
      ..toneMapping = fs.ToneMappingMode.pbrNeutral;
    scene.fog
      ..enabled = true
      ..mode = fs.FogMode.exponentialSquared
      ..density = m.fogDensity
      ..color = vm.Vector3(m.fogColour[0], m.fogColour[1], m.fogColour[2]);
    final w = WalkScene._(m, scene);
    await w._build(root);
    scene.add(w.world);
    return w;
  }

  fs.Geometry _geometry(fs.Node root, String name) {
    final node = root.getChildByName(name);
    final mesh = node?.mesh;
    if (mesh == null || mesh.primitives.isEmpty) {
      throw FormatException('${manifest.id}: no prototype $name');
    }
    return mesh.primitives.first.geometry;
  }

  Future<void> _build(fs.Node root) async {
    final g = manifest.grid;
    final dim = manifest.mirrorDim;
    for (final m in [hall, heads, water, fishMaterial]) {
      m.vertexColorWeight = 1;
    }
    hallMirror
      ..vertexColorWeight = 1
      ..baseColorFactor = vm.Vector4(dim[0], dim[1], dim[2], 1);
    headsMirror
      ..vertexColorWeight = 1
      ..baseColorFactor = vm.Vector4(dim[0], dim[1], dim[2], 1);
    final weeping = fs.UnlitMaterial()
      ..vertexColorWeight = 1
      ..baseColorTexture = await fs.Texture2D.fromAsset(
        manifest.textures['weeping']!,
      );
    final weepingMirror = fs.UnlitMaterial()
      ..vertexColorWeight = 1
      ..baseColorTexture = weeping.baseColorTexture
      ..baseColorFactor = vm.Vector4(dim[0], dim[1], dim[2], 1);
    faces.addAll([weeping, weepingMirror]);

    // Prototype → instanced meshes, the hall's and its reflection's.
    final sets = <String, (fs.InstancedMesh, fs.InstancedMesh)>{};
    (fs.InstancedMesh, fs.InstancedMesh) set(
      String name,
      fs.Material real,
      fs.Material mirror,
    ) => sets.putIfAbsent(name, () {
      final geometry = _geometry(root, name);
      return (
        fs.InstancedMesh(
          geometry: geometry,
          material: real,
          cullInstances: true,
        ),
        fs.InstancedMesh(
          geometry: geometry,
          material: mirror,
          cullInstances: true,
        ),
      );
    });
    final mirror = vm.Matrix4.identity()
      ..setEntry(1, 1, -1)
      ..setEntry(1, 3, 2 * g.waterLevel);
    void place(
      String name,
      vm.Matrix4 at, {
      fs.Material? real,
      fs.Material? reflected,
    }) {
      final (a, b) = set(name, real ?? hall, reflected ?? hallMirror);
      a.addInstance(at);
      b.addInstance(mirror * at);
      instances += 2;
      triangles += 2 * (manifest.prototypes[name] ?? 0);
    }

    vm.Matrix4 at(double x, double z, [double turn = 0]) =>
        vm.Matrix4.translationValues(x, 0, z)..rotateY(turn);

    var k = 0;
    for (var a = 1; a <= g.along; a++) {
      for (var b = 1; b <= g.across; b++) {
        final kind = manifest.capitals[k];
        final turn = int.parse(manifest.turns[k]) * math.pi / 2;
        k++;
        final (x, z) = g.column(a, b);
        final special = manifest.specialAt(a, b);
        if (special == null) {
          place('column-$kind', at(x, z, turn));
        } else if (special.carvedBase) {
          place(
            special.prototype,
            at(x, z),
            real: heads,
            reflected: headsMirror,
          );
          place(
            'column-S',
            at(x, z, turn),
            real: heads,
            reflected: headsMirror,
          );
          final photo = manifest.photos[special.prototype];
          final weight = photo == null ? 1.0 : 0.0;
          final face = fs.UnlitMaterial()..vertexColorWeight = weight;
          if (photo != null) {
            face.baseColorTexture = await fs.Texture2D.fromAsset(photo);
          }
          final faceMirror = fs.UnlitMaterial()
            ..vertexColorWeight = weight
            ..baseColorTexture = face.baseColorTexture
            ..baseColorFactor = vm.Vector4(dim[0], dim[1], dim[2], 1);
          faces.addAll([face, faceMirror]);
          final mesh = fs.InstancedMesh(
            geometry: _geometry(root, '${special.prototype}-face'),
            material: face,
          )..addInstance(at(x, z));
          final mesh2 = fs.InstancedMesh(
            geometry: _geometry(root, '${special.prototype}-face'),
            material: faceMirror,
          )..addInstance(mirror * at(x, z));
          for (final i in [mesh, mesh2]) {
            world.add(
              fs.Node(name: '${special.id}-face')
                ..addComponent(fs.InstancedMeshComponent(i)),
            );
          }
        } else {
          place(
            special.prototype,
            at(x, z, turn),
            real: weeping,
            reflected: weepingMirror,
          );
        }
      }
    }
    for (var a = 0; a <= g.along; a++) {
      for (var b = 0; b <= g.across; b++) {
        place('bay', at((a + .5) * g.pitchX, (b + .5) * g.pitchZ));
      }
    }
    for (var a = 0; a <= g.along; a++) {
      place('wall-long', at((a + .5) * g.pitchX, 0));
      place('wall-long', at((a + .5) * g.pitchX, g.width, math.pi));
      if (a > 0) {
        place('pilaster', at(a * g.pitchX, 0));
        place('pilaster', at(a * g.pitchX, g.width, math.pi));
      }
    }
    for (var b = 0; b <= g.across; b++) {
      place('wall-short', at(0, (b + .5) * g.pitchZ, -math.pi / 2));
      place('wall-short', at(g.length, (b + .5) * g.pitchZ, math.pi / 2));
      if (b > 0) {
        place('pilaster', at(0, b * g.pitchZ, -math.pi / 2));
        place('pilaster', at(g.length, b * g.pitchZ, math.pi / 2));
      }
    }
    place('deck', vm.Matrix4.identity());
    for (final (a, b) in sets.values) {
      world.add(
        fs.Node(name: 'set')..addComponent(fs.InstancedMeshComponent(a)),
      );
      world.add(
        fs.Node(name: 'set')..addComponent(fs.InstancedMeshComponent(b)),
      );
    }

    // The water: translucent, its ripple drifting.
    water
      ..alphaMode = fs.AlphaMode.blend
      ..baseColorTexture = await fs.Texture2D.fromAsset(
        manifest.textures['ripple']!,
      )
      ..vertexColorWeight = 0
      ..baseColorFactor = vm.Vector4(
        manifest.waterColour[0],
        manifest.waterColour[1],
        manifest.waterColour[2],
        manifest.waterAlpha,
      );
    final waterMesh = fs.Mesh(_geometry(root, 'water'), water);
    world.add(fs.Node(name: 'water', mesh: waterMesh));
    triangles += manifest.prototypes['water'] ?? 0;

    final fishGeometry = _geometry(root, 'fish');
    final rng = math.Random(manifest.fishCount);
    for (var i = 0; i < manifest.fishCount; i++) {
      final node = fs.Node(
        name: 'fish',
        mesh: fs.Mesh(fishGeometry, fishMaterial),
      )..visible = false;
      _fish.add(node);
      _fishPhase.add(rng.nextDouble() * 1000);
      world.add(node);
    }
  }

  /// Per frame: the reveal's lights, the water's drift and the fish.
  void update(WalkController c, double elapsed) {
    final hallK = c.hallLight, headK = c.headLight;
    final dim = manifest.mirrorDim;
    hall.baseColorFactor = vm.Vector4(hallK, hallK, hallK, 1);
    hallMirror.baseColorFactor = vm.Vector4(
      dim[0] * hallK,
      dim[1] * hallK,
      dim[2] * hallK,
      1,
    );
    heads.baseColorFactor = vm.Vector4(headK, headK, headK, 1);
    headsMirror.baseColorFactor = vm.Vector4(
      dim[0] * headK,
      dim[1] * headK,
      dim[2] * headK,
      1,
    );
    for (var i = 0; i < faces.length; i++) {
      final k = i < 2 ? hallK : headK;
      final m = i.isOdd ? dim[0] : 1.0;
      faces[i].baseColorFactor = vm.Vector4(k * m, k * m, k * m, 1);
    }
    final drift = c.reduced ? 0.0 : elapsed * .012;
    water.baseColorTextureTransform.offset = vm.Vector2(drift, drift * .6);
    water.baseColorFactor = vm.Vector4(
      manifest.waterColour[0],
      manifest.waterColour[1],
      manifest.waterColour[2],
      manifest.waterAlpha * (hallK * .7 + .3),
    );
    final g = manifest.grid, eye = c.camera.eye;
    for (var i = 0; i < _fish.length; i++) {
      final node = _fish[i];
      node.visible = c.fish;
      if (!c.fish) continue;
      // Each fish circles a point near the eye, slowly, just under the
      // surface.
      final p = _fishPhase[i];
      final t = elapsed * (.18 + (i % 5) * .03) + p;
      final cx = (eye.x + math.sin(p) * 6).clamp(1.0, g.length - 1);
      final cz = (eye.z + math.cos(p * 1.7) * 4).clamp(1.0, g.width - 1);
      final r = 1.6 + (i % 3) * .7;
      final x = cx + math.cos(t) * r, z = cz + math.sin(t) * r;
      final heading = t + math.pi / 2;
      node.localTransform = vm.Matrix4.translationValues(
        x,
        g.waterLevel - .22 - (i % 3) * .08,
        z,
      )..rotateY(-heading);
    }
  }

  fs.PerspectiveCamera camera(WalkCamera c) => fs.PerspectiveCamera(
    fovRadiansY: c.fovY,
    position: vm.Vector3(c.eye.x, c.eye.y, -c.eye.z),
    target: vm.Vector3(c.look.x, c.look.y, -c.look.z),
    up: vm.Vector3(0, 1, 0),
    fovNear: .1,
    fovFar: manifest.fogFar,
  );

  void dispose() => scene.dispose();
}

/// Projects walk points onto the screen with the same camera the scene
/// draws with, for the callouts' leader lines.
class WalkProjector {
  WalkProjector(WalkCamera c, this.width, this.height) {
    final eye = vm.Vector3(c.eye.x, c.eye.y, c.eye.z);
    final view = vm.makeViewMatrix(
      eye,
      vm.Vector3(c.look.x, c.look.y, c.look.z),
      vm.Vector3(0, 1, 0),
    );
    final projection = vm.makePerspectiveMatrix(
      c.fovY,
      width / math.max(1, height),
      .1,
      1000,
    );
    _m = projection * view;
  }
  final double width, height;
  late final vm.Matrix4 _m;

  /// Screen position, or null behind the eye.
  (double, double)? project(WalkPoint p) {
    final v = _m.transform(vm.Vector4(p.x, p.y, p.z, 1));
    if (v.w <= .05) return null;
    final x = v.x / v.w, y = v.y / v.w;
    return ((x + 1) / 2 * width, (1 - y) / 2 * height);
  }
}
