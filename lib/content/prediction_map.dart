import 'registry.dart';

/// Model output order is a mapping, never the catalogue order or its source.
class PredictionMap {
  PredictionMap(List<String> ids, ContentRegistry registry)
    : artworkIds = List.unmodifiable(ids) {
    if (ids.isEmpty || ids.toSet().length != ids.length) {
      throw const FormatException(
        'Prediction ids must be non-empty and unique',
      );
    }
    final known = registry.artworks.map((a) => a.id).toSet();
    for (final id in ids) {
      if (!known.contains(id)) {
        throw FormatException('Unknown prediction artwork $id');
      }
    }
  }
  final List<String> artworkIds;
  String artworkIdAt(int index) => artworkIds[index];
}
