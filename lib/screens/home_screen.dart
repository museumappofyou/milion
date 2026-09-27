import 'package:flutter/material.dart';

import '../services/classifier.dart';
import '../theme/milion_theme.dart';
import 'about_tab.dart';
import 'anastasis_relief_screen.dart';
import 'frontier_page.dart';
import 'scan_tab.dart';
import 'last_judgment_relief_screen.dart';
import 'scenes_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Classifier _classifier = Classifier();
  late final Future<void> _catalogLoading = _classifier.loadCatalog();
  Future<void>? _scannerLoading;
  int _index = 0;

  @override
  void dispose() {
    final pending = _scannerLoading;
    if (pending == null) {
      _classifier.close();
    } else {
      // A model finishing after the app closes must release its session too.
      pending.then(
        (_) => _classifier.close(),
        onError: (Object _, StackTrace _) => _classifier.close(),
      );
    }
    super.dispose();
  }

  void _select(int index) => setState(() {
    _index = index;
    if (index == 2) _scannerLoading ??= _classifier.load();
  });

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  void _openAnastasis() => _open(const AnastasisReliefScreen());
  void _openJudgment() => _open(const LastJudgmentReliefScreen());

  Widget _page() => switch (_index) {
    0 => FrontierPage(
      onAnastasis: _openAnastasis,
      onJudgment: _openJudgment,
      onCollection: () => _select(1),
      onScan: () => _select(2),
      onAbout: () => _select(3),
    ),
    1 => FutureBuilder<void>(
      future: _catalogLoading,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _StatusPanel(
            title: 'The collection could not open',
            message: 'Return home to explore the featured frescoes.',
            icon: Icons.menu_book_outlined,
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StatusPanel(
            title: 'Opening the collection',
            loading: true,
          );
        }
        return ScenesTab(
          scenes: _classifier.scenes,
          onExamineAnastasis: _openAnastasis,
          onExamineLastJudgment: _openJudgment,
        );
      },
    ),
    2 => FutureBuilder<void>(
      future: _scannerLoading,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StatusPanel(
            title: 'The scanner is unavailable',
            message: 'You can still explore both frescoes and browse the collection.',
            icon: Icons.camera_alt_outlined,
            onRetry: () => setState(() => _scannerLoading = _classifier.load()),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StatusPanel(
            title: 'Preparing the scanner',
            message: 'Getting scene recognition ready for your photograph.',
            loading: true,
          );
        }
        return ScanTab(
          classifier: _classifier,
          onExploreAnastasis: _openAnastasis,
          onExploreLastJudgment: _openJudgment,
        );
      },
    ),
    _ => const AboutTab(),
  };

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: wide || _index == 0
          ? PreferredSize(
              preferredSize: Size.fromHeight(
                wide
                    ? 88
                    : (MediaQuery.textScalerOf(context).scale(40) + 32).clamp(
                        72,
                        104,
                      ),
              ),
              child: SafeArea(
                bottom: false,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: MilionTheme.line)),
                  ),
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1360),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 22),
                      child: Row(
                        children: [
                          Semantics(
                            button: true,
                            label: 'Go to home',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () => _select(0),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: MilionWordmark(),
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (wide) ...[
                            for (final (index, label) in [
                              (0, 'Home'),
                              (1, 'Collection'),
                              (3, 'About'),
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 22),
                                child: TextButton(
                                  onPressed: () => _select(index),
                                  style: TextButton.styleFrom(
                                    foregroundColor: _index == index
                                        ? MilionTheme.ink
                                        : MilionTheme.muted,
                                    textStyle: TextStyle(
                                      fontFamily: 'DMSans',
                                      fontSize: 13,
                                      fontWeight: _index == index
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                  child: Text(label),
                                ),
                              ),
                            FilledButton.icon(
                              onPressed: () => _select(2),
                              icon: const Icon(
                                Icons.center_focus_strong_outlined,
                                size: 17,
                              ),
                              label: const Text('Scan a scene'),
                            ),
                          ] else
                            const Text(
                              'ISTANBUL',
                              style: TextStyle(
                                fontSize: 8,
                                letterSpacing: 1.3,
                                color: MilionTheme.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: SafeArea(top: false, bottom: false, child: _page()),
      bottomNavigationBar: wide
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: MilionTheme.line)),
              ),
              child: NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: _select,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.grid_view_outlined),
                    selectedIcon: Icon(Icons.grid_view_rounded),
                    label: 'Collection',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.center_focus_strong_outlined),
                    selectedIcon: Icon(Icons.center_focus_strong),
                    label: 'Scan',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.info_outline),
                    selectedIcon: Icon(Icons.info),
                    label: 'About',
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.title,
    this.message,
    this.loading = false,
    this.icon,
    this.onRetry,
  });
  final String title;
  final String? message;
  final bool loading;
  final IconData? icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const CircularProgressIndicator(strokeWidth: 2)
            else
              Icon(icon, color: MilionTheme.gold, size: 36),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: MilionTheme.display(32),
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: MilionTheme.muted),
                ),
              ),
            if (onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
