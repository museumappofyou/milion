import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/milion_theme.dart';

import '../models/anastasis_capture.dart';
import '../models/scene.dart';
import '../services/anastasis_assets.dart';
import '../services/anastasis_relief.dart';
import '../services/conch_geometry.dart';
import '../widgets/anastasis_dome_view.dart';
import '../widgets/capture_viewer_sheet.dart';
import 'anastasis_relief_screen.dart';

/// The Anastasis as an examinable 2.5D artifact: the painted panel wrapped
/// back onto the semi-dome of the Parekklesion apse, with its reference
/// captures, hotspots and provenance.
class AnastasisTab extends StatefulWidget {
  const AnastasisTab({super.key, this.scene});

  /// The catalog entry for F02, when the classifier has one, so the tab can
  /// show the same summary as the rest of the app.
  final Scene? scene;

  @override
  State<AnastasisTab> createState() => _AnastasisTabState();
}

class _AnastasisTabState extends State<AnastasisTab> {
  final AnastasisAssets _assets = AnastasisAssets();
  final GlobalKey<AnastasisDomeViewState> _viewKey =
      GlobalKey<AnastasisDomeViewState>();
  late final Future<void> _loading;

  ConchParams _params = const ConchParams();
  bool _showGuides = false;
  bool _sway = false;
  bool _legacyDebug = false;
  bool _legacyLoaded = false;
  ReliefControls _reliefControls = const ReliefControls();
  String _viewReadout = 'default capture view';
  String _modelLine = '';

  @override
  void initState() {
    super.initState();
    _loading = _assets.load(includeRelief: false);
    _modelLine = _describeModel(_params);
  }

  void _setParams(ConchParams params) {
    setState(() {
      _params = params;
      _modelLine = _describeModel(params);
    });
  }

  /// Short, honest summary of the solved geometry, shown under the section
  /// diagram. Built once per parameter change rather than per frame.
  String _describeModel(ConchParams params) {
    final surface = ConchSurface(
      params: params,
      textureSize: const Size(2048, 1091),
    );
    return 'Model: panel spans ±${params.thetaPanelDeg.toStringAsFixed(0)}° '
        'of azimuth and ${params.alphaBottomDeg.toStringAsFixed(0)}°–'
        '${params.alphaTopDeg.toStringAsFixed(0)}° of elevation. '
        'Default viewpoint '
        '${surface.captureHalfFovDeg.toStringAsFixed(0)}° half-FOV, '
        '${(params.cameraY * 100).toStringAsFixed(0)}% of the radius below '
        'the springing.';
  }

  @override
  void dispose() {
    _assets.dispose();
    super.dispose();
  }

  void _updateReadout() {
    final state = _viewKey.currentState;
    if (state == null) {
      return;
    }
    final (yaw, pitch) = state.viewAnglesDeg;
    setState(() {
      if (yaw.abs() < 0.5 && pitch.abs() < 0.5) {
        _viewReadout = 'default capture view';
      } else {
        _viewReadout =
            'viewpoint moved ${yaw.toStringAsFixed(0)}° across, '
            '${pitch.toStringAsFixed(0)}° up';
      }
    });
  }

  Future<void> _toggleLegacyDebug() async {
    if (!mounted) return;
    setState(() => _legacyDebug = !_legacyDebug);
    if (_legacyDebug && !_legacyLoaded) {
      await _assets.relief.load();
      _legacyLoaded = true;
      if (mounted) setState(() {});
    }
  }

