import 'package:flutter/material.dart';

import '../models/scene.dart';
import '../services/notes_service.dart';
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
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
  final _notes = NotesService(), _search = TextEditingController();
  Set<String> _notedIds = {};
  String _query = '';
  String? _room;
  bool _interactiveOnly = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final ids = await _notes.notedSceneIds();
    if (mounted) setState(() => _notedIds = ids);
  }

  bool _interactive(Scene s) => s.id == 'F02' || s.id == 'F05';
  void _clear() => setState(() {
    _query = '';
    _search.clear();
    _room = null;
    _interactiveOnly = false;
  });
  Future<void> _open(Scene scene) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SceneDetailSheet(
        scene: scene,
        onExamine: switch (scene.id) {
          'F02' => widget.onExamineAnastasis,
          'F05' => widget.onExamineLastJudgment,
          _ => null,
        },
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n,
        c = MeasureColors.of(context),
        q = _query.toLowerCase().trim();
    final scenes = widget.scenes
        .where(
          (a) =>
              (_room == null || _room == a.room) &&
              (!_interactiveOnly || _interactive(a)) &&
              (q.isEmpty ||
                  '${a.id} ${a.prettyTitle} ${a.room} ${a.surface} ${a.cues.join(' ')}'
                      .toLowerCase()
                      .contains(q)),
        )
        .toList();
    final rooms = widget.scenes.map((s) => s.room).toSet().toList()..sort();
    return Scaffold(
      appBar: AppBar(title: Text(s.collection)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              s.catalogueCount('${widget.scenes.length}'),
              style: TextStyle(color: c.secondary),
            ),
          ),
          if (context.language == 'tr')
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text(
                s.contentEnglish,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: s.searchScenes,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: s.clearSearch,
                        onPressed: () => setState(() {
                          _search.clear();
                          _query = '';
                        }),
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: DropdownButtonFormField<String>(
              key: ValueKey(_room),
              initialValue: _room ?? '',
              isExpanded: true,
              decoration: InputDecoration(labelText: s.room),
              items: [
                DropdownMenuItem(value: '', child: Text(s.allRooms)),
                for (final r in rooms)
                  DropdownMenuItem(
                    value: r,
                    child: Text(r, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _room = v == '' ? null : v),
            ),
          ),
          CheckboxListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            title: Text(s.interactive),
            secondary: const PlanIcon(PlanSymbol.layers),
            value: _interactiveOnly,
            onChanged: (v) => setState(() => _interactiveOnly = v ?? false),
          ),
          const Divider(),
          Expanded(
            child: scenes.isEmpty
                ? SingleChildScrollView(
                    child: ContentState(
                      title: s.noScenes,
                      message: s.noScenesBody,
                      onAction: _clear,
                      actionLabel: s.clearFilters,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: scenes.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, i) {
                      final a = scenes[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        leading: SizedBox(
                          width: 48,
                          child: Text(
                            a.id,
                            style: TypeRole.measurement.copyWith(
                              color: c.accent,
                            ),
                          ),
                        ),
                        title: Text(a.prettyTitle),
                        subtitle: Text('${a.room} · ${a.surface}'),
                        trailing: _notedIds.contains(a.id)
                            ? Tooltip(
                                message: s.hasNote,
                                child: const PlanIcon(
                                  PlanSymbol.story,
                                  size: 20,
                                ),
                              )
                            : null,
                        onTap: () => _open(a),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
