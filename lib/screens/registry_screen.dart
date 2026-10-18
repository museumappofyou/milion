import 'package:flutter/material.dart';

import '../content/bundled_content.dart';
import '../content/geography.dart';
import '../content/models.dart';
import '../content/registry.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../shell/app_scope.dart';
import '../shell/navigation.dart';
import '../space/study.dart';

class RegistryScreen extends StatefulWidget {
  const RegistryScreen({super.key, this.registry});
  final ContentRegistry? registry;
  @override
  State<RegistryScreen> createState() => _RegistryScreenState();
}

class _RegistryScreenState extends State<RegistryScreen> {
  late final Future<ContentRegistry> _load = widget.registry == null
      ? bundledContent.load()
      : Future.value(widget.registry);
  String? _language;
  @override
  Widget build(BuildContext context) => Localizations.override(
    context: context,
    locale: Locale(_language ?? context.language),
    delegates: AppLocalizations.localizationsDelegates,
    child: Builder(builder: _view),
  );
  Widget _view(BuildContext context) {
    final s = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.registry),
        actions: [
          TextButton(
            onPressed: () => setState(
              () => _language = context.language == 'en' ? 'tr' : 'en',
            ),
            child: Text(context.language == 'en' ? s.localeTr : s.localeEn),
          ),
        ],
      ),
      body: FutureBuilder<ContentRegistry>(
        future: _load,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ContentState(error: true, title: s.registryError);
          }
          if (!snapshot.hasData) return const Center(child: TesseraLoader());
          final registry = snapshot.data!,
              places = registry.placesByDistance(includeDrafts: true);
          return ListView(
            key: const PageStorageKey('registry-list'),
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                TypeRole.capitals(s.mileZero, context.language),
                style: TypeRole.measurement,
              ),
              const SizedBox(height: 8),
              Text(
                s.milionCoordinates,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                s.registryCounts(
                  '${places.length}',
                  '${registry.artworks.length}',
                ),
              ),
              Text(
                s.draftCounts(
                  '${places.where((p) => p.review == ReviewStatus.draft).length}',
                ),
              ),
              const SizedBox(height: 16),
              Text(s.registryMeasurement),
              const SizedBox(height: 16),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(s.categoryCounts),
                children: [
                  for (final c in Category.values)
                    _count(
                      context,
                      _category(context, c),
                      places.where((p) => p.categories.contains(c)).length,
                    ),
                ],
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(s.districtCounts),
                children: [
                  for (final d in District.values)
                    _count(
                      context,
                      d.spelling,
                      places.where((p) => p.district == d).length,
                    ),
                  _count(
                    context,
                    s.outsideProvince,
                    places.where((p) => p.outsideProvince).length,
                  ),
                ],
              ),
              ExpansionTile(
                key: const ValueKey('registry-studies'),
                tilePadding: EdgeInsets.zero,
                title: Text(s.spaceStudies),
                children: [
                  for (final st in _studies(context)) _study(context, st),
                ],
              ),
              const SizedBox(height: 16),
              for (final p in places) _place(context, p),
            ],
          );
        },
      ),
    );
  }

  /// Every study the bundle ships (P08's and the P09 kit's); the kit's are
  /// reached here until their places' layers name them (P16, P26).
  List<SpaceStudy> _studies(BuildContext context) => [
    ...?AppScope.maybeOf(context)?.spaces.studies,
  ];

  Widget _study(BuildContext context, SpaceStudy study) => ListTile(
    key: ValueKey('registry-study-${study.id}'),
    contentPadding: EdgeInsets.zero,
    title: Text(study.title.inLanguage(context.language)),
    subtitle: Text(
      [for (final e in study.epochs) e.label.inLanguage(context.language)]
          .join(' · '),
    ),
    trailing: Text('${study.triangles}', style: TypeRole.measurement),
    onTap: () => openStudy(context, study),
  );

  Widget _count(BuildContext context, String label, int count) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text('$count', style: TypeRole.measurement),
      ],
    ),
  );
  String _category(BuildContext context, Category c) {
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

  Widget _place(BuildContext context, Place p) {
    final d = fromMilion(p), c = MeasureColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              MilDistance(d.km),
              if (d.bearing != null)
                Text(
                  context.l10n.bearing('${d.bearing!.round()}'),
                  style: TypeRole.measurement.copyWith(color: c.secondary),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            p.names.inLanguage(context.language),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(p.hook.inLanguage(context.language)),
          const SizedBox(height: 8),
          Text(
            '${p.district?.spelling ?? context.l10n.outsideProvince} · ${p.qid} · ${p.reviewPhase}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          for (final st in [
            ...?AppScope.maybeOf(context)?.spaces.forPlace(p.id),
          ])
            TextButton(
              key: ValueKey('registry-place-study-${st.id}'),
              onPressed: () => openStudy(context, st),
              child: Text(st.title.inLanguage(context.language)),
            ),
        ],
      ),
    );
  }
}