  Future<void> _openCapture(AnastasisCapture capture) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121214),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CaptureViewerSheet(capture: capture),
    );
  }

  Future<void> _openHotspot(AnastasisHotspot hotspot) async {
    final artifact = _assets.artifact;
    final capture = artifact?.captureById(hotspot.captureId);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotspot.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  hotspot.detail,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (capture != null) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(capture.file),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${capture.title} · ${capture.credit}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openCapture(capture);
                    },
                    icon: const Icon(Icons.zoom_in, size: 18),
                    label: const Text('Open capture'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: _toggleLegacyDebug,
          child: const Text('Anastasis'),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(22),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'F02 · Parekklesion · semi-dome (conch)',
                style: TextStyle(fontSize: 12, color: MilionTheme.muted),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<void>(
        future: _loading,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !_assets.isReady) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.image_not_supported_outlined, size: 40),
                  const SizedBox(height: 12),
                  const Text('The Anastasis artifact assets are missing.'),
                  const SizedBox(height: 8),
                  Text(
                    'Run dart run tool/prepare_anastasis_assets.dart, then '
                    'python3.11 tool/build_anastasis_relief.py, and rebuild. '
                    'Details: ${snapshot.error ?? 'not loaded'}',
                  ),
                ],
              ),
            );
          }
          final artifact = _assets.artifact!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _header(context, artifact),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AnastasisReliefScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.view_in_ar_outlined),
                  label: const Text('Explore painted relief'),
                ),
              ),
              if (_legacyDebug) ...[
                const SizedBox(height: 12),
                _viewerCard(context, _assets.texture!),
                const SizedBox(height: 12),
                _reliefCard(context),
                const SizedBox(height: 12),
                _curvatureCard(context),
              ],
              const SizedBox(height: 12),
              _hotspotsCard(context),
              const SizedBox(height: 12),
              _capturesCard(context, artifact),
              const SizedBox(height: 12),
              _provenanceCard(context, artifact),
            ],
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, AnastasisArtifact artifact) {
    final scene = widget.scene;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.art_track, size: 16, color: Color(0xFFC9A227)),
            const SizedBox(width: 6),
            Text(
              'EXAMINABLE ARTIFACT',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: const Color(0xFF8A6D1B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'The Anastasis on its semi-dome',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          scene?.summary.isNotEmpty == true
              ? scene!.summary
              : 'Radiant Christ breaks the gates of death, binds Satan, and '
                    'pulls Adam and Eve from their tombs.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final cue in scene?.cues ?? const ['broken gates', 'mandorla'])
              _chip(cue),
          ],
        ),
      ],
    );
  }

  Widget _viewerCard(BuildContext context, dynamic texture) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.62,
            child: AnastasisDomeView(
              key: _viewKey,
              texture: texture,
              params: _params,
              layers: _assets.relief.layers,
              reliefControls: _reliefControls,
              hotspots: _hotspotList,
              showGuides: _showGuides,
              sway: _sway,
              onHotspotTap: _openHotspot,
              onViewChanged: _updateReadout,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Drag to move the viewpoint · double-tap to reset · '
                    'tap a marker. $_viewReadout.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.black54,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _sway ? 'Stop the automatic drift' : 'Drift slowly',
                  onPressed: () => setState(() => _sway = !_sway),
                  icon: Icon(
                    _sway
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                  ),
                ),
                IconButton(
                  tooltip: 'Reset the viewpoint',
                  onPressed: () {
                    _viewKey.currentState?.resetView();
                    _updateReadout();
                  },
                  icon: const Icon(Icons.restart_alt),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Conch curvature',
                      style: TextStyle(fontSize: 12.5),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _params.radius >= 0.995 && _params.radius <= 1.005
                            ? 'reference semi-dome'
                            : _params.radius < 1
                            ? 'tighter apse'
                            : 'flatter apse',
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _params.radius,
                  min: 0.45,
                  max: 2.0,
                  onChanged: (value) =>
                      _setParams(_params.copyWith(radius: value)),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'radius ${(_params.radius * 100).round()}% of '
                        'reference',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Surface guides'),
                      selected: _showGuides,
                      visualDensity: VisualDensity.compact,
                      onSelected: (value) =>
                          setState(() => _showGuides = value),
                    ),
                  ],
                ),
                Text(
                  'Everything scales together with the radius, so the framing '
                  'stays and only the depth of the bowl changes.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _curvatureCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading the curvature',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: CustomPaint(painter: _SectionPainter(params: _params)),
            ),
            const SizedBox(height: 10),
            const Text(
              'The Anastasis is painted on the inside of the apse semi-dome — '
              'a curved surface rising from the springing line. The default '
              'relief preserves the source photograph at center and separates '
              'painted groups by shallow depth. The optional conch projection '
              'maps the panel onto an estimated apse surface; its dimensions '
              'are not measured.',
              style: TextStyle(fontSize: 12, height: 1.45),
            ),
            const SizedBox(height: 8),
            if (_modelLine.isNotEmpty)
              Text(
                _modelLine,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
          ],
        ),
      ),
    );
  }

  Widget _reliefCard(BuildContext context) {
    final layers = _assets.relief.layers;
    return Card(
      child: ExpansionTile(
        title: const Text('Relief controls'),
        subtitle: Text('${_reliefControls.preset} · ${_reliefControls.mode}'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final preset in [
                      'FLAT_ORIGINAL',
                      'SUBTLE_RELIEF',
                      'BALANCED',
                      'STRONG_DEPTH',
                      'DEBUG_EXAGGERATED',
                    ])
                      ChoiceChip(
                        label: Text(preset.replaceAll('_', ' ')),
                        selected: _reliefControls.preset == preset,
                        onSelected: (_) => setState(
                          () => _reliefControls = ReliefControls.fromPreset(
                            preset,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final mode in [
                      'original',
                      'colors',
                      'depth',
                      'masks',
                      'wireframe',
                      'edges',
                    ])
                      ChoiceChip(
                        label: Text(mode),
                        selected: _reliefControls.mode == mode,
                        onSelected: (_) => setState(
                          () => _reliefControls = _reliefControls.copyWith(
                            mode: mode,
                          ),
                        ),
                      ),
                  ],
                ),
                _reliefSlider(
                  'Global depth scale',
                  _reliefControls.depthScale,
                  0,
                  .8,
                  (v) =>
                      _reliefControls.copyWith(depthScale: v, preset: 'CUSTOM'),
                ),
                _reliefSlider(
                  'Global relief',
                  _reliefControls.reliefScale,
                  0,
                  3,
                  (v) => _reliefControls.copyWith(
                    reliefScale: v,
                    preset: 'CUSTOM',
                  ),
                ),
                _reliefSlider(
                  'Parallax strength',
                  _reliefControls.parallax,
                  0,
                  1.7,
                  (v) =>
                      _reliefControls.copyWith(parallax: v, preset: 'CUSTOM'),
                ),
                _reliefSlider(
                  'Maximum horizontal angle',
                  _reliefControls.maxYaw * 180 / math.pi,
                  2,
                  12,
                  (v) => _reliefControls.copyWith(
                    maxYaw: v * math.pi / 180,
                    preset: 'CUSTOM',
                  ),
                ),
                _reliefSlider(
                  'Maximum vertical angle',
                  _reliefControls.maxPitch * 180 / math.pi,
                  2,
                  8,
                  (v) => _reliefControls.copyWith(
                    maxPitch: v * math.pi / 180,
                    preset: 'CUSTOM',
                  ),
                ),
                _reliefSlider(
                  'Lighting response',
                  _reliefControls.light,
                  0,
                  1.5,
                  (v) => _reliefControls.copyWith(light: v, preset: 'CUSTOM'),
                ),
                _reliefSlider(
                  'Saturation',
                  _reliefControls.saturation,
                  .7,
                  1.3,
                  (v) =>
                      _reliefControls.copyWith(saturation: v, preset: 'CUSTOM'),
                ),
                _reliefSlider(
                  'Contrast',
                  _reliefControls.contrast,
                  .7,
                  1.3,
                  (v) =>
                      _reliefControls.copyWith(contrast: v, preset: 'CUSTOM'),
                ),
                _reliefSlider(
                  'Brightness',
                  _reliefControls.brightness,
                  -.2,
                  .2,
                  (v) =>
                      _reliefControls.copyWith(brightness: v, preset: 'CUSTOM'),
                ),
                _reliefSlider(
                  'Edge softening',
                  _reliefControls.feather,
                  0,
                  3,
                  (v) => _reliefControls.copyWith(feather: v, preset: 'CUSTOM'),
                ),
                const Text(
                  'Christ focal layer',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                _reliefSlider(
                  'Christ contrast',
                  _reliefControls.christContrast,
                  .9,
                  1.15,
                  (v) => _reliefControls.copyWith(
                    christContrast: v,
                    preset: 'CUSTOM',
                  ),
                ),
                _reliefSlider(
                  'Christ saturation',
                  _reliefControls.christSaturation,
                  .9,
                  1.15,
                  (v) => _reliefControls.copyWith(
                    christSaturation: v,
                    preset: 'CUSTOM',
                  ),
                ),
                _reliefSlider(
                  'Christ brightness',
                  _reliefControls.christBrightness,
                  -.1,
                  .1,
                  (v) => _reliefControls.copyWith(
                    christBrightness: v,
                    preset: 'CUSTOM',
                  ),
                ),
                _reliefSlider(
                  'Christ edge separation',
                  _reliefControls.christEdgeSeparation,
                  0,
                  2,
                  (v) => _reliefControls.copyWith(
                    christEdgeSeparation: v,
                    preset: 'CUSTOM',
                  ),
                ),
                const Text('Solo layer'),
                DropdownButton<String>(
                  value: _reliefControls.solo,
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('All layers'),
                    ),
                    for (final layer in layers)
                      DropdownMenuItem(value: layer.id, child: Text(layer.id)),
                  ],
                  onChanged: (v) => setState(
                    () => _reliefControls = _reliefControls.copyWith(solo: v),
                  ),
                ),
                for (final layer in layers)
                  ExpansionTile(
                    title: Text(layer.id),
                    dense: true,
                    children: [
                      SwitchListTile(
                        dense: true,
                        title: const Text('Visible'),
                        value: _reliefControls.visibility[layer.id] ?? true,
                        onChanged: (v) => setState(
                          () => _reliefControls = _reliefControls.copyWith(
                            visibility: {
                              ..._reliefControls.visibility,
                              layer.id: v,
                            },
                          ),
                        ),
                      ),
                      _reliefSlider(
                        'Depth',
                        _reliefControls.depths[layer.id] ?? layer.depth,
                        0,
                        .7,
                        (v) => _reliefControls.copyWith(
                          depths: {..._reliefControls.depths, layer.id: v},
                          preset: 'CUSTOM',
                        ),
                      ),
                      _reliefSlider(
                        'Local relief',
                        _reliefControls.reliefs[layer.id] ?? layer.relief,
                        0,
                        .08,
                        (v) => _reliefControls.copyWith(
                          reliefs: {..._reliefControls.reliefs, layer.id: v},
                          preset: 'CUSTOM',
                        ),
                      ),
                      _reliefSlider(
                        'Opacity',
                        _reliefControls.opacities[layer.id] ?? 1,
                        0,
                        1,
                        (v) => _reliefControls.copyWith(
                          opacities: {
                            ..._reliefControls.opacities,
                            layer.id: v,
                          },
                          preset: 'CUSTOM',
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          SwitchListTile(
            dense: true,
            title: const Text('Architectural conch projection'),
            subtitle: const Text('Experimental curved mapping of the apse'),
            value: _reliefControls.projection == 'conch',
            onChanged: (v) => setState(
              () => _reliefControls = _reliefControls.copyWith(
                projection: v ? 'conch' : 'photo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reliefSlider(
    String label,
    double value,
    double min,
    double max,
    ReliefControls Function(double) update,
  ) => Row(
    children: [
      SizedBox(
        width: 125,
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
      Expanded(
        child: Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: (v) => setState(() => _reliefControls = update(v)),
        ),
      ),
      SizedBox(
        width: 37,
        child: Text(
          value.toStringAsFixed(2),
          style: const TextStyle(fontSize: 10),
        ),
      ),
    ],
  );

  Widget _hotspotsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anchor points',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            const Text(
              'Anchored to positions on the reconstructed surface: they move '
              'with the bowl as the viewpoint changes.',
              style: TextStyle(fontSize: 11.5, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hotspot in _hotspotList)
                  ActionChip(
                    avatar: const Icon(Icons.place_outlined, size: 15),
                    label: Text(hotspot.label),
                    onPressed: () => _openHotspot(hotspot),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _capturesCard(BuildContext context, AnastasisArtifact artifact) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 0, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Source captures (${artifact.captures.length})',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'tap to examine',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 152,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 14),
                itemCount: artifact.captures.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final capture = artifact.captures[index];
                  return _CaptureTile(
                    capture: capture,
                    onTap: () => _openCapture(capture),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _provenanceCard(BuildContext context, AnastasisArtifact artifact) {
    final credits = <String>{for (final c in artifact.captures) c.credit};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Provenance and method',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _provenanceRow('Source folder', artifact.sourceFolder),
            _provenanceRow(
              'Prepared',
              '${artifact.preparedOn} · ${artifact.preparedBy}',
            ),
            _provenanceRow(
              'Captures',
              '${artifact.captures.length} prepared from the reference set',
            ),
            const SizedBox(height: 8),
            const Text(
              'This is a single-view shallow relief made from the original '
              'fresco photograph. Semantic masks and controlled depth separate '
              'Christ, Adam, Eve, groups, terrain and lower elements. The '
              'optional conch projection uses an estimated apse shape. The '
              'geometry is not a measured survey; hidden painted areas are '
              'not reconstructed.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            for (final note in artifact.notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Text(
                        note,
                        style: const TextStyle(fontSize: 11.5, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text('Credits', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            for (final credit in credits)
              Text(
                '· $credit',
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
          ],
        ),
      ),
    );
  }

  Widget _provenanceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11.5))),
        ],
      ),
    );
  }

  List<AnastasisHotspot> get _hotspotList {
    final artifact = _assets.artifact;
    if (artifact == null) {
      return anastasisHotspots;
    }
    // Keep only anchors whose detail capture exists.
    return [
      for (final hotspot in anastasisHotspots)
        if (artifact.captureById(hotspot.captureId) != null) hotspot,
    ];
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFECE5D8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11.5)),
    );
  }
}

