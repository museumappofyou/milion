import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  Locale? locale;
  ThemeMode themeMode = ThemeMode.light;
  bool _changed = false;
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    if (_changed || _disposed) return;
    final code = p.getString('milion_language');
    locale = ['en', 'tr'].contains(code) ? Locale(code!) : null;
    themeMode = p.getString('milion_scheme') == 'lamp'
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setLanguage(String? code) async {
    _changed = true;
    locale = code == null ? null : Locale(code);
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    if (code == null) {
      await p.remove('milion_language');
    } else {
      await p.setString('milion_language', code);
    }
  }

  Future<void> setScheme(ThemeMode value) async {
    _changed = true;
    themeMode = value;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString(
      'milion_scheme',
      value == ThemeMode.dark ? 'lamp' : 'marble',
    );
  }
}

class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);
  static AppSettings? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()?.notifier;
}
