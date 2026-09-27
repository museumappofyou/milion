// Prepares the shipped Anastasis photographs from the chora-ar corpus: the
// raw reference captures of scene F02 are letterbox-trimmed, cropped,
// downsized and re-encoded into assets/anastasis/, with a provenance manifest
// at assets/anastasis/captures.json.
//
// Usage (from the app package root):
//   dart run tool/prepare_anastasis_assets.dart [source-folder]
//
// The corpus root comes from MILION_CAPTURES, defaulting to the sibling
// checkout ../chora-ar/captures next to this repository. Every shipped
// photograph is derivable from this one command.

import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

/// Root of the capture corpus. Override with MILION_CAPTURES; by default the
/// sibling checkout `../chora-ar/captures` next to this repository.
String get capturesRoot =>
    Platform.environment['MILION_CAPTURES'] ??
    '${File.fromUri(Platform.script).parent.parent.path}/../chora-ar/captures';

String get defaultSourceFolder =>
    '$capturesRoot/chora-scenes/5-PAREKKLESION/C__F02__Anastasis__dome__REF-8';

const String outputFolder = 'assets/anastasis';

const String artifactId = 'F02';
const String artifactTitle = 'Anastasis';
const String artifactRoom = 'Parekklesion';

const String preparedBy = 'tool/prepare_anastasis_assets.dart';
const String preparedOn = '2026-09-24';

/// A rectangle in normalized coordinates of the (trimmed) source image.
class Norm {
  const Norm(this.x0, this.y0, this.x1, this.y1);

  final double x0;
  final double y0;
  final double x1;
  final double y1;
}

class CaptureSpec {
  const CaptureSpec({
    required this.id,
    required this.source,
    required this.output,
    required this.role,
    required this.title,
    required this.credit,
    this.caption = '',
    this.sourceUrl,
    this.crop,
    this.maxWidth = 1600,
    this.quality = 82,
    this.excludePip = false,
    this.letterbox = true,
  });

  final String id;
  final String source;
  final String output;
  final String role;
  final String title;
  final String credit;
  final String caption;
  final String? sourceUrl;
  final Norm? crop;
  final int maxWidth;
  final int quality;

  /// Crops away the viewer's bottom-right picture-in-picture overlay.
  final bool excludePip;

  /// Trims near-uniform dark letterbox bars from the edges.
  final bool letterbox;
}

/// The picture-in-picture overlay of the capture viewer, as a fraction of the
/// source image, with a small safety margin.
const Norm pipRect = Norm(0.0, 0.0, 0.878, 1.0);