class _CaptureTile extends StatelessWidget {
  const _CaptureTile({required this.capture, required this.onTap});

  final AnastasisCapture capture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const roleLabels = {
      'texture': 'viewer texture',
      'wide': 'wide',
      'flat-reference': 'flat reference',
      'detail': 'detail',
      'context': 'in situ',
      'historical': 'historical',
      'capture': 'capture',
      'guide': 'guide thumb',
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 168,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                capture.file,
                height: 88,
                width: 168,
                fit: BoxFit.cover,
                cacheWidth: 336,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              capture.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${roleLabels[capture.role] ?? capture.role} · '
              '${capture.width}×${capture.height}',
              style: const TextStyle(fontSize: 10, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cross-section of the conch: the meridian arc of the apse, the painted
/// panel on it, the springing line and the default viewpoint with its rays.
///
/// The depth axis is compressed so the section fits a card; heights are to
/// scale.
class _SectionPainter extends CustomPainter {
  _SectionPainter({required this.params});

  final ConchParams params;

  @override
  void paint(Canvas canvas, Size size) {
    // True-scale section: one unit of length is one pixel scale for both the
    // depth and the height axes, so the arc is a real quarter circle.
    final scale = math.min(
      size.width * 0.86 / (params.cameraZ + 1.45),
      size.height * 0.74,
    );
    final originX = size.width - 14 - params.cameraZ * scale;
    final originY = size.height - 16;
    Offset point(double depth, double height) =>
        Offset(originX - depth * scale, originY - height * scale);

    final arcRect = Rect.fromCircle(
      center: Offset(originX, originY),
      radius: scale,
    );
    canvas.drawArc(
      arcRect,
      3.14159,
      1.5708,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xAA8A6D1B),
    );
    canvas.drawArc(
      arcRect,
      3.14159 + params.alphaBottom,
      params.alphaTop - params.alphaBottom,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x55C9A227),
    );

    // Springing line and the mouth plane.
    canvas.drawLine(
      point(0, 0),
      point(1.05, 0),
      Paint()
        ..strokeWidth = 1
        ..color = const Color(0x44000000),
    );
    canvas.drawLine(
      point(0, -0.1),
      point(0, 1.05),
      Paint()
        ..strokeWidth = 1
        ..color = const Color(0x22000000),
    );

    // Panel edge points on the meridian and the rays from the viewpoint.
    final bottom = point(
      math.cos(params.alphaBottom),
      math.sin(params.alphaBottom),
    );
    final top = point(math.cos(params.alphaTop), math.sin(params.alphaTop));
    final viewer = point(-params.cameraZ, params.cameraY);
    final ray = Paint()
      ..strokeWidth = 1
      ..color = const Color(0x66999AA0);
    canvas.drawLine(viewer, bottom, ray);
    canvas.drawLine(viewer, top, ray);
    final marker = Paint()..color = const Color(0xFFC9A227);
    canvas.drawCircle(bottom, 2.6, marker);
    canvas.drawCircle(top, 2.6, marker);
    canvas.drawCircle(viewer, 4, Paint()..color = const Color(0xFF1F3B73));

    _text(canvas, 'crown', point(0, 1.0) + const Offset(-14, -14));
    _text(canvas, 'springing line', point(0.55, 0) + const Offset(-20, 4));
    _text(canvas, 'deepest point', point(1.0, 0) + const Offset(-24, 4));
    _text(canvas, 'painted panel', point(0.72, 0.62) + const Offset(-6, 0));
    _text(canvas, 'viewpoint', viewer + const Offset(-24, -16));
    _text(canvas, 'apse section', const Offset(8, 6));
  }

  void _text(Canvas canvas, String value, Offset position) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: const TextStyle(fontSize: 10, color: Colors.black54),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(_SectionPainter oldDelegate) => true;
}
