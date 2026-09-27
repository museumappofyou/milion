import 'package:flutter/material.dart';

import '../content/bundled_content.dart';
import '../content/geography.dart';
import '../content/models.dart';
import '../content/registry.dart';

/// Internal draft inspection, reachable only from About in debug builds.
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
  String _language = 'en';
  String text(String en, String tr) =>
      Localized(en: en, tr: tr).inLanguage(_language);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFEEE7DB),
    appBar: AppBar(
      title: Text(text('Registry', 'İçerik kaydı')),
      actions: [
        TextButton(
          onPressed: () =>
              setState(() => _language = _language == 'en' ? 'tr' : 'en'),
          child: Text(_language == 'en' ? 'TR' : 'EN'),
        ),
      ],
    ),
    body: FutureBuilder<ContentRegistry>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              text('Registry could not load.', 'İçerik kaydı yüklenemedi.'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final registry = snapshot.data!;
        final places = registry.placesByDistance(includeDrafts: true);
        return ListView(
          key: const PageStorageKey('registry-list'),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 20),
            Text(
              text('MILE ZERO', 'SIFIRINCI MİL'),
              style: const TextStyle(fontSize: 13, letterSpacing: 3),
            ),
            const SizedBox(height: 8),
            const Text(
              '41.008043° N · 28.978066° E',
              style: TextStyle(fontSize: 19),
            ),
            const SizedBox(height: 12),
            Text(
              text(
                '${places.length} places · ${registry.artworks.length} artworks',
                '${places.length} yer · ${registry.artworks.length} eser',
              ),
            ),
            Text(
              text(
                '${places.where((p) => p.review == ReviewStatus.draft).length} drafts · hidden from public place lists',
                '${places.where((p) => p.review == ReviewStatus.draft).length} taslak · genel yer listelerinde gösterilmez',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              text(
                'Straight-line distance · Roman miles rounded\n1 mil ≈ 1,480 m · bearings from true north',
                'Kuş uçuşu uzaklık · Roma mili yuvarlanır\n1 mil ≈ 1.480 m · açılar gerçek kuzeye göre',
              ),
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                text('Counts by category', 'Kategoriye göre sayılar'),
              ),
              children: [
                for (final c in Category.values)
                  _count(
                    _categoryName(c),
                    places.where((p) => p.categories.contains(c)).length,
                  ),
              ],
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                text('Counts by district · 39', 'İlçeye göre sayılar · 39'),
              ),
              children: [
                for (final d in District.values)
                  _count(
                    d.spelling,
                    places.where((p) => p.district == d).length,
                  ),
                _count(
                  text('Outside province', 'İl dışı'),
                  places.where((p) => p.outsideProvince).length,
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final place in places) _place(place),
          ],
        );
      },
    ),
  );

  Widget _count(String label, int count) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text('$count'),
      ],
    ),
  );

  String _categoryName(Category c) {
    const labels = {
      Category.byzantine: ('Byzantine', 'Bizans'),
      Category.mosque: ('Mosque', 'Cami'),
      Category.museum: ('Museum', 'Müze'),
      Category.palace: ('Palace', 'Saray'),
      Category.fortification: ('Fortification', 'Savunma yapısı'),
      Category.cistern: ('Cistern', 'Sarnıç'),
      Category.tower: ('Tower', 'Kule'),
      Category.bazaar: ('Bazaar', 'Çarşı'),
      Category.bath: ('Bath', 'Hamam'),
      Category.other: ('Other', 'Diğer'),
    };
    return text(labels[c]!.$1, labels[c]!.$2);
  }

  Widget _place(Place place) {
    final distance = fromMilion(place);
    final bearing = distance.bearing == null
        ? '—'
        : '${distance.bearing!.toStringAsFixed(0)}°';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFBDB3A5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${formatMilDistance(distance.km, language: _language)} · $bearing',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF4E1B2B),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            place.names.inLanguage(_language),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(place.hook.inLanguage(_language)),
          const SizedBox(height: 6),
          Text(
            '${place.district?.spelling ?? text('Outside province', 'İl dışı')} · ${place.qid} · ${place.reviewPhase}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
