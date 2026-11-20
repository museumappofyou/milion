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

/// Compact architectural capability tags showing what interactive content and
/// historical layers a place offers (`3D`, `Plate`, `3D Walk`, `Section`,
/// `Plan`, `N layers`), shared by the City list and Atlas marker sheets.
class PlaceCapabilityTags extends StatelessWidget {
  const PlaceCapabilityTags({super.key, required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.maybeOf(context);
    if (app == null) return const SizedBox.shrink();
    final s = context.l10n;
    final c = MeasureColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final milestones = app.playableMilestonesForPlace(place);
    final kinds = {for (final m in milestones) ?app.playableKind(m)};
    final has3d =
        kinds.contains(PlayableKind.space) ||
        app.studiesForPlace(place).isNotEmpty;
    final hasPlate = kinds.contains(PlayableKind.plate);
    final hasWalk = kinds.contains(PlayableKind.walk);
    final hasSection = kinds.contains(PlayableKind.section);
    final hasGuide = app.registry?.guideFor(place.id) != null;
    final strataCount = place.strata.length;
    if (!has3d &&
        !hasPlate &&
        !hasWalk &&
        !hasSection &&
        !hasGuide &&
        strataCount == 0) {
      return const SizedBox.shrink();
    }

    Widget tag(String label, {required Color color, bool tinted = true}) =>
        DecoratedBox(
          decoration: BoxDecoration(
            color: tinted ? c.poche : Colors.transparent,
            borderRadius: Space.radius,
            border: tinted
                ? null
                : Border.all(color: c.line.withValues(alpha: .7)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              TypeRole.capitals(label, context.language),
              style: TypeRole.measurement.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: .45,
                color: color,
              ),
            ),
          ),
        );

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (has3d) tag(s.placeCapability3d, color: c.accent),
        if (hasWalk)
          tag(
            s.placeCapabilityWalk,
            color: dark ? const Color(0xFF88BCE0) : Pigment.cobalt,
          ),
        if (hasPlate) tag(s.placeCapabilityPlate, color: c.accent),
        if (hasSection)
          tag(
            s.placeCapabilitySection,
            color: dark ? const Color(0xFF8EC5B6) : Pigment.verdigris,
          ),
        if (hasGuide)
          tag(
            s.placeCapabilityPlan,
            color: dark ? const Color(0xFF8EC5B6) : Pigment.verdigris,
          ),
        if (strataCount > 0)
          tag(
            s.placeStrataCount('$strataCount'),
            color: c.secondary,
            tinted: false,
          ),
      ],
    );
  }
}

/// The City tab (P10 + Phase 3): the Atlas or the same places as a searchable,
/// featured-first list. Map and list read one filter, one query and one list of
/// places ([atlasPlaces]), so they always agree; the list is the TalkBack-first view.
class CityTab extends StatefulWidget {
  const CityTab({super.key});
  @override
  State<CityTab> createState() => _CityTabState();
}

class _CityTabState extends State<CityTab> with RestorationMixin {
  final _list = RestorableBool(false);
  final _filter = RestorableStringN(null);
  final _stop = RestorableInt(atlasYears.length - 1);
  final _query = RestorableString('');
  final _featuredFirst = RestorableBool(true);
  final _atlas = AtlasController();
  final _searchCtrl = TextEditingController();
  bool _mapSearchOpen = false;
  Future<AtlasAssets>? _assets;

