import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../content/models.dart';
import '../content/registry.dart';
import '../design/plan_icon.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import 'dig_sections.dart';
import 'external_links.dart';

/// The visit card of the present layer: hours, entry, etiquette, access,
/// transit and "Report a change". Missing facts stay visibly unverified
/// (O15), and O17 keeps the report row hidden until an address exists.
class VisitCard extends StatelessWidget {
  const VisitCard({super.key, required this.place, required this.registry});
  final Place place;
  final ContentRegistry registry;
  @override
  Widget build(BuildContext context) {
    final visit = place.visit;
    if (visit == null) return const SizedBox.shrink();
    final s = context.l10n, lang = context.language;
    final name = place.names.inLanguage(lang);
    final report = reportChangeUri(
      place,
      subject: s.digReportSubject(name),
      body: s.digReportBody(name, place.qid),
    );
    String date(DateTime value) => DateFormat.yMMMMd(lang).format(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(s.digVisit, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _Field(
          label: s.digHours,
          value: visit.hours?.inLanguage(lang) ?? s.digNotChecked,
          note: visit.hoursCheckedAt == null
              ? null
              : s.digCheckedOn(date(visit.hoursCheckedAt!)),
        ),
        if (visit.entry != null)
          _Field(label: s.digEntry, value: visit.entry!.inLanguage(lang)),
        if (visit.etiquette != null)
          _Field(
            label: s.digEtiquette,
            value: visit.etiquette!.inLanguage(lang),
          ),
        _Field(
          label: s.digAccessibility,
          value: visit.accessibility?.inLanguage(lang) ?? s.digNotChecked,
        ),
        _Field(
          label: s.digGettingThere,
          value: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final transit in visit.transit)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const PlanIcon(PlanSymbol.route, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(transit.stop.inLanguage(lang))),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 24, top: 2),
                        child: Text(
                          s.digWalkMinutes('${transit.minutes}'),
                          style: TypeRole.measurement.copyWith(
                            color: MeasureColors.of(context).secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (visit.checkedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              s.digRemotelyChecked(date(visit.checkedAt!)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              s.digVisitUnverified,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 8),
        SourceList(
          sources: [
            for (final id in visit.sourceIds)
              if (registry.source(id) != null) registry.source(id)!,
          ],
        ),
        if (report != null)
          InkWell(
            key: const ValueKey('report-a-change'),
            onTap: () =>
                launchUrl(report, mode: LaunchMode.externalApplication),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: MeasureColors.of(context).line),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const PlanIcon(PlanSymbol.story, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    s.digReportChange,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, this.value, this.child, this.note});
  final String label;
  final String? value;
  final Widget? child;
  final String? note;
  @override
  Widget build(BuildContext context) {
    final c = MeasureColors.of(context), lang = context.language;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TypeRole.capitals(label, lang),
            style: TypeRole.measurement.copyWith(color: c.secondary),
          ),
          const SizedBox(height: 4),
          if (value != null) Text(value!),
          ?child,
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(note!, style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}
