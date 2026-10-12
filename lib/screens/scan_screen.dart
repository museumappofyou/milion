import 'package:flutter/material.dart';

import '../design/components.dart';
import '../design/theme.dart';
import '../l10n/strings.dart';
import '../shell/app_scope.dart';
import '../shell/navigation.dart';
import '../services/classifier.dart';
import 'scan_tab.dart';

/// The camera-eye action on places and artworks with recognition support.
/// The model and camera load only here; nothing asks for camera access before.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _classifier = Classifier();
  late Future<void> _loading = _classifier.load();

  @override
  void dispose() {
    _loading.then(
      (_) => _classifier.close(),
      onError: (Object _, StackTrace _) => _classifier.close(),
    );
    super.dispose();
  }

  void _explore(String artworkId) {
    final app = AppScope.of(context);
    final m = app.registry!.milestones
        .where(
          (m) =>
              m.artworkIds.contains(artworkId) &&
              app.plates.forMilestone(m) != null,
        )
        .firstOrNull;
    if (m != null) openMilestone(context, m);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return FutureBuilder<void>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return ScanTab(
            classifier: _classifier,
            explorable: {
              for (final m in AppScope.of(context).registry!.milestones)
                if (AppScope.of(context).plates.forMilestone(m) != null)
                  ...m.artworkIds,
            },
            onExplore: _explore,
          );
        }
        return Theme(
          data: DesignTheme.lamp,
          child: Scaffold(
            appBar: AppBar(title: Text(s.scanScene)),
            body: Center(
              child: SingleChildScrollView(
                child: snapshot.hasError
                    ? ContentState(
                        error: true,
                        title: s.scannerUnavailable,
                        message: s.scannerUnavailableBody,
                        onAction: () =>
                            setState(() => _loading = _classifier.load()),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const TesseraLoader(),
                          const SizedBox(height: 24),
                          Text(s.preparingScanner),
                          Text(s.preparingScannerBody),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
