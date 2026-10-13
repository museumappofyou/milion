import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'content/bundled_content.dart';
import 'content/registry.dart';
import 'content/repository.dart';
import 'design/design_sheet.dart';
import 'design/motion.dart';
import 'design/settings.dart';
import 'design/theme.dart';
import 'first_run/first_run_screen.dart';
import 'l10n/strings.dart';
import 'services/classifier.dart';
import 'services/progress_service.dart';
import 'shell/app_scope.dart';
import 'shell/app_shell.dart';
import 'plate/catalog.dart';
import 'space/catalog.dart';
import 'today/detail_crop.dart';

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
  final binding = WidgetsFlutterBinding.ensureInitialized();
  registerFontLicences();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(DesignTheme.overlay(Brightness.light));
  // The splash stays until Today (or the first run) can draw complete:
  // settings, content and today's detail image. No visible loading state.
  binding.deferFirstFrame();
  runApp(MilionApp(onReady: binding.allowFirstFrame));
}

class MilionApp extends StatefulWidget {
  const MilionApp({super.key, this.onReady, this.clock, this.content});

  /// Called once when the first complete frame can be shown (or after
  /// [readyTimeout], so a failed load can still show its error state).
  final VoidCallback? onReady;
  final DateTime Function()? clock;
  final ContentRepository? content;
  static const readyTimeout = Duration(milliseconds: 1500);
  @override
  State<MilionApp> createState() => _MilionAppState();
}

class _MilionAppState extends State<MilionApp> {
  final _settings = AppSettings();
  final _progress = MilestoneProgress();
  late final ContentRepository _repository = widget.content ?? bundledContent;
  ContentRegistry? _registry;
  PlateCatalog _plates = const PlateCatalog.empty();
  SpaceCatalog _spaces = const SpaceCatalog.empty();
  Object? _error;
  Set<String> _recognised = const {};
  bool _ready = false;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _timeout = Timer(MilionApp.readyTimeout, _release);
    _start();
  }

  Future<void> _start() async {
    await Future.wait([_settings.load(), _progress.load(), _loadContent()]);
    if (!mounted) return;
    final registry = _registry;
    if (registry != null &&
        _settings.firstRunSeen &&
        registry.details.isNotEmpty) {
      final detail = detailOfDay(
        registry,
        (widget.clock ?? DateTime.now)(),
        playable: (d) =>
            _plates.forMilestone(registry.milestone(d.milestoneId)!) != null,
      );
      final scene = detail == null
          ? null
          : _plates.forMilestone(registry.milestone(detail.milestoneId)!);
      if (scene != null) {
        try {
          await precacheImage(AssetImage(scene.original), context);
        } catch (_) {
          // The image still loads in place; startup must not block on it.
        }
      }
    }
    _release();
  }

  Future<void> _loadContent() async {
    // Which artworks the on-device model covers, read alongside the registry;
    // only the camera-eye actions depend on it.
    final classes = _repository
        .loadText(Classifier.classesAsset)
        .then((text) => (jsonDecode(text) as List).cast<String>())
        .catchError((Object _) => const <String>[]);
    try {
      final registry = await _repository.load();
      final plates = await PlateCatalog.load(
        registry,
        _repository.loadText,
        strict: false,
      );
      for (final error in plates.errors) {
        debugPrint('Plate skipped: $error');
      }
      final spaces = await SpaceCatalog.load(
        registry,
        _repository.loadText,
        strict: false,
      );
      for (final error in spaces.errors) {
        debugPrint('Study skipped: $error');
      }
      final ids = await classes;
      final known = {for (final a in registry.artworks) a.id};
      if (!mounted) return;
      setState(() {
        _registry = registry;
        _plates = plates;
        _spaces = spaces;
        _recognised = {...ids.where(known.contains)};
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _release() {
    _timeout?.cancel();
    if (_ready) return;
    _ready = true;
    widget.onReady?.call();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _settings.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SettingsScope(
    settings: _settings,
    child: ProgressScope(
      progress: _progress,
      child: AppScope(
        registry: _registry,
        plates: _plates,
        spaces: _spaces,
        error: _error,
        retry: () {
          setState(() => _error = null);
          _loadContent();
        },
        clock: widget.clock ?? DateTime.now,
        recognised: _recognised,
        child: ListenableBuilder(
          listenable: _settings,
          builder: (context, _) => MaterialApp(
            onGenerateTitle: (context) => context.l10n.appTitle,
            debugShowCheckedModeBanner: false,
            restorationScopeId: 'milion',
            theme: DesignTheme.marble,
            darkTheme: DesignTheme.lamp,
            themeMode: _settings.themeMode,
            locale: _settings.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routes: kDebugMode
                ? {'/design': (_) => const DesignSheet()}
                : const {},
            home: !_settings.loaded
                ? const _Ground()
                : _Home(
                    firstRunSeen: _settings.firstRunSeen,
                    onFirstRunDone: _settings.completeFirstRun,
                  ),
          ),
        ),
      ),
    ),
  );
}

/// Before preferences load (behind the deferred first frame) nothing shows.
class _Ground extends StatelessWidget {
  const _Ground();
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: const SizedBox.expand(),
  );
}

/// The first child appears at once (the first run starts on black); only
/// the hand-over from the first run to Today is a sweep.
class _Home extends StatelessWidget {
  const _Home({required this.firstRunSeen, required this.onFirstRunDone});
  final bool firstRunSeen;
  final VoidCallback onFirstRunDone;
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: MotionToken.duration(
      MeasureMotion.sweep,
      reduced: MediaQuery.disableAnimationsOf(context),
    ),
    child: firstRunSeen
        ? const AppShell(key: ValueKey('shell'))
        : FirstRunScreen(
            key: const ValueKey('first-run'),
            onDone: onFirstRunDone,
          ),
  );
}
