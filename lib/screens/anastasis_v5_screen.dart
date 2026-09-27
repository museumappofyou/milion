import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../services/anastasis_assets.dart';
import '../services/anastasis_relief.dart';
import '../services/anastasis_relief_v5.dart';
import '../services/conch_geometry.dart';
import '../widgets/anastasis_dome_view.dart';

/// Phone-first, quiet presentation of the original fresco and its painted relief.
/// Long-press the title for the developer inspection controls.
///
/// The default is the fifth-pass static relief with the camera fixed and
/// centered: no parallax, drift, gyroscope or light motion. Passing
/// [initialControls] opens the archived third-pass layered renderer instead,
/// which the developer sheet can also switch to for comparison.
class AnastasisV5Screen extends StatefulWidget {
  const AnastasisV5Screen({super.key, this.initialControls});

  final ReliefControls? initialControls;

  /// Fifth-pass view: centered photo framing, all motion disabled.
  static const frozenControls = ReliefControls(
    preset: 'FLAT_ORIGINAL',
    mode: 'flat',
    depthScale: 0,
    reliefScale: 0,
    parallax: 0,
    maxYaw: 0,
    maxPitch: 0,
  );

  @override
  State<AnastasisV5Screen> createState() => _AnastasisV5ScreenState();
}

class _AnastasisV5ScreenState extends State<AnastasisV5Screen> {
  final AnastasisAssets _assets = AnastasisAssets();
  final AnastasisReliefV5 _v5 = AnastasisReliefV5();
  final GlobalKey<AnastasisDomeViewState> _viewKey = GlobalKey();
  late bool _legacy = widget.initialControls != null;
  late final Future<void> _loading = Future.wait([
    _assets.load(includeRelief: _legacy),
    _v5.load(),
  ]);
  Future<void>? _legacyLoading;
  late ReliefControls _controls =
      widget.initialControls ?? const ReliefControls();
  String _v5View = 'relief';
  bool _original = false;
  String _focus = 'Overview';

  static const _windows = <String, ui.Rect?>{
    'Overview': null,
    'Whole': null,
    'Figures': ui.Rect.fromLTRB(350, 265, 1720, 890),
    'Left rock': ui.Rect.fromLTRB(130, 120, 870, 545),
    'Right rock': ui.Rect.fromLTRB(1120, 120, 1900, 545),
  };

  @override
  void dispose() {
    _assets.dispose();
    _v5.dispose();
    super.dispose();
  }

  Future<void> _setLegacy(bool value) async {
    if (value && !_legacy) {
      _legacyLoading ??= _assets.relief.load();
      await _legacyLoading;
    }
    if (!mounted) return;
    setState(() => _legacy = value);
    _viewKey.currentState?.resetView();
  }

