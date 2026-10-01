import 'package:flutter/material.dart';

import '../content/models.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../shell/navigation.dart';

/// The register's chapters in §1 content order, by numeral range.
class Chapter {
  const Chapter(
    this.numeral,
    this.name,
    this.ground,
    this.material,
    this.first,
    this.last,
  );
  final String numeral, name;
  final Color ground, material;
  final int first, last;
  bool contains(Milestone m) => m.number >= first && m.number <= last;
}

List<Chapter> chaptersOf(BuildContext context) {
  final s = context.l10n;
  return [
    Chapter(
      'I',
      s.chapterByzantineName,
      Pigment.byzantine.ground,
      Pigment.byzantine.material,
      0,
      22,
    ),
    Chapter(
      'II',
      s.chapterMosquesName,
      Pigment.mosques.ground,
      Pigment.mosques.material,
      23,
      35,
    ),
    Chapter(
      'III',
      s.chapterMuseumsName,
      Pigment.museums.ground,
      Pigment.museums.material,
      36,
      45,
    ),
    Chapter('IV', s.chapterAbroadName, Pigment.lamp, Pigment.bronze, 46, 47),
  ];
}

/// A chapter heading on its wave ground, with the wave's material tessera.
class ChapterBand extends StatelessWidget {
  const ChapterBand({
    super.key,
    required this.chapter,
    required this.pieces,
    this.current = false,
  });
  final Chapter chapter;
  final List<Milestone> pieces;
  final bool current;
  @override
  Widget build(BuildContext context) {
    final s = context.l10n, lang = context.language;
    final playable = pieces.where((m) => explorerFor(m) != null).length;
    final approved = pieces
        .where((m) => m.status == MilestoneStatus.approved)
        .length;
    return Container(
      color: chapter.ground,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(width: 12, height: 12, color: chapter.material),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (current)
                  Text(
                    TypeRole.capitals(s.chapterCurrent, lang),
                    style: TypeRole.measurement.copyWith(color: Pigment.marble),
                  ),
                Semantics(
                  header: true,
                  child: Text(
                    TypeRole.capitals(
                      s.chapterHeading(chapter.numeral, chapter.name),
                      lang,
                    ),
                    style: TypeRole.inscription(20, color: Pigment.marble),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.chapterProgress(
                    '$playable',
                    '${pieces.length}',
                    '$approved',
                  ),
                  style: const TextStyle(color: Pigment.marble),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
