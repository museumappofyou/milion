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

/// The walk as a flutter_scene scene (P14's immersive backend): real
/// photo-textured spolia column shafts & bases, carved Corinthian and
/// unfinished cushion capitals, concentric brick cross vaults, 2022 seismic
/// tie-rods, glowing water-edge uplights, mirrored reflections under dual
/// counter-drifting translucent water & caustic planes, and optional fish.
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

  // Material pairs (real + mirrored) grouped by lighting channel so the reveal
  // lights the carved heads first and then brings up the hall seamlessly.
  final _hallMats = <(fs.UnlitMaterial, fs.UnlitMaterial, double)>[];
  final _headMats = <(fs.UnlitMaterial, fs.UnlitMaterial, double)>[];
  final water = fs.UnlitMaterial();
  final waterCaustics = fs.UnlitMaterial();
  final fishMaterial = fs.UnlitMaterial();
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
    water.vertexColorWeight = 0;
    waterCaustics.vertexColorWeight = 0;
    fishMaterial.vertexColorWeight = 1;

    Future<(fs.UnlitMaterial, fs.UnlitMaterial)> pair({
      String? textureKey,
      String? textureAsset,
      double vertexWeight = 1.0,
      double gain = 1.0,
      bool head = false,
    }) async {
      final asset =
          textureAsset ??
          (textureKey == null ? null : manifest.textures[textureKey]);
      final tex = asset == null ? null : await fs.Texture2D.fromAsset(asset);
      final real = fs.UnlitMaterial()
        ..vertexColorWeight = vertexWeight
        ..baseColorFactor = vm.Vector4(gain, gain, gain, 1);
      final reflected = fs.UnlitMaterial()
        ..vertexColorWeight = vertexWeight
        ..baseColorFactor = vm.Vector4(
          dim[0] * gain,
          dim[1] * gain,
          dim[2] * gain,
          1,
        );
      if (tex != null) {
        real.baseColorTexture = tex;
        reflected.baseColorTexture = tex;
      }
      (head ? _headMats : _hallMats).add((real, reflected, gain));
      return (real, reflected);
    }

    // Real photo-derived shaft materials (6 spolia styles) + capital materials.
    final shaftMats = <String, (fs.UnlitMaterial, fs.UnlitMaterial)>{
      'M': await pair(textureKey: 'marbleSmooth'),
      'R': await pair(textureKey: 'marbleRough'),
      'T': await pair(textureKey: 'marbleBanded'),
      'D': await pair(textureKey: 'marbleWarm'),
      'W': await pair(textureKey: 'weeping'),
    };
    final (headMarble, headMarbleMirror) = await pair(
      textureKey: 'marbleSmooth',
      head: true,
    );
    final (headCapPlain, headCapPlainMirror) = await pair(
      textureKey: 'capPlain',
      head: true,
    );
    final (medusaStone, medusaStoneMirror) = await pair(
      textureKey: 'medusaStone',
      head: true,
    );
    final (capCorinthian, capCorinthianMirror) = await pair(
      textureKey: 'capCorinthian',
    );
    final (capPlain, capPlainMirror) = await pair(textureKey: 'capPlain');
    final (brick, brickMirror) = await pair(textureKey: 'brick');
    final (plaster, plasterMirror) = await pair(textureKey: 'plaster');
    final (deckMat, deckMirror) = await pair(textureKey: 'deck');
    final (railMat, railMirror) = await pair();
    final (stairMat, stairMirror) = await pair(textureKey: 'medusaStone');
    final (stripMat, stripMirror) = await pair(gain: 1.45);
    final (lampGlowMat, lampGlowMirror) = await pair(gain: 1.55);

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
      required fs.Material real,
      required fs.Material reflected,
    }) {
      final (a, b) = set(name, real, reflected);
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
        final capKind = manifest.capitals[k];
        final shaftStyle = manifest.shaftAt(k);
        final turn = int.parse(manifest.turns[k]) * math.pi / 2;
        k++;
        final (x, z) = g.column(a, b);
        final special = manifest.specialAt(a, b);
        if (special == null) {
          final (sReal, sMirror) = shaftMats[shaftStyle] ?? shaftMats['M']!;
          place(
            'shaft-$shaftStyle',
            at(x, z, turn),
            real: sReal,
            reflected: sMirror,
          );
          final isCorinthian = capKind == 'C';
          place(
            'cap-$capKind',
            at(x, z, turn),
            real: isCorinthian ? capCorinthian : capPlain,
            reflected: isCorinthian ? capCorinthianMirror : capPlainMirror,
          );
          // Warm water-edge spotlight pods beside alternating aisle columns
          // create crisp golden light reflections dancing on the water mirror.
          if ((a + b).isEven &&
              manifest.prototypes.containsKey('uplamp-body')) {
            place(
              'uplamp-body',
              at(x, z, turn),
              real: railMat,
              reflected: railMirror,
            );
            place(
              'uplamp-glow',
              at(x, z, turn),
              real: lampGlowMat,
              reflected: lampGlowMirror,
            );
          }
        } else if (special.carvedBase) {
          place(
            special.prototype,
            at(x, z),
            real: medusaStone,
            reflected: medusaStoneMirror,
          );
          place(
            'shaft-S',
            at(x, z, turn),
            real: headMarble,
            reflected: headMarbleMirror,
          );
          place(
            'cap-P',
            at(x, z, turn),
            real: headCapPlain,
            reflected: headCapPlainMirror,
          );
          final photo = manifest.photos[special.prototype];
          final (face, faceMirror) = await pair(
            textureAsset: photo,
            vertexWeight: photo == null ? 1.0 : 0.45,
            head: true,
          );
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
          // Hen's-eye / Peacock-eyed column: real photo shaft + unfinished block capital.
          final (wReal, wMirror) = shaftMats['W']!;
          place(
            special.prototype,
            at(x, z, turn),
            real: wReal,
            reflected: wMirror,
          );
          place(
            'cap-P',
            at(x, z, turn),
            real: capPlain,
            reflected: capPlainMirror,
          );
          if (manifest.prototypes.containsKey('uplamp-body')) {
            place(
              'uplamp-body',
              at(x, z, 0),
              real: railMat,
              reflected: railMirror,
            );
            place(
              'uplamp-glow',
              at(x, z, 0),
              real: lampGlowMat,
              reflected: lampGlowMirror,
            );
          }
        }
      }
    }
    final hasTieRods = manifest.prototypes.containsKey('tie-rods');
    for (var a = 0; a <= g.along; a++) {
      for (var b = 0; b <= g.across; b++) {
        final bx = (a + .5) * g.pitchX;
        final bz = (b + .5) * g.pitchZ;
        place('bay', at(bx, bz), real: brick, reflected: brickMirror);
        if (hasTieRods && a >= 1 && b >= 1 && a < g.along && b < g.across) {
          place('tie-rods', at(bx, bz), real: railMat, reflected: railMirror);
        }
      }
    }
    for (var a = 0; a <= g.along; a++) {
      place(
        'wall-long',
        at((a + .5) * g.pitchX, 0),
        real: plaster,
        reflected: plasterMirror,
      );
      place(
        'wall-long',
        at((a + .5) * g.pitchX, g.width, math.pi),
        real: plaster,
        reflected: plasterMirror,
      );
      if (a > 0) {
        place(
          'pilaster',
          at(a * g.pitchX, 0),
          real: plaster,
          reflected: plasterMirror,
        );
        place(
          'pilaster',
          at(a * g.pitchX, g.width, math.pi),
          real: plaster,
          reflected: plasterMirror,
        );
      }
    }
    for (var b = 0; b <= g.across; b++) {
      place(
        'wall-short',
        at(0, (b + .5) * g.pitchZ, -math.pi / 2),
        real: plaster,
        reflected: plasterMirror,
      );
      place(
        'wall-short',
        at(g.length, (b + .5) * g.pitchZ, math.pi / 2),
        real: plaster,
        reflected: plasterMirror,
      );
      if (b > 0) {
        place(
          'pilaster',
          at(0, b * g.pitchZ, -math.pi / 2),
          real: plaster,
          reflected: plasterMirror,
        );
        place(
          'pilaster',
          at(g.length, b * g.pitchZ, math.pi / 2),
          real: plaster,
          reflected: plasterMirror,
        );
      }
    }
    place('deck', vm.Matrix4.identity(), real: deckMat, reflected: deckMirror);
    if (manifest.prototypes.containsKey('deck-rail')) {
      place(
        'deck-rail',
        vm.Matrix4.identity(),
        real: railMat,
        reflected: railMirror,
      );
    }
    if (manifest.prototypes.containsKey('stair')) {
      place(
        'stair',
        vm.Matrix4.identity(),
        real: stairMat,
        reflected: stairMirror,
      );
    }
    if (manifest.prototypes.containsKey('deck-strip')) {
      place(
        'deck-strip',
        vm.Matrix4.identity(),
        real: stripMat,
        reflected: stripMirror,
      );
    }
    for (final (a, b) in sets.values) {
      world.add(
        fs.Node(name: 'set')..addComponent(fs.InstancedMeshComponent(a)),
      );
      world.add(
        fs.Node(name: 'set')..addComponent(fs.InstancedMeshComponent(b)),
      );
    }

    // Dual-layer liquid water:
    // 1) Primary translucent emerald-amber ripple plane (full coverage alpha)
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
    world.add(
      fs.Node(name: 'water', mesh: fs.Mesh(_geometry(root, 'water'), water)),
    );
    triangles += manifest.prototypes['water'] ?? 0;

    // 2) Counter-drifting warm golden liquid caustics sheet slightly above water
    if (manifest.prototypes.containsKey('water-caustics') &&
        manifest.textures.containsKey('caustics')) {
      waterCaustics
        ..alphaMode = fs.AlphaMode.blend
        ..baseColorTexture = await fs.Texture2D.fromAsset(
          manifest.textures['caustics']!,
        )
        ..vertexColorWeight = 0
        ..baseColorFactor = vm.Vector4(0.92, 0.68, 0.36, 0.28);
      world.add(
        fs.Node(
          name: 'water-caustics',
          mesh: fs.Mesh(_geometry(root, 'water-caustics'), waterCaustics),
        ),
      );
      triangles += manifest.prototypes['water-caustics'] ?? 0;
    }

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

  /// Per frame: the reveal's lights, dual-layer water shimmer, and fish.
  void update(WalkController c, double elapsed) {
    final hallK = c.hallLight, headK = c.headLight;
    final dim = manifest.mirrorDim;
    for (final (real, reflected, gain) in _hallMats) {
      final v = hallK * gain;
      real.baseColorFactor = vm.Vector4(v, v, v, 1);
      reflected.baseColorFactor = vm.Vector4(
        dim[0] * v,
        dim[1] * v,
        dim[2] * v,
        1,
      );
    }
    for (final (real, reflected, gain) in _headMats) {
      final v = headK * gain;
      real.baseColorFactor = vm.Vector4(v, v, v, 1);
      reflected.baseColorFactor = vm.Vector4(
        dim[0] * v,
        dim[1] * v,
        dim[2] * v,
        1,
      );
    }
    // Dual counter-drifting ripples produce organic shimmering water waves.
    final drift = c.reduced ? 0.0 : elapsed * .018;
    water.baseColorTextureTransform.offset = vm.Vector2(drift, drift * .65);
    water.baseColorFactor = vm.Vector4(
      manifest.waterColour[0] * (0.3 + 0.7 * hallK),
      manifest.waterColour[1] * (0.3 + 0.7 * hallK),
      manifest.waterColour[2] * (0.3 + 0.7 * hallK),
      manifest.waterAlpha * (hallK * .65 + .35),
    );
    final cDrift = c.reduced ? 0.0 : elapsed * .014;
    waterCaustics.baseColorTextureTransform.offset = vm.Vector2(
      -cDrift * .85,
      cDrift * 1.15,
    );
    final pulse = c.reduced ? 0.16 : 0.16 + 0.04 * math.sin(elapsed * 1.35);
    waterCaustics.baseColorFactor = vm.Vector4(
      0.84 * hallK,
      0.72 * hallK,
      0.54 * hallK,
      pulse * hallK,
    );

    final g = manifest.grid, eye = c.camera.eye;
    // Snap each fish orbit to the open centre of a vault bay near the eye so
    // fish always swim in open water and never clip through columns or bases.
    final baseBayX = (eye.x / g.pitchX).floor().clamp(0, g.along);
    final baseBayZ = (eye.z / g.pitchZ).floor().clamp(0, g.across);
    for (var i = 0; i < _fish.length; i++) {
      final node = _fish[i];
      node.visible = c.fish;
      if (!c.fish) continue;
      final p = _fishPhase[i];
      final t = elapsed * (.20 + (i % 5) * .03) + p;
      final ox = (i % 3) - 1;
      final oz = ((i ~/ 3) % 3) - 1;
      final bx = (baseBayX + ox).clamp(0, g.along);
      final bz = (baseBayZ + oz).clamp(0, g.across);
      final cx = (bx + 0.5) * g.pitchX;
      final cz = (bz + 0.5) * g.pitchZ;
      final r = 0.85 + (i % 3) * 0.22;
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
/// draws with, for the callouts' leader lines and interactive deck circles.
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