  @override
  String get restorationId => 'city';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_list, 'list');
    registerForRestoration(_filter, 'filter');
    registerForRestoration(_stop, 'stop');
    registerForRestoration(_query, 'query');
    registerForRestoration(_featuredFirst, 'featured-first');
    _searchCtrl.text = _query.value;
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
    _searchCtrl.dispose();
    _list.dispose();
    _filter.dispose();
    _stop.dispose();
    _query.dispose();
    _featuredFirst.dispose();
    super.dispose();
  }

  AtlasFilter get filter => AtlasFilter.decode(_filter.value);
  set filter(AtlasFilter f) =>
      setState(() => _filter.value = f.isEmpty ? null : f.encode());

  void _setQuery(String q) => setState(() => _query.value = q);

  void _clearQuery() => setState(() {
    _searchCtrl.clear();
    _query.value = '';
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final scope = AppScope.of(context);
    final registry = scope.registry;
    final f = filter;
    final interactiveIds = scope.interactivePlaceIds;
    final places = registry == null
        ? const <Place>[]
        : atlasPlaces(
            registry,
            f,
            scope.clock(),
            interactivePlaces: interactiveIds,
            query: _query.value,
          );
    final list = _list.value;
    final showSearch = _mapSearchOpen || _query.value.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.navCity),
        actions: [
          IconButton(
            key: const ValueKey('city-search-toggle'),
            tooltip: showSearch ? s.clearSearch : s.citySearchHint,
            onPressed: () => setState(() {
              if (showSearch) {
                _mapSearchOpen = false;
                _searchCtrl.clear();
                _query.value = '';
              } else {
                _mapSearchOpen = true;
              }
            }),
            icon: Icon(showSearch ? Icons.close : Icons.search),
          ),
          IconButton(
            key: const ValueKey('city-filters'),
            tooltip: f.isEmpty
                ? s.atlasFilters
                : s.atlasFiltersActive('${f.activeCount}'),
            onPressed: registry == null
                ? null
                : () => _openFilters(context, registry, interactiveIds),
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
      body: Column(
        children: [
          if (showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: _CitySearchField(
                controller: _searchCtrl,
                query: _query.value,
                onChanged: _setQuery,
                onClear: _clearQuery,
              ),
            ),
          Expanded(
            child: list
                ? _CityList(
                    places: places,
                    filtered: !f.isEmpty || _query.value.trim().isNotEmpty,
                    filter: f,
                    onFilterChanged: (next) => filter = next,
                    onClearQuery: _clearQuery,
                    featuredFirst: _featuredFirst.value,
                    onSortChanged: (v) =>
                        setState(() => _featuredFirst.value = v),
                    interactiveIds: interactiveIds,
                  )
                : _map(context, places),
          ),
        ],
      ),
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

  Future<void> _openFilters(
    BuildContext context,
    ContentRegistry registry,
    Set<String> interactiveIds,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _FilterSheet(
      registry: registry,
      now: AppScope.of(context).clock,
      initial: filter,
      interactiveIds: interactiveIds,
      query: _query.value,
      onChanged: (f) => filter = f,
    ),
  );
}

class _CitySearchField extends StatelessWidget {
  const _CitySearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return TextField(
      key: const ValueKey('city-search'),
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        hintText: s.citySearchHint,
        prefixIcon: const Icon(Icons.search, size: 20),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                tooltip: s.clearSearch,
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18),
              ),
      ),
    );
  }
}

class _CityList extends StatelessWidget {
  const _CityList({
    required this.places,
    required this.filtered,
    required this.filter,
    required this.onFilterChanged,
    required this.onClearQuery,
    required this.featuredFirst,
    required this.onSortChanged,
    required this.interactiveIds,
  });
  final List<Place> places;
  final bool filtered;
  final AtlasFilter filter;
  final ValueChanged<AtlasFilter> onFilterChanged;
  final VoidCallback onClearQuery;
  final bool featuredFirst;
  final ValueChanged<bool> onSortChanged;
  final Set<String> interactiveIds;

  bool _isFeatured(Place p) =>
      p.review == ReviewStatus.reviewed || interactiveIds.contains(p.id);

