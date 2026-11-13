import 'dart:convert';
import 'dart:io';

import 'package:milion/content/registry.dart';
import 'package:milion/content/repository.dart';
import 'package:milion/plate/catalog.dart';
import 'package:milion/space/catalog.dart';
import 'package:milion/space/model.dart';

Future<void> main(List<String> args) async {
  try {
    final data = args.length == 2 && args.first == '--fixture'
        ? jsonDecode(await File(args.last).readAsString())
              as Map<String, dynamic>
        : await readContent(
            (path) => File(path).readAsString(),
            indexPath: args.isEmpty ? 'assets/content/index.json' : args.single,
          );
    final report = validateContent(data);
    for (final kind in recordKinds) {
      stdout.writeln('$kind: ${(data[kind] as List).length}');
    }
    for (final pair in [
      ('category', report.categories),
      ('district', report.districts),
      ('era (places, not strata)', report.eras),
      ('wave', report.waves),
    ]) {
      stdout.writeln(
        '${pair.$1}: ${pair.$2.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
      );
    }
    stdout.writeln(
      'Missing TR: ${report.missingTurkish.length}/${report.localizedCount} localized fields',
    );
    stdout.writeln(
      'Artworks complete: ${report.completeArtworks}/${(data['artworks'] as List).length}',
    );
    if (report.isValid) {
      final registry = ContentRegistry.fromJson(data);
      for (final path in [
        for (final m in registry.media) m.path,
        for (final m in registry.milestones)
          if (m.manifestPath != null) m.manifestPath!,
      ]) {
        if (!File(path).existsSync()) report.errors.add('Missing asset: $path');
      }
      final plates = await PlateCatalog.load(
        registry,
        (p) => File(p).readAsString(),
      );
      for (final p in plates.plates) {
        for (final path in [...p.imagePaths, ?p.rig?.path]) {
          if (!File(path).existsSync()) {
            report.errors.add('Missing plate asset: $path');
          }
        }
        final rigPath = p.rig?.path;
        if (rigPath != null) {
          final rig = jsonDecode(
            await File(rigPath).readAsString(),
          ) as Map<String, dynamic>;
          if (rig['poses'] is String &&
              !File(rig['poses'] as String).existsSync()) {
            report.errors.add('Missing plate poses: ${rig['poses']}');
          }
        }
      }
      stdout.writeln('Plates: ${plates.plates.length} typed manifests');
      // Studies: manifest, sources, and a model of closed named solids.
      final spaces = await SpaceCatalog.load(
        registry,
        (p) => File(p).readAsString(),
      );
      for (final study in spaces.studies) {
        final model = SpaceModel.fromGlb(
          (await File(study.model).readAsBytes()).buffer.asByteData(),
        );
        study.checkModel(model);
        for (final part in model.parts) {
          if (!part.closed) {
            report.errors.add('${study.id}: ${part.id} is not closed');
          }
        }
      }
      stdout.writeln('Studies: ${spaces.studies.length} typed manifests');
    }
    for (final error in report.errors) {
      stderr.writeln('ERROR: $error');
    }
    stdout.writeln(
      report.isValid
          ? 'VALID (schema $contentSchemaVersion)'
          : '${report.errors.length} error(s)',
    );
    if (!report.isValid) exitCode = 1;
  } catch (e) {
    stderr.writeln('ERROR: $e');
    exitCode = 1;
  }
}
