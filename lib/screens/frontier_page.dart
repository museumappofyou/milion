import 'package:flutter/material.dart';

import '../theme/milion_theme.dart';

class FrontierPage extends StatelessWidget {
  const FrontierPage({
    super.key,
    required this.onAnastasis,
    required this.onJudgment,
    required this.onCollection,
    required this.onScan,
    required this.onAbout,
  });

  final VoidCallback onAnastasis,
      onJudgment,
      onCollection,
      onScan,
      onAbout;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final wide = box.maxWidth >= 860;
      final padding = box.maxWidth < 600 ? 22.0 : 40.0;
      return SingleChildScrollView(
        key: const PageStorageKey('frontier-scroll'),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1360),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: wide ? 38 : 24),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 50),
                            child: _introduction(context, wide),
                          ),
                        ),
                        Expanded(
                          flex: 7,
                          child: _HeroArtwork(onOpen: onAnastasis, wide: true),
                        ),
                      ],
                    )
                  else ...[
                    _introduction(context, false),
                    const SizedBox(height: 28),
                    _HeroArtwork(onOpen: onAnastasis, wide: false),
                  ],
                  SizedBox(height: wide ? 52 : 30),
                  _ExperienceStrip(wide: wide),
                  SizedBox(height: wide ? 68 : 42),
                  _collectionHeading(context, wide),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cards = [
                        _SceneCard(
                          number: '01',
                          title: 'Anastasis',
                          location: 'THE SEMI-DOME',
                          image: 'assets/anastasis/conch_reference.jpg',
                          description: 'A hand reaches out. A story of resurrection unfolds.',
                          onOpen: onAnastasis,
                        ),
                        _SceneCard(
                          number: '02',
                          title: 'The Last Judgment',
                          location: 'THE VAULT',
                          image: 'assets/last_judgment/vault_reference.jpg',
                          description: 'A heavenly court, an unfolding sky, a world of detail.',
                          onOpen: onJudgment,
                        ),
                      ];
                      return constraints.maxWidth >= 700
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: 28),
                                Expanded(child: cards[1]),
                              ],
                            )
                          : Column(
                              children: [
                                cards[0],
                                const SizedBox(height: 30),
                                cards[1],
                              ],
                            );
                    },
                  ),
                  SizedBox(height: wide ? 64 : 40),
                  _ScanInvitation(onScan: onScan),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 30,
                      runSpacing: 8,
                      children: [
                        const Text(
                          'CHORA / KARIYE · ISTANBUL',
                          style: MilionTheme.eyebrow,
                        ),
                        TextButton.icon(
                          onPressed: onAbout,
                          label: const Text('About the collection & credits'),
                          icon: const Icon(Icons.arrow_outward, size: 15),
                          iconAlignment: IconAlignment.end,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _introduction(BuildContext context, bool wide) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          SizedBox(width: 24, child: Divider(color: MilionTheme.gold)),
          SizedBox(width: 10),
          Text('THE CHORA COLLECTION', style: MilionTheme.eyebrow),
        ],
      ),
      SizedBox(height: wide ? 26 : 18),
      Semantics(
        header: true,
        child: Text(
          'Stories beyond\nthe surface.',
          style: MilionTheme.display(wide ? 76 : 48),
        ),
      ),
      const SizedBox(height: 20),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Text(
          'Step inside the painted world of Chora. Explore its frescoes, bring figures to life, and discover the details between.',
          style: TextStyle(
            fontSize: wide ? 16 : 14,
            height: 1.65,
            color: MilionTheme.muted,
          ),
        ),
      ),
      SizedBox(height: wide ? 30 : 22),
      Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton.icon(
            key: const ValueKey('frontier-enter'),
            onPressed: onAnastasis,
            label: const Text('Enter Anastasis'),
            icon: const Icon(Icons.arrow_forward, size: 18),
            iconAlignment: IconAlignment.end,
          ),
          TextButton.icon(
            onPressed: onCollection,
            icon: const Icon(Icons.grid_view_outlined, size: 17),
            label: const Text('View collection'),
          ),
        ],
      ),
      if (wide) ...[
        const SizedBox(height: 48),
        const Text(
          'LOOK CLOSER. STAY CURIOUS.',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1.9,
            color: MilionTheme.muted,
          ),
        ),
      ],
    ],
  );

  Widget _collectionHeading(BuildContext context, bool wide) => Wrap(
    spacing: 36,
    runSpacing: 12,
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.end,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EXPLORE IN DEPTH', style: MilionTheme.eyebrow),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(
              'Two scenes. Countless details.',
              style: MilionTheme.display(wide ? 40 : 34),
            ),
          ),
        ],
      ),
      const SizedBox(
        width: 320,
        child: Text(
          'Move between the original fresco, painted relief and restored interpretation. Make each discovery your own.',
          style: TextStyle(color: MilionTheme.muted, fontSize: 13, height: 1.6),
        ),
      ),
    ],
  );
}

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork({required this.onOpen, required this.wide});
  final VoidCallback onOpen;
  final bool wide;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Material(
        color: MilionTheme.parchment,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(wide ? 240 : 145),
          topRight: Radius.circular(wide ? 240 : 145),
          bottomLeft: const Radius.circular(4),
          bottomRight: const Radius.circular(4),
        ),
        child: InkWell(
          onTap: onOpen,
          child: SizedBox(
            height: wide ? 550 : 330,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/restoration/anastasis_restored_4k_v2.jpg',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -.08),
                  cacheWidth: wide ? 1800 : 1100,
                  semanticLabel: 'Anastasis, restored interpretation',
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xC217251F)],
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 20,
                  bottom: 22,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FEATURED EXPERIENCE',
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 1.8,
                                color: MilionTheme.lightGold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'The Anastasis',
                              style: MilionTheme.display(
                                wide ? 40 : 32,
                                color: MilionTheme.paper,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: MilionTheme.paper.withValues(alpha: .55),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_outward,
                          color: MilionTheme.paper,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'F02 / PAREKKLESION',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 1.5,
              color: MilionTheme.muted,
            ),
          ),
          Text(
            'Restored interpretation',
            style: TextStyle(fontSize: 10, color: MilionTheme.muted),
          ),
        ],
      ),
    ],
  );
}

