import 'package:flutter/material.dart';

import '../atlas/atlas_assets.dart';
import '../atlas/atlas_controller.dart';
import '../atlas/atlas_filter.dart';
import '../atlas/atlas_map.dart';
import '../atlas/historic.dart';
import '../content/geography.dart';
import '../content/models.dart';
import '../content/registry.dart';
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../shell/app_scope.dart';
import '../shell/navigation.dart';

PlanSymbol categorySymbol(Place p) {
  final c = p.categories.where((c) => c != Category.byzantine).firstOrNull;
  return switch (c) {
    Category.mosque => PlanSymbol.minaret,
    Category.museum => PlanSymbol.vitrine,
    Category.palace || Category.fortification => PlanSymbol.gate,
    Category.cistern => PlanSymbol.cistern,
    Category.tower => PlanSymbol.column,
    Category.bazaar => PlanSymbol.route,
    Category.bath => PlanSymbol.dome,
    Category.other => PlanSymbol.milestone,
    Category.byzantine || null => PlanSymbol.dome,
  };
}

String categoryLabel(BuildContext context, Category c) {
  final s = context.l10n;
  return switch (c) {
    Category.byzantine => s.categoryByzantine,
    Category.mosque => s.categoryMosque,
    Category.museum => s.categoryMuseum,
    Category.palace => s.categoryPalace,
    Category.fortification => s.categoryFortification,
    Category.cistern => s.categoryCistern,
    Category.tower => s.categoryTower,
    Category.bazaar => s.categoryBazaar,
    Category.bath => s.categoryBath,
    Category.other => s.categoryOther,
  };
}

String waveLabel(BuildContext context, Wave w) {
  final s = context.l10n;
  return switch (w) {
    Wave.byzantine => s.atlasWaveByzantine,
    Wave.mosques => s.atlasWaveMosques,
    Wave.museums => s.atlasWaveMuseums,
    Wave.city => s.atlasWaveCity,
    Wave.abroad => s.atlasWaveAbroad,
  };
}

String eraName(BuildContext context, Era e) {
  final s = context.l10n;
  return switch (e) {
    Era.ancient => s.eraAncient,
    Era.roman => s.eraRoman,
    Era.byzantine => s.eraByzantine,
    Era.medieval => s.eraMedieval,
    Era.ottoman => s.eraOttoman,
    Era.modern => s.eraModern,
  };
}

/// The City tab (P10): the Atlas, or the same places as a list. Map and list
/// read one filter and one list of places ([atlasPlaces]), so they always
/// agree; the list is the TalkBack-first view.
class CityTab extends StatefulWidget {
  const CityTab({super.key});
  @override
  State<CityTab> createState() => _CityTabState();
}

class _CityTabState extends State<CityTab> with RestorationMixin {
  final _list = RestorableBool(false);
  final _filter = RestorableStringN(null);
  final _stop = RestorableInt(atlasYears.length - 1);
  final _atlas = AtlasController();
  Future<AtlasAssets>? _assets;

  @override
  String get restorationId => 'city';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_list, 'list');
    registerForRestoration(_filter, 'filter');
    registerForRestoration(_stop, 'stop');
    _atlas
      ..stop = _stop.value
      ..year = atlasYears[_stop.value].toDouble();
  }

  @override
  void initState() {
    super.initState();
    _atlas.addListener(_saveStop);
  }

  void _saveStop() {
    if (_stop.value != _atlas.stop) _stop.value = _atlas.stop;
  }

  @override
  void dispose() {
    _atlas
      ..removeListener(_saveStop)
      ..dispose();
    _list.dispose();
    _filter.dispose();
    _stop.dispose();
    super.dispose();
  }

  AtlasFilter get filter => AtlasFilter.decode(_filter.value);
  set filter(AtlasFilter f) =>
      setState(() => _filter.value = f.isEmpty ? null : f.encode());

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final scope = AppScope.of(context);
    final registry = scope.registry;
    final f = filter;
    final places = registry == null
        ? const <Place>[]
        : atlasPlaces(registry, f, scope.clock());
    final list = _list.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.navCity),
        actions: [
          IconButton(
            key: const ValueKey('city-filters'),
            tooltip: f.isEmpty
                ? s.atlasFilters
                : s.atlasFiltersActive('${f.activeCount}'),
            onPressed: registry == null
                ? null
                : () => _openFilters(context, registry),
            // The tooltip says how many are on; the badge is only drawn.
            icon: ExcludeSemantics(
              child: Badge(
                isLabelVisible: !f.isEmpty,
                label: Text('${f.activeCount}'),
                child: const Icon(Icons.tune),
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('city-mode'),
            tooltip: list ? s.atlasMap : s.atlasList,
            onPressed: () => setState(() => _list.value = !list),
            icon: Icon(list ? Icons.map_outlined : Icons.view_list_outlined),
          ),
        ],
      ),
      body: list
          ? _CityList(places: places, filtered: !f.isEmpty)
          : _map(context, places),
    );
  }

  Widget _map(BuildContext context, List<Place> places) {
    final s = context.l10n;
    _assets ??= AtlasAssets.load();
    return FutureBuilder<AtlasAssets>(
      future: _assets,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(s.atlasUnavailable));
        }
        final assets = snapshot.data;
        if (assets == null) {
          return Center(
            child: Semantics(liveRegion: true, child: Text(s.atlasLoading)),
          );
        }
        return AtlasMap(assets: assets, controller: _atlas, places: places);
      },
    );
  }

  Future<void> _openFilters(BuildContext context, ContentRegistry registry) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => _FilterSheet(
          registry: registry,
          now: AppScope.of(context).clock,
          initial: filter,
          onChanged: (f) => filter = f,
        ),
      );
}

