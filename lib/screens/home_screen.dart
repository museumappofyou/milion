import 'package:flutter/material.dart';

import '../services/classifier.dart';
import '../content/bundled_content.dart';
import '../content/registry.dart';
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../l10n/strings.dart';
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
  final _classifier = Classifier();
  late Future<ContentRegistry> _catalogLoading = bundledContent.load();
  Future<void>? _scannerLoading;
  int _index = 0;
  @override
  void dispose() {
    final pending = _scannerLoading;
    if (pending == null) {
      _classifier.close();
    } else {
      pending.then(
        (_) => _classifier.close(),
        onError: (Object _, StackTrace _) => _classifier.close(),
      );
    }
    super.dispose();
  }

  void _select(int i) => setState(() {
    _index = i;
    if (i == 2) _scannerLoading ??= _classifier.load();
  });
  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  void _anastasis() => _open(const AnastasisReliefScreen());
  void _judgment() => _open(const LastJudgmentReliefScreen());
  Widget _page() {
    final s = context.l10n;
    switch (_index) {
      case 0:
        return FrontierPage(
          onAnastasis: _anastasis,
          onJudgment: _judgment,
          onCollection: () => _select(1),
          onScan: () => _select(2),
          onAbout: () => _select(3),
        );
      case 1:
        return FutureBuilder<ContentRegistry>(
          future: _catalogLoading,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: ContentState(
                  error: true,
                  title: s.collectionError,
                  message: s.collectionErrorBody,
                  onAction: () =>
                      setState(() => _catalogLoading = bundledContent.load()),
                ),
              );
            }
            if (!snapshot.hasData) return const Center(child: TesseraLoader());
            return ScenesTab(
              scenes: snapshot.data!.artworks
                  .where((a) => a.placeId == 'chora')
                  .map((a) => sceneForArtwork(a, language: context.language))
                  .toList(growable: false),
              onExamineAnastasis: _anastasis,
              onExamineLastJudgment: _judgment,
            );
          },
        );
      case 2:
        return FutureBuilder<void>(
          future: _scannerLoading,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: ContentState(
                  error: true,
                  title: s.scannerUnavailable,
                  message: s.scannerUnavailableBody,
                  onAction: () =>
                      setState(() => _scannerLoading = _classifier.load()),
                ),
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TesseraLoader(),
                    const SizedBox(height: 24),
                    Text(s.preparingScanner),
                    Text(s.preparingScannerBody),
                  ],
                ),
              );
            }
            return ScanTab(
              classifier: _classifier,
              onExploreAnastasis: _anastasis,
              onExploreLastJudgment: _judgment,
            );
          },
        );
      default:
        return const AboutTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Scaffold(
      appBar: _index == 0
          ? AppBar(title: const MilionWordmark(compact: true))
          : null,
      body: SafeArea(top: _index != 0, bottom: false, child: _page()),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: [
            NavigationDestination(
              icon: const PlanIcon(PlanSymbol.dome),
              label: s.home,
            ),
            NavigationDestination(
              icon: const PlanIcon(PlanSymbol.vitrine),
              label: s.collection,
            ),
            NavigationDestination(
              icon: const PlanIcon(PlanSymbol.cameraEye),
              label: s.scan,
            ),
            NavigationDestination(
              icon: const PlanIcon(PlanSymbol.story),
              label: s.about,
            ),
          ],
        ),
      ),
    );
  }
}
