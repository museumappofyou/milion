import 'package:flutter/material.dart';

import '../city/city_tab.dart';
import '../design/plan_icon.dart';
import '../design/theme.dart';
import '../l10n/strings.dart';
import '../milestones/milestones_tab.dart';
import '../mosaic/mosaic_tab.dart';
import '../today/today_screen.dart';

enum Destination { today, city, milestones, mosaic }

/// Lets a composition on one tab move the shell to another.
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.select, required super.child});
  final ValueChanged<Destination> select;
  static ShellScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();
  @override
  bool updateShouldNotify(ShellScope old) => false;
}

/// Today, City, Milestones and Mosaic. Tabs stay alive, so their scroll
/// state survives switching; restoration carries tab and scroll across
/// process death. Back on another tab returns to Today; back on Today leaves.
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> with RestorationMixin {
  final _tab = RestorableInt(0);
  final _visited = <int>{0};

  Destination get current => Destination.values[_tab.value];

  @override
  String get restorationId => 'shell';
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_tab, 'tab');
    _visited.add(_tab.value);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void select(Destination d) => setState(() {
    _tab.value = d.index;
    _visited.add(d.index);
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final pages = [
      const TodayScreen(),
      const CityTab(),
      const MilestonesTab(),
      const MosaicTab(),
    ];
    return ShellScope(
      select: select,
      child: PopScope(
        canPop: current == Destination.today,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) select(Destination.today);
        },
        child: Scaffold(
          body: IndexedStack(
            index: _tab.value,
            children: [
              for (final (i, page) in pages.indexed)
                TickerMode(
                  enabled: i == _tab.value,
                  child: _visited.contains(i) ? page : const SizedBox.shrink(),
                ),
            ],
          ),
          bottomNavigationBar: AnnotatedRegion(
            value: DesignTheme.overlay(Theme.of(context).brightness),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: NavigationBar(
                selectedIndex: _tab.value,
                onDestinationSelected: (i) => select(Destination.values[i]),
                destinations: [
                  NavigationDestination(
                    icon: const PlanIcon(PlanSymbol.dial),
                    label: s.navToday,
                  ),
                  NavigationDestination(
                    icon: const PlanIcon(PlanSymbol.dome),
                    label: s.navCity,
                  ),
                  NavigationDestination(
                    icon: const PlanIcon(PlanSymbol.milestone),
                    label: s.navMilestones,
                  ),
                  NavigationDestination(
                    icon: const PlanIcon(PlanSymbol.tessera),
                    label: s.navMosaic,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
