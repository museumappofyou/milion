import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/scene.dart';
import '../services/notes_service.dart';
import '../theme/milion_theme.dart';
import '../widgets/scene_detail_sheet.dart';

class ScenesTab extends StatefulWidget {
  const ScenesTab({
    super.key,
    required this.scenes,
    this.onExamineAnastasis,
    this.onExamineLastJudgment,
  });
  final List<Scene> scenes;
  final VoidCallback? onExamineAnastasis, onExamineLastJudgment;
  @override
  State<ScenesTab> createState() => _ScenesTabState();
}

class _ScenesTabState extends State<ScenesTab> {
  final NotesService _notes = NotesService();
  final _search = TextEditingController();
  Set<String> _notedIds = const {};
  String _query = '';
  String? _room;
  bool _interactiveOnly = false;

  @override
  void initState() {
    super.initState();
    _reloadNotes();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reloadNotes() async {
    final noted = await _notes.notedSceneIds();
    if (mounted) setState(() => _notedIds = noted);
  }

  bool _interactive(Scene scene) => scene.id == 'F02' || scene.id == 'F05';

  void _clear() => setState(() {
    _search.clear();
    _query = '';
    _room = null;
    _interactiveOnly = false;
  });

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = widget.scenes
        .where(
          (scene) =>
              (_room == null || scene.room == _room) &&
              (!_interactiveOnly || _interactive(scene)) &&
              (query.isEmpty ||
                  scene.id.toLowerCase().contains(query) ||
                  scene.prettyTitle.toLowerCase().contains(query) ||
                  scene.room.toLowerCase().contains(query) ||
                  scene.surface.toLowerCase().contains(query) ||
                  scene.cues.any((cue) => cue.toLowerCase().contains(query))),
        )
        .toList();
    final grouped = <String, List<Scene>>{};
    for (final scene in filtered) {
      grouped.putIfAbsent(scene.room, () => []).add(scene);
    }
    final rooms = grouped.keys.toList()..sort();
    final allRooms = widget.scenes.map((s) => s.room).toSet().toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('The collection')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                child: Text(
                  '${widget.scenes.length} scenes. Every wall has a story.',
                  style: const TextStyle(
                    color: MilionTheme.muted,
                    fontSize: 14,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: TextField(
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search scenes, places or details',
                    prefixIcon: const Icon(Icons.search, size: 22),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () => setState(() {
                              _search.clear();
                              _query = '';
                            }),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All rooms'),
                      selected: _room == null,
                      onSelected: (_) => setState(() => _room = null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Interactive'),
                      avatar: const Icon(Icons.layers_outlined, size: 16),
                      selected: _interactiveOnly,
                      onSelected: (v) => setState(() => _interactiveOnly = v),
                    ),
                    const SizedBox(width: 8),
                    for (final room in allRooms)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(room),
                          selected: _room == room,
                          onSelected: (_) => setState(() => _room = room),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: rooms.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.search_off_outlined,
                                size: 36,
                                color: MilionTheme.gold,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No scenes found',
                                style: MilionTheme.display(32),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Try another detail or a different room.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: _clear,
                                child: const Text('Clear filters'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                        children: [
                          for (final room in rooms) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 22, 0, 12),
                              child: Row(
                                children: [
                                  Text(
                                    room.toUpperCase(),
                                    style: MilionTheme.eyebrow,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(child: Divider()),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${grouped[room]!.length}',
                                    style: const TextStyle(
                                      color: MilionTheme.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            for (final scene in grouped[room]!)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Card(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    leading: _interactive(scene)
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.asset(
                                              scene.id == 'F02'
                                                  ? 'assets/anastasis/conch_reference.jpg'
                                                  : 'assets/last_judgment/vault_reference.jpg',
                                              width: 58,
                                              height: 58,
                                              fit: BoxFit.cover,
                                              cacheWidth: 180,
                                            ),
                                          )
                                        : Container(
                                            width: 48,
                                            height: 48,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: MilionTheme.parchment,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              scene.id,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: MilionTheme.gold,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                    title: Text(
                                      scene.prettyTitle,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _interactive(scene)
                                          ? '${scene.id} · ${scene.surface} · Interactive'
                                          : scene.surface,
                                      style: const TextStyle(
                                        color: MilionTheme.muted,
                                        fontSize: 11,
                                        height: 1.7,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_notedIds.contains(scene.id))
                                          const Padding(
                                            padding: EdgeInsets.only(right: 5),
                                            child: Tooltip(
                                              message: 'Has a note',
                                              child: Icon(
                                                Icons.sticky_note_2_outlined,
                                                size: 17,
                                                color: MilionTheme.gold,
                                              ),
                                            ),
                                          ),
                                        const Icon(
                                          Icons.arrow_forward,
                                          size: 17,
                                          color: MilionTheme.gold,
                                        ),
                                      ],
                                    ),
                                    onTap: () => _showScene(scene),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showScene(Scene scene) async {
    final detail = SceneDetailSheet(
      scene: scene,
      onExamine: switch (scene.id) {
        'F02' => widget.onExamineAnastasis,
        'F05' => widget.onExamineLastJudgment,
        _ => null,
      },
    );
    if (kIsWeb) {
      // A labelled dialog gives desktop keyboard and screen-reader users a
      // clear route name; native devices retain their familiar bottom sheet.
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          semanticLabel: scene.prettyTitle,
          backgroundColor: MilionTheme.paper,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 640),
          titlePadding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              const Expanded(
                child: Text('SCENE DETAILS', style: MilionTheme.eyebrow),
              ),
              IconButton(
                tooltip: 'Close scene details',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            height: MediaQuery.sizeOf(context).height * .68,
            child: detail,
          ),
        ),
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: MilionTheme.paper,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => detail,
      );
    }
    await _reloadNotes();
  }
}
