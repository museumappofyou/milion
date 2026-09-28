import 'package:flutter/material.dart';

import '../content/models.dart';
import '../content/geography.dart';
import '../content/bundled_content.dart';
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';

/// P03 reskin of the two existing artwork entry points; Today logic is P04.
class FrontierPage extends StatelessWidget {
  const FrontierPage({
    super.key,
    required this.onAnastasis,
    required this.onJudgment,
    required this.onCollection,
    required this.onScan,
    required this.onAbout,
  });
  final VoidCallback onAnastasis, onJudgment, onCollection, onScan, onAbout;
  @override
  Widget build(BuildContext context) {
    final s = context.l10n, c = MeasureColors.of(context);
    final large = MediaQuery.textScalerOf(context).scale(14) > 21;
    return ListView(
      key: const PageStorageKey('frontier-scroll'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 24),
        Wrap(
          spacing: 24,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Text(
              s.choraLocation,
              style: TypeRole.measurement.copyWith(color: c.secondary),
            ),
            FutureBuilder(
              future: bundledContent.load(),
              builder: (context, snapshot) {
                final place = snapshot.data?.places
                    .where((p) => p.id == 'chora')
                    .firstOrNull;
                return place == null
                    ? const SizedBox.shrink()
                    : MilDistance(fromMilion(place).km);
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        InkWell(
          key: const ValueKey('frontier-enter'),
          onTap: onAnastasis,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HonestyLabel(Honesty.ORIGINAL),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 1.22,
                child: Image.asset(
                  'assets/anastasis/flat_reference.jpg',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -.15),
                  semanticLabel: s.anastasis,
                  cacheWidth: 1200,
                ),
              ),
              const SizedBox(height: 16),
              if (large) ...[
                Row(
                  children: [
                    const MilestoneNumeral('I', size: 28),
                    const Spacer(),
                    const PlanIcon(PlanSymbol.layers),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.anastasis,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(s.anastasisHook),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MilestoneNumeral('I', size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.anastasis,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(s.anastasisHook),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const PlanIcon(PlanSymbol.layers),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        InkWell(
          onTap: onJudgment,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MilestoneNumeral('II', size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.judgment,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(s.judgmentHook),
                    ],
                  ),
                ),
                if (!large) const SizedBox(width: 16),
                if (!large)
                  Image.asset(
                    'assets/last_judgment/vault_reference.jpg',
                    width: 64,
                    height: 80,
                    fit: BoxFit.cover,
                    cacheWidth: 200,
                  ),
              ],
            ),
          ),
        ),
        const Divider(),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton.icon(
              onPressed: onCollection,
              icon: const PlanIcon(PlanSymbol.vitrine),
              label: Text(s.viewCollection),
            ),
            TextButton.icon(
              onPressed: onScan,
              icon: const PlanIcon(PlanSymbol.cameraEye),
              label: Text(s.scanScene),
            ),
          ],
        ),
        TextButton(onPressed: onAbout, child: Text(s.aboutCredits)),
        const SizedBox(height: 24),
      ],
    );
  }
}