const List<CaptureSpec> captures = [
  // ---- Texture and framing -------------------------------------------------
  CaptureSpec(
    id: 'ref-17-18-48',
    source: 'Screenshot 2026-09-23 at 17.18.48.png',
    output: 'conch_reference.jpg',
    role: 'texture',
    title: 'Conch reference capture',
    credit: 'Reference capture, 2026-09-23 (photographer unrecorded)',
    caption:
        'Frontal capture of the whole Anastasis field. This is the texture '
        'wrapped onto the reconstructed semi-dome surface.',
    maxWidth: 2048,
    quality: 86,
  ),
  CaptureSpec(
    id: 'ref-17-18-16',
    source: 'Screenshot 2026-09-23 at 17.18.16.png',
    output: 'conch_reference_alt.jpg',
    role: 'wide',
    title: 'Conch reference, alternate framing',
    credit: 'Reference capture, 2026-09-23 (photographer unrecorded)',
    caption:
        'Companion frontal capture with more of the vault below the lunette.',
    maxWidth: 1600,
  ),
  CaptureSpec(
    id: 'web-01',
    source: 'web-ke-01-CAN09421.jpg',
    output: 'flat_reference.jpg',
    role: 'flat-reference',
    title: 'Flat reference photograph',
    credit: '© Caner Cangül, kulturenvanteri.com',
    sourceUrl: 'https://cdn.kulturenvanteri.com/wp-content/uploads/2019/11/CAN09421.jpg',
    caption:
        'Published flat photograph of the same fresco; used to compare the '
        'curved reconstruction against an independent capture.',
    maxWidth: 1600,
    quality: 84,
    letterbox: false,
  ),

  // ---- Details -------------------------------------------------------------
  CaptureSpec(
    id: 'detail-christ',
    source: 'Screenshot 2026-09-23 at 17.17.28.png',
    output: 'detail_christ_mandorla.jpg',
    role: 'detail',
    title: 'Christ in the mandorla',
    credit: 'Reference capture, 2026-09-23 (photographer unrecorded)',
    caption:
        'Christ strides on the broken gates, rayed mandorla behind him, '
        'pulling Adam up by the wrist.',
    crop: Norm(0.13, 0.0, 0.95, 1.0),
  ),
  CaptureSpec(
    id: 'detail-adam',
    source: 'Screenshot 2026-09-23 at 17.17.36.png',
    output: 'detail_adam_raised.jpg',
    role: 'detail',
    title: 'Adam raised from the tomb',
    credit: 'Reference capture, 2026-09-23 (photographer unrecorded)',
    caption:
        'Adam, grey-haired and in a pale robe, is drawn out of his sarcophagus '
        'as the kings and prophets look on.',
    crop: Norm(0.02, 0.04, 0.76, 1.0),
    excludePip: true,
  ),
  CaptureSpec(
    id: 'detail-kings',
    source: 'Screenshot 2026-09-23 at 17.18.35.png',
    output: 'detail_kings_prophets.jpg',
    role: 'detail',
    title: 'Kings and prophets (left group)',
    credit: 'Reference capture, 2026-09-23 (photographer unrecorded)',
    caption:
        'David and Solomon with the kings and prophets at the left end of the '
        'conch, beside the painted arch border.',
    crop: Norm(0.10, 0.02, 0.78, 1.0),
  ),
  CaptureSpec(
    id: 'detail-righteous',
    source: 'Screenshot 2026-09-23 at 17.18.24.png',
    output: 'detail_righteous_group.jpg',
    role: 'detail',
    title: 'John the Baptist and the righteous (right group)',
    credit: 'Reference capture, 2026-09-23 (photographer unrecorded)',
    caption:
        'John the Baptist with the righteous behind him at the right end of '
        'the conch, under the painted arch border.',
    crop: Norm(0.34, 0.0, 0.88, 1.0),
  ),
  CaptureSpec(
    id: 'detail-eve',
    source: 'Screenshot 2026-09-23 at 17.17.49.png',
    output: 'detail_eve_and_baptist.jpg',
    role: 'detail',
    title: 'Eve and the bound figure',
    credit: 'Reference capture, 2026-09-23 (photographer unrecorded)',
    caption:
        'Eve in red is lifted from her tomb while the dark, bound figure of '
        'Hades-Satan crouches below Christ\u2019s reaching hand.',
    crop: Norm(0.02, 0.0, 0.70, 1.0),
  ),
  CaptureSpec(
    id: 'detail-gates-web',
    source: 'web-ke-02-Isanin-Ayaklari-Altinda-Zincire-Vurulmus-Seytan.jpg',
    output: 'detail_gates_hades.jpg',
    role: 'detail',
    title: 'Broken gates and bound Hades',
    credit: '© Caner Cangül, kulturenvanteri.com',
    sourceUrl: 'https://cdn.kulturenvanteri.com/wp-content/uploads/2024/05/Isanin-Ayaklari-Altinda-Zincire-Vurulmus-Seytan.jpg',
    caption:
        'The locks, keys, chains and broken doors scattered under Christ\u2019s '
        'feet, with Hades-Satan bound below.',
    maxWidth: 1234,
    letterbox: false,
  ),
  CaptureSpec(
    id: 'detail-gates-ref',
    source: 'Screenshot 2026-09-23 at 17.17.58.png',
    output: 'detail_gates_hades_ref.jpg',
    role: 'detail',
    title: 'Underfoot: gates, locks and chains',
    credit: 'Reference capture, 2026-09-23 (photographer unrecorded)',
    caption:
        'Reference capture of the lowest band of the conch: the shattered '
        'gates, fallen locks and Hades beneath Christ\u2019s feet.',
    crop: Norm(0.0, 0.0, 0.86, 1.0),
  ),

  // ---- In situ and historical ---------------------------------------------
  CaptureSpec(
    id: 'context-2014-13',
    source: '2014_Interior_of_Chora_Church__13_.png',
    output: 'apse_context_2014.jpg',
    role: 'context',
    title: 'The apse in situ (2014)',
    credit: 'Chris06, Wikimedia Commons, 2014-10-03',
    sourceUrl: 'https://commons.wikimedia.org/wiki/File:2014_Interior_of_Chora_Church_(13).jpg',
    caption:
        'The Anastasis conch above the church fathers in the Parekklesion '
        'apse; the true curvature and springing line are visible here.',
    maxWidth: 1600,
    quality: 84,
    letterbox: false,
  ),
  CaptureSpec(
    id: 'context-2014-12',
    source: '2014_Interior_of_Chora_Church__12_.png',
    output: 'apse_context_2014_alt.jpg',
    role: 'context',
    title: 'The apse in situ, closer (2014)',
    credit: 'Chris06, Wikimedia Commons, 2014-10-03',
    sourceUrl: 'https://commons.wikimedia.org/wiki/File:2014_Interior_of_Chora_Church_(12).jpg',
    caption:
        'A closer in-situ view of the lunette over the apse window; the '
        'lunette meets the springing line at the cornice.',
    maxWidth: 1600,
    quality: 84,
    letterbox: false,
  ),
  CaptureSpec(
    id: 'historical-1998',
    source: 'Estambul__Mezquita_Kariye_1998_08.png',
    output: 'historical_1998.jpg',
    role: 'historical',
    title: 'Historical photograph (1998)',
    credit: 'LBM1948, Wikimedia Commons, 1998-04',
    sourceUrl: 'https://commons.wikimedia.org/wiki/File:Estambul,_Mezquita_Kariye_1998_08.jpg',
    caption:
        'A 1998 photograph of the same conch, useful for comparing condition '
        'and colour against the 2026 captures.',
    maxWidth: 1051,
    letterbox: false,
  ),

  // ---- Remaining captures (gallery only) -----------------------------------
  CaptureSpec(
    id: 'cap-17-17-34',
    source: 'Screenshot 2026-09-23 at 17.17.34.png',
    output: 'capture_17_17_34.jpg',
    role: 'capture',
    title: 'Capture 17:17',
    credit: 'Reference capture, 2026-09-23 (photographer unrecorded)',
    caption: 'Christ and both raised figures in one frame.',
    maxWidth: 1100,
    quality: 78,
  ),
  CaptureSpec(
    id: 'cap-17-17-39',
    source: 'Screenshot 2026-09-23 at 17.17.39.png',
    output: 'capture_17_17_39.jpg',
    role: 'capture',
    title: 'Capture 17:17 (left group)',
    credit: 'Reference capture, 2026-09-23 (photographer unrecorded)',
    caption: 'The left group with Adam; viewer overlay cropped away.',
    maxWidth: 1100,
    quality: 78,
    excludePip: true,
  ),
  CaptureSpec(
    id: 'cap-17-17-42',
    source: 'Screenshot 2026-09-23 at 17.17.42.png',
    output: 'capture_17_17_42.jpg',
    role: 'capture',
    title: 'Capture 17:17 (left group and border)',
    credit: 'Reference capture, 2026-09-23 (photographer unrecorded)',
    caption:
        'Left group with the painted arch border; viewer overlay cropped away.',
    maxWidth: 1100,
    quality: 78,
    excludePip: true,
  ),
  CaptureSpec(
    id: 'cap-17-17-51',
    source: 'Screenshot 2026-09-23 at 17.17.51.png',
    output: 'capture_17_17_51.jpg',
    role: 'capture',
    title: 'Capture 17:17 (right group)',
    credit: 'Reference capture, 2026-09-23 (photographer unrecorded)',
    caption: 'Right group with the arch border; viewer overlay cropped away.',
    maxWidth: 1100,
    quality: 78,
    excludePip: true,
  ),
  CaptureSpec(
    id: 'cap-17-17-53',
    source: 'Screenshot 2026-09-23 at 17.17.53.png',
    output: 'capture_17_17_53.jpg',
    role: 'capture',
    title: 'Capture 17:17 (full field)',
    credit: 'Reference capture, 2026-09-23 (photographer unrecorded)',
    caption: 'Full field, alternate framing; viewer overlay cropped away.',
    maxWidth: 1100,
    quality: 78,
    excludePip: true,
  ),

  // ---- Guide thumbnails (already small) ------------------------------------
  CaptureSpec(
    id: 'guide-01',
    source: 'F02-01.jpg',
    output: 'guide_f02_01.jpg',
    role: 'guide',
    title: 'Guide thumbnail',
    credit: 'Project guide image (low resolution)',
    caption: 'Low-resolution guide thumbnail shipped with the scene catalog.',
    maxWidth: 480,
    quality: 82,
    letterbox: false,
  ),
  CaptureSpec(
    id: 'guide-02',
    source: 'F02-02.jpg',
    output: 'guide_f02_02.jpg',
    role: 'guide',
    title: 'Guide thumbnail (underfoot detail)',
    credit: 'Project guide image (low resolution)',
    caption: 'Low-resolution guide thumbnail of the gates and Hades.',
    maxWidth: 480,
    quality: 82,
    letterbox: false,
  ),
  CaptureSpec(
    id: 'guide-a3-1',
    source: 'a3-f02-001.jpg',
    output: 'guide_a3_f02_001.jpg',
    role: 'guide',
    title: 'Archive thumbnail 001',
    credit: 'Project archive image (low resolution)',
    caption: 'Low-resolution archive thumbnail of the Anastasis field.',
    maxWidth: 480,
    quality: 82,
    letterbox: false,
  ),
  CaptureSpec(
    id: 'guide-a3-2',
    source: 'a3-f02-002.jpg',
    output: 'guide_a3_f02_002.jpg',
    role: 'guide',
    title: 'Archive thumbnail 002',
    credit: 'Project archive image (low resolution)',
    caption: 'Low-resolution archive thumbnail of the Anastasis field.',
    maxWidth: 480,
    quality: 82,
    letterbox: false,
  ),
  CaptureSpec(
    id: 'guide-a3-3',
    source: 'a3-f02-003.jpg',
    output: 'guide_a3_f02_003.jpg',
    role: 'guide',
    title: 'Archive thumbnail 003',
    credit: 'Project archive image (low resolution)',
    caption: 'Low-resolution archive thumbnail of the Anastasis field.',
    maxWidth: 480,
    quality: 82,
    letterbox: false,
  ),
  CaptureSpec(
    id: 'guide-a3-4',
    source: 'a3-f02-004.jpg',
    output: 'guide_a3_f02_004.jpg',
    role: 'guide',
    title: 'Archive thumbnail 004',
    credit: 'Project archive image (low resolution)',
    caption: 'Low-resolution archive thumbnail of the Anastasis field.',
    maxWidth: 480,
    quality: 82,
    letterbox: false,
  ),
];

