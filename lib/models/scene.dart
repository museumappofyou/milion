class Scene {
  const Scene({
    required this.id,
    required this.title,
    required this.room,
    required this.surface,
    required this.folder,
    this.summary = '',
    this.cues = const [],
    this.position = '',
    this.artworkType = '',
  });

  final String id;
  final String title;
  final String room;
  final String surface;
  final String folder;
  final String summary;
  final List<String> cues;
  final String position;
  final String artworkType;

  String get prettyTitle => title.replaceAll('_', ' ');
}
