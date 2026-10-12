import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/components.dart';
import '../l10n/strings.dart';
import 'manifest.dart';
import 'player.dart';

/// Standalone entry used by previews; app navigation uses its parsed catalogue.
class PlateScreen extends StatefulWidget {
  const PlateScreen({super.key, required this.asset});
  final String asset;
  @override
  State<PlateScreen> createState() => _PlateScreenState();
}

class _PlateScreenState extends State<PlateScreen> {
  late final manifest = rootBundle
      .loadString(widget.asset, cache: false)
      .then(
        (text) =>
            PlateManifest.fromJson(jsonDecode(text) as Map<String, dynamic>),
      );
  @override
  Widget build(BuildContext context) => FutureBuilder<PlateManifest>(
    future: manifest,
    builder: (context, snapshot) => snapshot.hasData
        ? PlatePlayer(
            key: ValueKey(snapshot.data!.id),
            manifest: snapshot.data!,
          )
        : Scaffold(
            body: Center(
              child: snapshot.hasError
                  ? ContentState(
                      error: true,
                      title: context.l10n.sceneUnavailable,
                      message: context.l10n.plateUnavailable,
                    )
                  : const TesseraLoader(),
            ),
          ),
  );
}