  void _setOriginal(bool value) {
    setState(() => _original = value);
    _viewKey.currentState?.resetView();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1B1918);
    return Scaffold(
      backgroundColor: ink,
      appBar: AppBar(
        backgroundColor: ink,
        foregroundColor: const Color(0xFFF4EBDC),
        toolbarHeight: 65,
        titleSpacing: 0,
        title: GestureDetector(
          onLongPress: _openDebug,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ANASTASIS',
                style: TextStyle(fontSize: 17, letterSpacing: 1.1),
              ),
              Text(
                'Parekklesion · painted relief',
                style: TextStyle(fontSize: 11, color: Color(0xFFBDB1A3)),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Reset view',
            onPressed: () => _viewKey.currentState?.resetView(),
            icon: const Icon(Icons.center_focus_strong_outlined),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _loading,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !_assets.isReady) {
            return Center(
              child: Text(
                'Relief assets unavailable: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          final v5View = _v5.view(_v5View) ?? _v5.views.first;
          final texture = _original || _legacy
              ? _assets.texture!
              : v5View.image!;
          final controls = !_legacy
              ? AnastasisV5Screen.frozenControls
              : _original
              ? ReliefControls.fromPreset('FLAT_ORIGINAL')
                    .copyWith(mode: 'flat')
              : _controls;
          final framedControls = controls.copyWith(
            fov: _focus == 'Overview' && controls.mode != 'sideAngle'
                ? controls.fov * .64
                : controls.fov,
          );
          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: ClipRect(
                    child: AnastasisDomeView(
                      key: _viewKey,
                      texture: texture,
                      params: const ConchParams(),
                      layers: _legacy ? _assets.relief.layers : const [],
                      reliefControls: framedControls,
                      sourceWindow: _windows[_focus],
                      settleOnRelease: _legacy,
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final focus in _windows.keys)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: ChoiceChip(
                                  label: Text(focus),
                                  selected: _focus == focus,
                                  onSelected: (_) => setState(() {
                                    _focus = focus;
                                    _viewKey.currentState?.resetView();
                                  }),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<bool>(
                          style: ButtonStyle(
                            foregroundColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.selected)
                                  ? ink
                                  : const Color(0xFFE8DFD1),
                            ),
                            backgroundColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.selected)
                                  ? const Color(0xFFE9D19A)
                                  : const Color(0xFF33302B),
                            ),
                          ),
                          segments: const [
                            ButtonSegment(value: true, label: Text('Original')),
                            ButtonSegment(value: false, label: Text('Relief')),
                          ],
                          selected: {_original},
                          onSelectionChanged: (selection) =>
                              _setOriginal(selection.first),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openDebug() {
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, localSet) {
          void update(ReliefControls value, {bool keepPreset = false}) {
            setState(
              () => _controls = keepPreset
                  ? value
                  : value.copyWith(preset: 'CUSTOM'),
            );
            localSet(() {});
          }

          Widget slider(
            String label,
            double value,
            double min,
            double max,
            ReliefControls Function(double) change,
          ) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$label  ${value.toStringAsFixed(2)}'),
              Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: (v) => update(change(v)),
              ),
            ],
          );
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .8,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  const Text(
                    'RELIEF INSPECTION',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Device DPR ${MediaQuery.devicePixelRatioOf(context).toStringAsFixed(1)} · Flutter-managed raster scale',
                  ),
                  SwitchListTile(
                    title: const Text('Archived v3 layered renderer'),
                    subtitle: const Text(
                      'Off: fifth-pass static relief, camera fixed',
                    ),
                    value: _legacy,
                    onChanged: (v) async {
                      await _setLegacy(v);
                      localSet(() {});
                    },
                  ),
                  if (!_legacy)
                    Wrap(
                      spacing: 5,
                      children: [
                        for (final view in _v5.views)
                          ChoiceChip(
                            label: Text(view.label),
                            selected: _v5View == view.id,
                            onSelected: (_) async {
                              await view.ensureLoaded();
                              if (!mounted) return;
                              setState(() => _v5View = view.id);
                              localSet(() {});
                            },
                          ),
                      ],
                    ),
                  if (_legacy) ..._legacyControls(slider, update),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _legacyControls(
    Widget Function(
      String label,
      double value,
      double min,
      double max,
      ReliefControls Function(double) change,
    )
    slider,
    void Function(ReliefControls value, {bool keepPreset}) update,
  ) => [
    Wrap(
      spacing: 6,
      children: [
        for (final preset in [
          'FLAT_ORIGINAL',
          'SUBTLE_RELIEF',
          'BALANCED',
          'STRONG_DEPTH',
          'DEBUG_EXAGGERATED',
        ])
          ActionChip(
            label: Text(preset),
            onPressed: () =>
                update(ReliefControls.fromPreset(preset), keepPreset: true),
          ),
      ],
    ),
    Wrap(
      spacing: 5,
      children: [
        for (final mode in [
          'relief',
          'original',
          'masks',
          'colors',
          'semanticDepth',
          'localDepth',
          'combinedDepth',
          'normals',
          'wireframe',
          'aoOnly',
          'shadowOnly',
          'edges',
          'sideAngle',
        ])
          ChoiceChip(
            label: Text(mode),
            selected: _controls.mode == mode,
            onSelected: (_) => update(_controls.copyWith(mode: mode)),
          ),
      ],
    ),
    slider(
      'Global depth',
      _controls.depthScale,
      0,
      .8,
      (v) => _controls.copyWith(depthScale: v),
    ),
    slider(
      'Global local relief',
      _controls.reliefScale,
      0,
      2.5,
      (v) => _controls.copyWith(reliefScale: v),
    ),
    slider(
      'Parallax',
      _controls.parallax,
      0,
      1.5,
      (v) => _controls.copyWith(parallax: v),
    ),
    slider(
      'Horizontal range (radians)',
      _controls.maxYaw,
      .025,
      .17,
      (v) => _controls.copyWith(maxYaw: v),
    ),
    slider(
      'Vertical range (radians)',
      _controls.maxPitch,
      .02,
      .12,
      (v) => _controls.copyWith(maxPitch: v),
    ),
    slider(
      'Light angle',
      _controls.lightAngle,
      -90,
      90,
      (v) => _controls.copyWith(lightAngle: v),
    ),
    slider(
      'Light intensity',
      _controls.lightIntensity,
      0,
      2,
      (v) => _controls.copyWith(lightIntensity: v),
    ),
    slider(
      'Ambient',
      _controls.ambientIntensity,
      .5,
      1.2,
      (v) => _controls.copyWith(ambientIntensity: v),
    ),
    slider(
      'AO',
      _controls.aoIntensity,
      0,
      2,
      (v) => _controls.copyWith(aoIntensity: v),
    ),
    slider(
      'Contact shadow',
      _controls.contactShadow,
      0,
      1,
      (v) => _controls.copyWith(contactShadow: v),
    ),
    slider(
      'Edge thickness',
      _controls.bevel,
      0,
      2,
      (v) => _controls.copyWith(bevel: v),
    ),
    SwitchListTile(
      title: const Text('Inspect raking light with drag'),
      value: _controls.lightInspection,
      onChanged: (v) => update(_controls.copyWith(lightInspection: v)),
    ),
    slider(
      'Mesh quality',
      _controls.meshQuality,
      .5,
      2,
      (v) => _controls.copyWith(meshQuality: v),
    ),
    slider('FOV', _controls.fov, .75, 1.5, (v) => _controls.copyWith(fov: v)),
    slider(
      'Texture filtering',
      _controls.textureQuality,
      .5,
      1.5,
      (v) => _controls.copyWith(textureQuality: v),
    ),
    slider(
      'Christ saturation',
      _controls.christSaturation,
      .8,
      1.2,
      (v) => _controls.copyWith(christSaturation: v),
    ),
    slider(
      'Christ contrast',
      _controls.christContrast,
      .8,
      1.2,
      (v) => _controls.copyWith(christContrast: v),
    ),
    slider(
      'Edge softness',
      _controls.feather,
      0,
      4,
      (v) => _controls.copyWith(feather: v),
    ),
    DropdownButton<String>(
      value: _controls.solo,
      items: [
        const DropdownMenuItem(value: '', child: Text('All layers')),
        for (final layer in _assets.relief.layers)
          DropdownMenuItem(value: layer.id, child: Text('Solo ${layer.id}')),
      ],
      onChanged: (v) => update(_controls.copyWith(solo: v)),
    ),
    for (final layer in _assets.relief.layers)
      ExpansionTile(
        title: Text(layer.id),
        children: [
          SwitchListTile(
            title: const Text('Visible'),
            value: _controls.visibility[layer.id] ?? true,
            onChanged: (v) => update(
              _controls.copyWith(
                visibility: {..._controls.visibility, layer.id: v},
              ),
            ),
          ),
          slider(
            'Semantic depth',
            _controls.depths[layer.id] ?? layer.depth,
            0,
            .8,
            (v) =>
                _controls.copyWith(depths: {..._controls.depths, layer.id: v}),
          ),
          slider(
            'Local relief',
            _controls.reliefs[layer.id] ?? layer.relief,
            0,
            .4,
            (v) => _controls.copyWith(
              reliefs: {..._controls.reliefs, layer.id: v},
            ),
          ),
          slider(
            'Opacity',
            _controls.opacities[layer.id] ?? 1,
            0,
            1,
            (v) => _controls.copyWith(
              opacities: {..._controls.opacities, layer.id: v},
            ),
          ),
        ],
      ),
  ];
}
