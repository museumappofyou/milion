import 'package:flutter/services.dart';

import '../models/scene.dart';
import 'models.dart';
import 'repository.dart';

final bundledContent = ContentRepository(rootBundle.loadString);

/// Compatibility view for the P01 collection and scanner UI. The registry owns
/// every field; remove this adapter when P05 replaces the old scene sheet.
Scene sceneForArtwork(Artwork artwork, {String language = 'en'}) => Scene(
  id: artwork.id,
  title: artwork.title.inLanguage(language),
  room: artwork.room.inLanguage(language),
  surface: artwork.surface.inLanguage(language),
  folder: artwork.folder,
  summary: artwork.summary.inLanguage(language),
  cues: artwork.cues.map((c) => c.inLanguage(language)).toList(growable: false),
  position: artwork.position.inLanguage(language),
  artworkType: artwork.kind.name,
);
