import 'package:shared_preferences/shared_preferences.dart';

class NotesService {
  static const String _prefix = 'scene_note_';

  Future<String> noteFor(String sceneId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefix$sceneId') ?? '';
  }

  Future<void> saveNote(String sceneId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      await prefs.remove('$_prefix$sceneId');
    } else {
      await prefs.setString('$_prefix$sceneId', trimmed);
    }
  }

  Future<Set<String>> notedSceneIds() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final key in prefs.getKeys())
        if (key.startsWith(_prefix) &&
            (prefs.getString(key) ?? '').trim().isNotEmpty)
          key.substring(_prefix.length),
    };
  }
}
