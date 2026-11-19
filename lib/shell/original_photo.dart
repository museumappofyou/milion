import 'package:flutter/material.dart';

import '../content/models.dart';
import '../design/components.dart';
import '../l10n/strings.dart';
import 'app_scope.dart';

/// P14: a credited photograph of the thing itself, from a walk's stop or a
/// section's find. It is the ORIGINAL view of a page whose drawing is a
/// RECONSTRUCTION: the photo pinch-zooms, the credit and its source sit
/// under it.
class OriginalPhotoPage extends StatelessWidget {
  const OriginalPhotoPage({super.key, required this.media, this.title});
  final Media media;
  final Localized? title;

  @override
  Widget build(BuildContext context) {
    final lang = context.language;
    final registry = AppScope.maybeOf(context)?.registry;
    final source = registry?.source(media.sourceId)?.title.inLanguage(lang);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title?.inLanguage(lang) ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: Image.asset(
                  media.path,
                  key: ValueKey('original-photo-${media.id}'),
                  fit: BoxFit.contain,
                  semanticLabel: title?.inLanguage(lang),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HonestyLabel(Honesty.ORIGINAL),
                const SizedBox(height: 8),
                Text(
                  [
                    media.credit.inLanguage(lang),
                    ?source,
                  ].join(' — '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens [mediaId]'s photograph, if the registry has it.
Future<void> openOriginalPhoto(
  BuildContext context,
  String mediaId, {
  Localized? title,
}) async {
  final media = AppScope.maybeOf(context)?.registry?.mediaItem(mediaId);
  if (media == null) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => OriginalPhotoPage(media: media, title: title),
    ),
  );
}
