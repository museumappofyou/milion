import 'package:flutter/material.dart';

import 'last_judgment_relief_screen.dart';

class LastJudgmentTab extends StatelessWidget {
  const LastJudgmentTab({super.key});

  void _open(BuildContext context, [String focus = 'Overview']) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LastJudgmentReliefScreen(initialFocus: focus),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Last Judgment')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _open(context),
                child: Image.asset(
                  'assets/last_judgment/relief_v5/relief_front.jpg',
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'F05 · PAREKKLESION VAULT',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The Last Judgment',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Explore the heavenly court, Christ in the mandorla, '
                      'the rolling up of heaven and the prepared throne in painted relief.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _open(context),
                        icon: const Icon(Icons.threed_rotation),
                        label: const Text('Explore painted relief'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Look closer', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final focus in ['Deesis', 'Christ', 'Heavens', 'Throne'])
              ActionChip(
                label: Text(focus),
                onPressed: () => _open(context, focus),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Reference photographs',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final reference in const [
          ('deesis_reference.jpg', 'Christ, Mary and John'),
          ('heavens_reference.jpg', 'The rolling up of heaven'),
          ('throne_reference.jpg', 'The prepared throne'),
          ('vault_reference.jpg', 'Complete vault'),
        ])
          Card(
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/last_judgment/${reference.$1}',
                  width: 64,
                  height: 50,
                  fit: BoxFit.cover,
                  cacheWidth: 192,
                ),
              ),
              title: Text(reference.$2),
              trailing: const Icon(Icons.open_in_full, size: 18),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    backgroundColor: const Color(0xFF1B1918),
                    appBar: AppBar(title: Text(reference.$2)),
                    body: Column(
                      children: [
                        Expanded(
                          child: InteractiveViewer(
                            maxScale: 5,
                            child: Center(
                              child: Image.asset(
                                'assets/last_judgment/${reference.$1}',
                              ),
                            ),
                          ),
                        ),
                        const SafeArea(
                          top: false,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Photograph: Caner Cangül',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 18),
        Text(
          'About this relief',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'An interpretation of the painting’s depth, using the same '
          'authored surface and gentle light as Anastasis v5. Zoom into faces, '
          'animate the figures’ gestures, or pause and examine a pose. Compare Original '
          'and Relief, and explore separate restoration studies. The source photographs remain unchanged.\n\n'
          'Photographs: Caner Cangül · supplied scene references.',
        ),
      ],
    ),
  );
}
