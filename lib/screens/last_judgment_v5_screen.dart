import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// The same fixed-camera, baked-light presentation as Anastasis v5.
/// All views derive from one authored surface; the photograph is never layered.
class LastJudgmentV5Screen extends StatefulWidget {
  const LastJudgmentV5Screen({super.key, this.initialFocus = 'Overview'});

  final String initialFocus;

  @override
  State<LastJudgmentV5Screen> createState() => _LastJudgmentV5ScreenState();
}

class _LastJudgmentV5ScreenState extends State<LastJudgmentV5Screen> {
  static const _ink = Color(0xFF1B1918);
  static const _paper = Color(0xFFF4EBDC);
  late final Future<Map<String, dynamic>> _loading = _load();
  late String _focus = widget.initialFocus;
  String _view = 'relief';
  bool _original = false;

  Future<Map<String, dynamic>> _load() async => jsonDecode(
    await rootBundle.loadString('assets/last_judgment/relief_v5/manifest.json'),
  ) as Map<String, dynamic>;

  void _reset() => setState(() {
    _focus = 'Overview';
    _view = 'relief';
    _original = false;
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _ink,
    appBar: AppBar(
      backgroundColor: _ink,
      foregroundColor: _paper,
      toolbarHeight: 65,
      titleSpacing: 0,
      title: GestureDetector(
        onLongPress: _inspect,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LAST JUDGMENT',
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
          onPressed: _reset,
          icon: const Icon(Icons.center_focus_strong_outlined),
        ),
      ],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Relief assets unavailable.',
              style: TextStyle(color: _paper),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final manifest = snapshot.data!;
        final views = (manifest['views'] as List).cast<Map<String, dynamic>>();
        final focuses = (manifest['focus'] as List)
            .cast<Map<String, dynamic>>();
        final view = views.firstWhere((v) => v['id'] == _view);
        final focus = focuses.firstWhere(
          (f) => f['label'] == _focus,
          orElse: () => focuses.first,
        );
        final size = (manifest['size'] as List).cast<num>();
        final rect = (focus['rect'] as List?)?.cast<num>();
        final isSide = !_original && _view == 'side';
        final file = (_original ? manifest['master'] : view['file']) as String;
        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: isSide
                      ? Image.asset(
                          file,
                          fit: BoxFit.contain,
                          errorBuilder: _imageError,
                        )
                      : FixedReliefFrame(
                          file: file,
                          sourceSize: Size(
                            size[0].toDouble(),
                            size[1].toDouble(),
                          ),
                          window: rect == null
                              ? null
                              : Rect.fromLTRB(
                                  rect[0].toDouble(),
                                  rect[1].toDouble(),
                                  rect[2].toDouble(),
                                  rect[3].toDouble(),
                                ),
                        ),
                ),
              ),
            ),
            if (_view != 'relief' && !_original)
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  '${view['label']} · inspection',
                  style: const TextStyle(
                    color: Color(0xFFBDB1A3),
                    fontSize: 11,
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
                          for (final item in focuses)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: ChoiceChip(
                                label: Text(item['label'] as String),
                                selected: _focus == item['label'],
                                onSelected: (_) => setState(() {
                                  _focus = item['label'] as String;
                                  if (_view == 'side') _view = 'relief';
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
                                ? _ink
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
                        onSelectionChanged: (value) =>
                            setState(() => _original = value.first),
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

  Future<void> _inspect() async {
    final manifest = await _loading;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RELIEF INSPECTION',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final view in manifest['views'] as List)
                    ActionChip(
                      label: Text(view['label'] as String),
                      onPressed: () {
                        setState(() {
                          _view = view['id'] as String;
                          _original = false;
                        });
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'One continuous surface · fixed camera and light.\n'
                '45° view shows the surface with 1.5× depth.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _imageError(BuildContext context, Object error, StackTrace? stack) =>
    const Center(
      child: Text(
        'Image unavailable',
        style: TextStyle(color: Color(0xFFF4EBDC)),
      ),
    );

/// Crops in source-pixel coordinates, identically for original and relief.
/// Deliberately has no gesture or animation: the v5 camera stays fixed.
class FixedReliefFrame extends StatelessWidget {
  const FixedReliefFrame({
    super.key,
    required this.file,
    required this.sourceSize,
    this.window,
  });

  final String file;
  final Size sourceSize;
  final Rect? window;

  @override
  Widget build(BuildContext context) {
    final crop = window ?? Offset.zero & sourceSize;
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: crop.width,
        height: crop.height,
        child: ClipRect(
          child: Stack(
            children: [
              Positioned(
                left: -crop.left,
                top: -crop.top,
                width: sourceSize.width,
                height: sourceSize.height,
                child: Image.asset(
                  file,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  errorBuilder: _imageError,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
