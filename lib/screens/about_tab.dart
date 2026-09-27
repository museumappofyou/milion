import 'package:flutter/material.dart';

import '../theme/milion_theme.dart';

class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const MilionMark(size: 32),
                      const SizedBox(width: 12),
                      Text(
                        'Milion',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The Milion was the zero-mile stone of Constantinople: '
                    'every road distance in the empire was measured from it. '
                    'A fragment still stands on Divanyolu, beside the Basilica '
                    'Cistern. Milion measures Istanbul from that same point.',
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Point the camera at a mosaic or fresco in the Chora/Kariye '
                    'building and the app suggests which of the 103 catalogued '
                    'scenes you are looking at. Works fully offline.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('The model'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _InfoRow(label: 'Backbone', value: 'EfficientNet-B0, 224 px'),
                  _InfoRow(label: 'Head', value: 'ArcFace, 103 classes'),
                  _InfoRow(
                    label: 'Cross-validation',
                    value: '89.4% top-1, 93.4% top-3',
                  ),
                  _InfoRow(
                    label: 'Baseline',
                    value: '70.1% (frozen DINOv2 + kNN)',
                  ),
                  _InfoRow(label: 'Real photos', value: 'about 81% top-1'),
                  _InfoRow(label: '3D-viewer frames', value: 'about 95% top-1'),
                  _InfoRow(
                    label: 'Inference',
                    value: 'ONNX, about 47 ms per image on CPU',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('What it does not do'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'This demo only ranks possibilities. Measured on 231 hard '
                    'negatives, the model rejects at most about 67% of frames '
                    'that show no catalogued scene, below the 98% target. It '
                    'must never be treated as a confirmation on its own, and it '
                    'does not verify the geometry of what the camera sees.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Data and credits'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Trained on the Chora capture kit: project-owner captures, '
                    'licensed Wikimedia Commons references, and 3D virtual-tour '
                    'frames. Internal prototype, not cleared for publication.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () =>
                showLicensePage(context: context, applicationName: 'Milion'),
            child: const Text('Open-source licenses'),
          ),
          Center(
            child: Text(
              'Istanbul collection · Chora preview',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
