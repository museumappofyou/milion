import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'design/design_sheet.dart';
import 'design/settings.dart';
import 'design/theme.dart';
import 'l10n/strings.dart';
import 'screens/home_screen.dart';

void registerFontLicences() {
  LicenseRegistry.addLicense(() async* {
    for (final family in ['Cinzel', 'NotoSans', 'NotoSerifDisplay']) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString('assets/fonts/OFL-$family.txt'));
    }
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicences();
  runApp(const MilionApp());
}

class MilionApp extends StatefulWidget {
  const MilionApp({super.key});
  @override
  State<MilionApp> createState() => _MilionAppState();
}

class _MilionAppState extends State<MilionApp> {
  final _settings = AppSettings();
  @override
  void initState() {
    super.initState();
    _settings.load();
  }

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SettingsScope(
    settings: _settings,
    child: ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (context) => context.l10n.appTitle,
        debugShowCheckedModeBanner: false,
        theme: DesignTheme.marble,
        darkTheme: DesignTheme.lamp,
        themeMode: _settings.themeMode,
        locale: _settings.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: kDebugMode ? {'/design': (_) => const DesignSheet()} : const {},
        home: const HomeScreen(),
      ),
    ),
  );
}