class _ExperienceStrip extends StatelessWidget {
  const _ExperienceStrip({required this.wide});
  final bool wide;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(vertical: wide ? 22 : 18),
    decoration: const BoxDecoration(
      border: Border(
        top: BorderSide(color: MilionTheme.line),
        bottom: BorderSide(color: MilionTheme.line),
      ),
    ),
    child: Row(
      children: [
        for (final (icon, title, description) in [
          (Icons.zoom_in, 'Look closer', 'Zoom into every detail'),
          (
            Icons.play_circle_outline,
            'Bring it to life',
            'See the figures move',
          ),
          (Icons.compare_outlined, 'See anew', 'Compare the restorations'),
        ])
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: MilionTheme.gold, size: 18),
                    if (wide) const SizedBox(width: 10),
                    if (wide)
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  wide ? description : title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: wide ? 12 : 10,
                    color: MilionTheme.muted,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.number,
    required this.title,
    required this.location,
    required this.image,
    required this.description,
    required this.onOpen,
  });
  final String number, title, location, image, description;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Material(
        color: MilionTheme.parchment,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: AspectRatio(
            aspectRatio: 1.72,
            child: Image.asset(
              image,
              fit: BoxFit.cover,
              cacheWidth: 1300,
              semanticLabel: 'Explore $title',
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Text(
            '$number / $location',
            style: MilionTheme.eyebrow.copyWith(fontSize: 9),
          ),
          const Spacer(),
          const Icon(Icons.layers_outlined, color: MilionTheme.gold, size: 17),
          const SizedBox(width: 5),
          const Text(
            'Interactive',
            style: TextStyle(fontSize: 10, color: MilionTheme.muted),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Text(title, style: MilionTheme.display(36)),
      const SizedBox(height: 6),
      Text(
        description,
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
          color: MilionTheme.muted,
        ),
      ),
      const SizedBox(height: 12),
      TextButton.icon(
        onPressed: onOpen,
        label: const Text('Explore scene'),
        icon: const Icon(Icons.arrow_forward, size: 16),
        iconAlignment: IconAlignment.end,
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
      ),
    ],
  );
}

class _ScanInvitation extends StatelessWidget {
  const _ScanInvitation({required this.onScan});
  final VoidCallback onScan;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: MilionTheme.ink,
      borderRadius: BorderRadius.circular(14),
    ),
    child: LayoutBuilder(
      builder: (context, box) {
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AT CHORA, OR EXPLORING FROM HOME',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.6,
                color: MilionTheme.lightGold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Find the story in front of you.',
              style: MilionTheme.display(36, color: MilionTheme.paper),
            ),
            const SizedBox(height: 12),
            const Text(
              'Point your camera at a fresco or choose a photograph to find its place in the collection.',
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Color(0xFFD2D6CD),
              ),
            ),
          ],
        );
        final button = FilledButton.icon(
          onPressed: onScan,
          style: FilledButton.styleFrom(
            backgroundColor: MilionTheme.lightGold,
            foregroundColor: MilionTheme.night,
          ),
          icon: const Icon(Icons.center_focus_strong_outlined, size: 18),
          label: const Text('Scan a scene'),
        );
        return box.maxWidth >= 750
            ? Row(
                children: [
                  Expanded(child: text),
                  const SizedBox(width: 48),
                  button,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [text, const SizedBox(height: 24), button],
              );
      },
    ),
  );
}