class _CityList extends StatelessWidget {
  const _CityList({required this.places, required this.filtered});
  final List<Place> places;
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n,
        c = MeasureColors.of(context),
        lang = context.language;
    final reviewed = places
        .where((p) => p.review == ReviewStatus.reviewed)
        .length;
    return CustomScrollView(
      key: const ValueKey('city-list'),
      restorationId: 'city-scroll',
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.cityTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(s.plottedPlaces('${places.length}', '$reviewed')),
                const SizedBox(height: 4),
                Text(
                  s.straightLine,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (filtered && places.isEmpty) ...[
                  const SizedBox(height: 24),
                  Text(s.atlasNoMatches),
                ],
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: places.length,
          itemBuilder: (context, i) {
            final p = places[i], m = fromMilion(p);
            final draft = p.review == ReviewStatus.draft;
            return MergeSemantics(
              key: ValueKey('city-place-${p.id}'),
              child: InkWell(
                onTap: () => openPlace(context, p),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.line)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PlanIcon(categorySymbol(p)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.names.inLanguage(lang),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                p.district?.spelling,
                                ...p.categories.map(
                                  (c) => categoryLabel(context, c),
                                ),
                              ].whereType<String>().join(' · '),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 12,
                              children: [
                                MilDistance(m.km),
                                if (m.bearing != null)
                                  Text(
                                    '${m.bearing!.round()}°',
                                    style: TypeRole.measurement.copyWith(
                                      color: c.secondary,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        label: draft ? s.notReviewed : s.reviewed,
                        child: TesseraSlot(
                          state: draft
                              ? SlotState.planned
                              : SlotState.available,
                          width: 12,
                          height: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Wave, era, kind, district, open now and Milestone filters; changes apply
/// at once to the map or list behind the sheet.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.registry,
    required this.now,
    required this.initial,
    required this.onChanged,
  });
  final ContentRegistry registry;
  final DateTime Function() now;
  final AtlasFilter initial;
  final ValueChanged<AtlasFilter> onChanged;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late AtlasFilter f = widget.initial;

  void _set(AtlasFilter next) {
    setState(() => f = next);
    widget.onChanged(next);
  }

  Set<T> _toggle<T>(Set<T> set, T v) =>
      set.contains(v) ? ({...set}..remove(v)) : {...set, v};

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final theme = Theme.of(context);
    final count = atlasPlaces(widget.registry, f, widget.now()).length;
    Widget section<T>(
      String title,
      Iterable<T> values,
      Set<T> selected,
      String Function(T) label,
      AtlasFilter Function(Set<T>) update,
    ) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleSmall),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final v in values)
                FilterChip(
                  label: Text(label(v)),
                  selected: selected.contains(v),
                  onSelected: (_) => _set(update(_toggle(selected, v))),
                ),
            ],
          ),
        ],
      ),
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .7,
      maxChildSize: .95,
      builder: (context, scroll) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              children: [
                Text(s.atlasFilters, style: theme.textTheme.titleLarge),
                SwitchListTile(
                  key: const ValueKey('filter-open-now'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.filterOpenNow),
                  subtitle: Text(s.filterOpenNowHint),
                  value: f.openNow,
                  onChanged: (v) => _set(f.copyWith(openNow: v)),
                ),
                SwitchListTile(
                  key: const ValueKey('filter-milestone'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.filterHasMilestone),
                  value: f.hasMilestone,
                  onChanged: (v) => _set(f.copyWith(hasMilestone: v)),
                ),
                section<Wave>(
                  s.filterWave,
                  Wave.values,
                  f.waves,
                  (w) => waveLabel(context, w),
                  (v) => f.copyWith(waves: v),
                ),
                section<Era>(
                  s.filterEra,
                  Era.values,
                  f.eras,
                  (e) => eraName(context, e),
                  (v) => f.copyWith(eras: v),
                ),
                section<Category>(
                  s.filterCategory,
                  Category.values,
                  f.categories,
                  (c) => categoryLabel(context, c),
                  (v) => f.copyWith(categories: v),
                ),
                section<District>(
                  s.filterDistrict,
                  atlasDistricts(widget.registry),
                  f.districts,
                  (d) => d.spelling,
                  (v) => f.copyWith(districts: v),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Row(
                children: [
                  TextButton(
                    key: const ValueKey('filter-clear'),
                    onPressed: f.isEmpty ? null : () => _set(AtlasFilter.none),
                    child: Text(s.atlasClearFilters),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const ValueKey('filter-show'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(s.atlasShowPlaces('$count')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