  void _toggleCategory(Category cat) {
    final next = {...filter.categories};
    if (!next.add(cat)) next.remove(cat);
    onFilterChanged(filter.copyWith(categories: next));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n,
        c = MeasureColors.of(context),
        lang = context.language;
    final reviewed = places
        .where((p) => p.review == ReviewStatus.reviewed)
        .length;

    final featured = [
      for (final p in places)
        if (_isFeatured(p)) p,
    ];
    final others = [
      for (final p in places)
        if (!_isFeatured(p)) p,
    ];
    final showGrouped =
        featuredFirst && featured.isNotEmpty && others.isNotEmpty;

    Widget rowFor(Place p) {
      final m = fromMilion(p);
      final draft = p.review == ReviewStatus.draft;
      final isRich = _isFeatured(p);
      return MergeSemantics(
        key: ValueKey('city-place-${p.id}'),
        child: InkWell(
          onTap: () => openPlace(context, p),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: c.line.withValues(alpha: .55)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PlanIcon(
                  categorySymbol(p),
                  color: isRich ? c.accent : c.secondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.names.inLanguage(lang),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: isRich
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isRich
                                  ? c.ink
                                  : c.ink.withValues(alpha: .88),
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          p.district?.spelling,
                          ...p.categories.map(
                            (cat) => categoryLabel(context, cat),
                          ),
                        ].whereType<String>().join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
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
                      if (isRich) ...[
                        const SizedBox(height: 6),
                        PlaceCapabilityTags(place: p),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Every draft keeps its mark, featured or not.
                if (draft)
                  Semantics(
                    label: s.notReviewed,
                    child: const TesseraSlot(
                      state: SlotState.planned,
                      width: 10,
                      height: 10,
                    ),
                  )
                else
                  Icon(Icons.chevron_right, size: 18, color: c.secondary),
              ],
            ),
          ),
        ),
      );
    }

    Widget groupHeader(String label) => Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      decoration: BoxDecoration(
        color: c.poche.withValues(alpha: .45),
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Semantics(
        header: true,
        child: Text(
          TypeRole.capitals(label, lang),
          style: TypeRole.measurement.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: .6,
            color: c.ink,
          ),
        ),
      ),
    );

    return CustomScrollView(
      key: const ValueKey('city-list'),
      restorationId: 'city-scroll',
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    FilterChip(
                      key: const ValueKey('city-quick-interactive'),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      selected: filter.interactiveOnly,
                      label: Text(s.cityQuickInteractive),
                      onSelected: (v) =>
                          onFilterChanged(filter.copyWith(interactiveOnly: v)),
                    ),
                    FilterChip(
                      key: const ValueKey('city-quick-reviewed'),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      selected: filter.reviewedOnly,
                      label: Text(s.cityQuickReviewed),
                      onSelected: (v) =>
                          onFilterChanged(filter.copyWith(reviewedOnly: v)),
                    ),
                    for (final cat in const [
                      Category.byzantine,
                      Category.mosque,
                      Category.cistern,
                      Category.museum,
                    ])
                      FilterChip(
                        key: ValueKey('city-quick-${cat.name}'),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        selected: filter.categories.contains(cat),
                        label: Text(categoryLabel(context, cat)),
                        onSelected: (_) => _toggleCategory(cat),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ChoiceChip(
                      key: const ValueKey('city-sort-featured'),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      selected: featuredFirst,
                      label: Text(s.citySortFeatured),
                      onSelected: (_) => onSortChanged(true),
                    ),
                    ChoiceChip(
                      key: const ValueKey('city-sort-distance'),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      selected: !featuredFirst,
                      label: Text(s.citySortDistance),
                      onSelected: (_) => onSortChanged(false),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  s.plottedPlaces('${places.length}', '$reviewed'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                // Distances are straight lines from the Milion (P05 disclosure).
                Text(
                  s.straightLine,
                  key: const ValueKey('city-straight-line'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (filtered && places.isEmpty) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.atlasNoMatches,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () {
                            onFilterChanged(AtlasFilter.none);
                            onClearQuery();
                          },
                          child: Text(s.atlasClearFilters),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showGrouped) ...[
          SliverToBoxAdapter(
            child: groupHeader(s.cityFeaturedPlaces('${featured.length}')),
          ),
          SliverList.builder(
            itemCount: featured.length,
            itemBuilder: (context, i) => rowFor(featured[i]),
          ),
          SliverToBoxAdapter(
            child: groupHeader(s.cityOtherPlaces('${others.length}')),
          ),
          SliverList.builder(
            itemCount: others.length,
            itemBuilder: (context, i) => rowFor(others[i]),
          ),
        ] else
          SliverList.builder(
            itemCount: places.length,
            itemBuilder: (context, i) => rowFor(places[i]),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
    required this.interactiveIds,
    required this.query,
    required this.onChanged,
  });
  final ContentRegistry registry;
  final DateTime Function() now;
  final AtlasFilter initial;
  final Set<String> interactiveIds;
  final String query;
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
    final count = atlasPlaces(
      widget.registry,
      f,
      widget.now(),
      interactivePlaces: widget.interactiveIds,
      query: widget.query,
    ).length;
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
      initialChildSize: .72,
      maxChildSize: .95,
      builder: (context, scroll) => Column(
        children: [
          const DimensionHandle(),
          Expanded(
            child: SingleChildScrollView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.atlasFilters, style: theme.textTheme.titleLarge),
                  SwitchListTile(
                    key: const ValueKey('filter-interactive'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.cityQuickInteractive),
                    value: f.interactiveOnly,
                    onChanged: (v) => _set(f.copyWith(interactiveOnly: v)),
                  ),
                  SwitchListTile(
                    key: const ValueKey('filter-reviewed'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.cityQuickReviewed),
                    value: f.reviewedOnly,
                    onChanged: (v) => _set(f.copyWith(reviewedOnly: v)),
                  ),
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
