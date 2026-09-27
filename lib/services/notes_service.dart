import 'package:shared_preferences/shared_preferences.dart';

class NotesService {
  static const String _prefix = 'scene_note_';
  static const String _schemaKey = 'scene_notes_schema_version';
  static const int schemaVersion = 1;

  Future<SharedPreferences> _preferences() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getInt(_schemaKey) ?? 0;
    if (version > schemaVersion) {
      throw StateError('Unsupported notes schema $version');
    }
    // v0 → v1: artwork IDs retain M03/F02/F05, so the safest migration is to
    // preserve every key and byte of text in place. P19 imports these into SQLite.
    if (version == 0) {
      if (!await prefs.setInt(_schemaKey, schemaVersion)) {
        throw StateError('Could not record notes schema');
      }
    }
    return prefs;
  }

  Future<String> noteFor(String sceneId) async {
    final prefs = await _preferences();
    return prefs.getString('$_prefix$sceneId') ?? '';
  }

  Future<void> saveNote(String sceneId, String text) async {
    final prefs = await _preferences();
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      await prefs.remove('$_prefix$sceneId');
    } else {
      await prefs.setString('$_prefix$sceneId', trimmed);
    }
  }

  Future<Set<String>> notedSceneIds() async {
    final prefs = await _preferences();
    return {
      for (final key in prefs.getKeys())
        if (key.startsWith(_prefix) &&
            (prefs.getString(key) ?? '').trim().isNotEmpty)
          key.substring(_prefix.length),
    };
  }
}