void main(List<String> args) {
  final sourceFolder = args.isNotEmpty ? args.first : defaultSourceFolder;
  final sourceDir = Directory(sourceFolder);
  if (!sourceDir.existsSync()) {
    stderr.writeln(
      'Source folder not found: $sourceFolder\n'
      'Set MILION_CAPTURES to the capture corpus root (default: '
      'the ../chora-ar/captures folder next to this repository), or pass '
      'the scene folder as the first argument.',
    );
    exitCode = 1;
    return;
  }
  final outDir = Directory(outputFolder);
  if (outDir.existsSync()) {
    outDir.deleteSync(recursive: true);
  }
  outDir.createSync(recursive: true);

  final entries = <Map<String, dynamic>>[];
  for (final spec in captures) {
    final sourceFile = File('${sourceDir.path}/${spec.source}');
    if (!sourceFile.existsSync()) {
      stderr.writeln('MISSING source: ${spec.source}');
      exitCode = 1;
      return;
    }
    final sourceBytes = sourceFile.readAsBytesSync();
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      stderr.writeln('Could not decode ${spec.source}');
      exitCode = 1;
      return;
    }
    final source = img.bakeOrientation(decoded);

    var working = source;
    var trimTop = 0;
    var trimBottom = 0;
    if (spec.letterbox) {
      trimTop = _scanBars(working, fromTop: true);
      trimBottom = _scanBars(working, fromTop: false);
      if (working.height - trimTop - trimBottom < 100) {
        stderr.writeln('Letterbox trim would destroy ${spec.source}');
        exitCode = 1;
        return;
      }
      working = img.copyCrop(
        working,
        x: 0,
        y: trimTop,
        width: working.width,
        height: working.height - trimTop - trimBottom,
      );
    }

    var pipExcluded = false;
    final crop = spec.excludePip ? pipRect : spec.crop;
    if (crop != null) {
      final x0 = (crop.x0 * working.width).round().clamp(0, working.width - 1);
      final y0 = (crop.y0 * working.height).round().clamp(
        0,
        working.height - 1,
      );
      final x1 = (crop.x1 * working.width).round().clamp(x0 + 1, working.width);
      final y1 = (crop.y1 * working.height).round().clamp(
        y0 + 1,
        working.height,
      );
      working = img.copyCrop(
        working,
        x: x0,
        y: y0,
        width: x1 - x0,
        height: y1 - y0,
      );
      pipExcluded = spec.excludePip;
    }

    if (working.width > spec.maxWidth) {
      working = img.copyResize(
        working,
        width: spec.maxWidth,
        interpolation: img.Interpolation.cubic,
      );
    }

    final jpg = img.encodeJpg(working, quality: spec.quality);
    final outputFile = File('$outputFolder/${spec.output}');
    outputFile.writeAsBytesSync(jpg);

    entries.add({
      'id': spec.id,
      'file': 'assets/anastasis/${spec.output}',
      'source': spec.source,
      'source_width': source.width,
      'source_height': source.height,
      'trim_top': trimTop,
      'trim_bottom': trimBottom,
      'pip_excluded': pipExcluded,
      'width': working.width,
      'height': working.height,
      'bytes': jpg.length,
      'role': spec.role,
      'title': spec.title,
      'caption': spec.caption,
      'credit': spec.credit,
      if (spec.sourceUrl != null) 'source_url': spec.sourceUrl,
    });
    stdout.writeln(
      '${spec.output.padRight(34)} ${working.width}x${working.height} '
      '${(jpg.length / 1024).round()} KiB  [${spec.role}]'
      '${pipExcluded ? ' pip-cropped' : ''}',
    );
  }

  final manifest = {
    'artifact': {
      'id': artifactId,
      'title': artifactTitle,
      'room': artifactRoom,
      'surface': 'apse semi-dome (conch)',
      'source_folder':
          'captures/chora-scenes/5-PAREKKLESION/C__F02__Anastasis__dome__REF-8',
      'prepared_on': preparedOn,
      'prepared_by': preparedBy,
      'texture_file': 'assets/anastasis/conch_reference.jpg',
      'flat_reference_file': 'assets/anastasis/flat_reference.jpg',
      'notes': [
        'Derived from the reference capture folder; letterbox bars from the '
            'capture viewer are trimmed and its picture-in-picture overlay is '
            'cropped away where present.',
        'No pixels are retouched beyond trim, crop, resize and JPEG encode.',
        'The main texture keeps the fresco border band so the reconstructed '
            'field shows its own edge.',
      ],
    },
    'captures': entries,
  };
  final manifestFile = File('$outputFolder/captures.json');
  manifestFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );
  final totalBytes = entries.fold<int>(
    0,
    (sum, e) => sum + (e['bytes'] as int),
  );
  stdout.writeln(
    '\n${entries.length} captures, ${(totalBytes / 1024 / 1024).toStringAsFixed(1)} '
    'MiB total -> $outputFolder',
  );
}

bool _rowIsBar(img.Image image, int y) {
  var max = 0;
  var sum = 0.0;
  for (var x = 0; x < image.width; x++) {
    final p = image.getPixel(x, y);
    final l = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();
    if (l > max) max = l;
    sum += l;
  }
  // The capture viewer letterbox is a dark, near-empty band; real content
  // rows almost always carry something brighter than the threshold.
  return sum / image.width < 52 && max < 88;
}

int _scanBars(img.Image image, {required bool fromTop}) {
  var count = 0;
  for (var i = 0; i < image.height; i++) {
    final y = fromTop ? i : image.height - 1 - i;
    if (!_rowIsBar(image, y)) break;
    count++;
  }
  return count;
}
