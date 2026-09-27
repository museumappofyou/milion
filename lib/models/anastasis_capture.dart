/// Data model for the Anastasis 2.5D artifact: the prepared reference
/// captures of scene F02 and the hotspots that anchor interpretations to the
/// reconstructed semi-dome.
library;

class AnastasisArtifact {
  const AnastasisArtifact({
    required this.id,
    required this.title,
    required this.room,
    required this.surface,
    required this.sourceFolder,
    required this.preparedOn,
    required this.preparedBy,
    required this.textureFile,
    required this.flatReferenceFile,
    required this.notes,
    required this.captures,
  });

  final String id;
  final String title;
  final String room;
  final String surface;
  final String sourceFolder;
  final String preparedOn;
  final String preparedBy;
  final String textureFile;
  final String flatReferenceFile;
  final List<String> notes;
  final List<AnastasisCapture> captures;

  AnastasisCapture? captureById(String id) {
    for (final capture in captures) {
      if (capture.id == id) {
        return capture;
      }
    }
    return null;
  }

  static AnastasisArtifact fromJson(Map<String, dynamic> json) {
    final artifact = (json['artifact'] as Map).cast<String, dynamic>();
    final captures = ((json['captures'] as List?) ?? const [])
        .map(
          (entry) =>
              AnastasisCapture.fromJson((entry as Map).cast<String, dynamic>()),
        )
        .toList();
    return AnastasisArtifact(
      id: artifact['id'] as String? ?? '',
      title: artifact['title'] as String? ?? '',
      room: artifact['room'] as String? ?? '',
      surface: artifact['surface'] as String? ?? '',
      sourceFolder: artifact['source_folder'] as String? ?? '',
      preparedOn: artifact['prepared_on'] as String? ?? '',
      preparedBy: artifact['prepared_by'] as String? ?? '',
      textureFile: artifact['texture_file'] as String? ?? '',
      flatReferenceFile: artifact['flat_reference_file'] as String? ?? '',
      notes: ((artifact['notes'] as List?) ?? const []).cast<String>(),
      captures: captures,
    );
  }
}

class AnastasisCapture {
  const AnastasisCapture({
    required this.id,
    required this.file,
    required this.source,
    required this.role,
    required this.title,
    required this.caption,
    required this.credit,
    required this.width,
    required this.height,
    required this.sourceWidth,
    required this.sourceHeight,
    this.sourceUrl,
    this.pipExcluded = false,
  });

  final String id;

  /// Asset path of the prepared image the app displays.
  final String file;

  /// Original file name inside the capture folder.
  final String source;
  final String role;
  final String title;
  final String caption;
  final String credit;
  final String? sourceUrl;
  final int width;
  final int height;
  final int sourceWidth;
  final int sourceHeight;
  final bool pipExcluded;

  bool get isPanelSource => role == 'texture';

  static AnastasisCapture fromJson(Map<String, dynamic> json) {
    return AnastasisCapture(
      id: json['id'] as String? ?? '',
      file: json['file'] as String? ?? '',
      source: json['source'] as String? ?? '',
      role: json['role'] as String? ?? 'capture',
      title: json['title'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      credit: json['credit'] as String? ?? '',
      sourceUrl: json['source_url'] as String?,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      sourceWidth: (json['source_width'] as num?)?.toInt() ?? 0,
      sourceHeight: (json['source_height'] as num?)?.toInt() ?? 0,
      pipExcluded: json['pip_excluded'] as bool? ?? false,
    );
  }
}

/// An interpretation anchored to the reconstructed panel.
class AnastasisHotspot {
  const AnastasisHotspot({
    required this.id,
    required this.label,
    required this.u,
    required this.v,
    required this.captureId,
    required this.detail,
  });

  final String id;
  final String label;

  /// Position in normalized coordinates of the reference capture.
  final double u;
  final double v;

  /// The capture to show when the hotspot is opened.
  final String captureId;

  /// One or two sentences of interpretation.
  final String detail;
}

/// The examinable hotspots of the Anastasis, anchored on the reference
/// capture (normalized coordinates of assets/anastasis/conch_reference.jpg).
const List<AnastasisHotspot> anastasisHotspots = [
  AnastasisHotspot(
    id: 'christ',
    label: 'Christ',
    u: 0.513,
    v: 0.500,
    captureId: 'detail-christ',
    detail:
        'Radiant Christ strides on the shattered gates, the rayed mandorla '
        'behind him, and pulls Adam up by the wrist.',
  ),
  AnastasisHotspot(
    id: 'adam',
    label: 'Adam',
    u: 0.427,
    v: 0.673,
    captureId: 'detail-adam',
    detail:
        'Adam, grey-haired in a pale robe, is drawn out of his sarcophagus '
        'as the raised are gathered.',
  ),
  AnastasisHotspot(
    id: 'eve',
    label: 'Eve',
    u: 0.663,
    v: 0.667,
    captureId: 'detail-eve',
    detail:
        'Eve, in red, rises from her tomb on Christ\u2019s left while the '
        'bound figure of Hades-Satan crouches beneath his hand.',
  ),
  AnastasisHotspot(
    id: 'kings',
    label: 'Kings and prophets',
    u: 0.197,
    v: 0.493,
    captureId: 'detail-kings',
    detail:
        'David and Solomon with the kings and prophets wait at the left end '
        'of the conch, beside the painted arch border.',
  ),
  AnastasisHotspot(
    id: 'righteous',
    label: 'John the Baptist',
    u: 0.700,
    v: 0.480,
    captureId: 'detail-righteous',
    detail:
        'John the Baptist with his thin staff leads the righteous raised from '
        'their tombs at the right end of the conch.',
  ),
  AnastasisHotspot(
    id: 'satan',
    label: 'Satan bound',
    u: 0.573,
    v: 0.793,
    captureId: 'detail-gates-web',
    detail:
        'Hades-Satan lies bound in the dark pit under Christ\u2019s feet, '
        'with the locks, keys and chains of death scattered around.',
  ),
  AnastasisHotspot(
    id: 'gates',
    label: 'Broken gates',
    u: 0.497,
    v: 0.870,
    captureId: 'detail-gates-ref',
    detail:
        'The doors of hell lie broken at the bottom of the panel, their '
        'boards, bolts and keys strewn across the dark ground.',
  ),
];
