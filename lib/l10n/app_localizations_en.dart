// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Milion · Istanbul from mile zero';

  @override
  String get brandName => 'MILION';

  @override
  String get tagline => 'Istanbul from mile zero';

  @override
  String get home => 'Home';

  @override
  String get today => 'Today';

  @override
  String get collection => 'Collection';

  @override
  String get scan => 'Scan';

  @override
  String get about => 'About';

  @override
  String get openAnastasis => 'Open Anastasis';

  @override
  String get anastasis => 'Anastasis';

  @override
  String get judgment => 'The Last Judgment';

  @override
  String get chora => 'Chora / Kariye';

  @override
  String get choraLocation => 'Fatih · Chora / Kariye';

  @override
  String get anastasisHook => 'Christ holds Adam and Eve by the wrist.';

  @override
  String get judgmentHook => 'An angel rolls up the sky like a scroll.';

  @override
  String get original => 'Original';

  @override
  String get depth => 'Depth';

  @override
  String get reconstruction => 'Reconstruction';

  @override
  String get imagined => 'Imagined';

  @override
  String get originalDescription => 'The unchanged source photograph.';

  @override
  String get depthDescription => 'Source pixels with added depth or light.';

  @override
  String get reconstructionDescription =>
      'Added pixels or geometry based on cited evidence.';

  @override
  String get imaginedDescription =>
      'A proposed interpretation, not historical evidence.';

  @override
  String get mileZero => 'Mile zero';

  @override
  String get milionCoordinates => '41.008043° N · 28.978066° E';

  @override
  String get fromMilion => 'From the Milion';

  @override
  String bearing(String degrees) {
    return '$degrees° from true north';
  }

  @override
  String get straightLine => 'Straight-line distance · 1 Roman mile ≈ 1,480 m';

  @override
  String catalogueCount(String count) {
    return '$count artworks · Chora / Kariye';
  }

  @override
  String get viewCollection => 'View collection';

  @override
  String get scanScene => 'Scan a scene';

  @override
  String get aboutCredits => 'About and credits';

  @override
  String get loadingCollection => 'Opening the collection';

  @override
  String get collectionError => 'The collection could not open';

  @override
  String get collectionErrorBody =>
      'The bundled Chora catalogue could not be read. Try again.';

  @override
  String get scannerUnavailable => 'The scanner is unavailable';

  @override
  String get scannerUnavailableBody =>
      'Scene recognition could not start. The collection is available offline.';

  @override
  String get preparingScanner => 'Preparing the scanner';

  @override
  String get preparingScannerBody => 'Loading the 103-artwork Chora model.';

  @override
  String get retry => 'Try again';

  @override
  String get loading => 'Loading';

  @override
  String get searchScenes => 'Search artwork, room or detail';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get allRooms => 'All rooms';

  @override
  String get interactive => 'Interactive';

  @override
  String get noScenes => 'No artworks match';

  @override
  String get noScenesBody => 'Change the search text or room filter.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get hasNote => 'Has a note';

  @override
  String get room => 'Room';

  @override
  String get lookFor => 'Look for';

  @override
  String get where => 'Position';

  @override
  String get yourNote => 'Your note';

  @override
  String get noteHint => 'Write a note about this artwork';

  @override
  String get saveNote => 'Save note';

  @override
  String get saved => 'Saved';

  @override
  String noteSaved(String id) {
    return 'Note saved for $id';
  }

  @override
  String get exploreRelief => 'Open artwork';

  @override
  String modelMatch(String percent) {
    return 'Model match $percent% · unverified';
  }

  @override
  String get contentEnglish =>
      'This artwork’s text is awaiting Turkish review.';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'Device language';

  @override
  String get english => 'English';

  @override
  String get turkish => 'Türkçe';

  @override
  String get appearance => 'Appearance';

  @override
  String get marble => 'Marble';

  @override
  String get lamp => 'Lamp';

  @override
  String get aboutStory =>
      'The Milion marked Constantinople’s mile zero. Its surviving fragment stands on Divanyolu beside the Basilica Cistern. Milion measures Istanbul from that point.';

  @override
  String get aboutRecognition =>
      'The camera suggests matches among 103 Chora artworks. Recognition runs on the device, offline.';

  @override
  String get recognitionLimits => 'Recognition limits';

  @override
  String get recognitionLimitsBody =>
      'Matches are suggestions. The prototype rejected at most 67% of 231 unrelated test images; it cannot confirm an artwork on its own.';

  @override
  String get credits => 'Sources and credits';

  @override
  String get creditsBody =>
      'Chora references: project-owner captures, Wikimedia Commons and Kültür Envanteri. Source URLs are recorded; public-release rights review is pending.';

  @override
  String get licenses => 'Open-source licences';

  @override
  String get version => 'Milion 1.0.0 · 1';

  @override
  String get previewFooter => 'Istanbul collection · Chora preview';

  @override
  String get registry => 'Registry';

  @override
  String get registryError => 'Registry could not load.';

  @override
  String registryCounts(String places, String artworks) {
    return '$places places · $artworks artworks';
  }

  @override
  String draftCounts(String count) {
    return '$count drafts · hidden from public place lists';
  }

  @override
  String get registryMeasurement =>
      'Straight-line distance · Roman miles rounded\n1 mil ≈ 1,480 m · bearings from true north';

  @override
  String get categoryCounts => 'Counts by category';

  @override
  String get districtCounts => 'Counts by district · 39';

  @override
  String get outsideProvince => 'Outside province';

  @override
  String get categoryByzantine => 'Byzantine';

  @override
  String get categoryMosque => 'Mosque';

  @override
  String get categoryMuseum => 'Museum';

  @override
  String get categoryPalace => 'Palace';

  @override
  String get categoryFortification => 'Fortification';

  @override
  String get categoryCistern => 'Cistern';

  @override
  String get categoryTower => 'Tower';

  @override
  String get categoryBazaar => 'Bazaar';

  @override
  String get categoryBath => 'Bath';

  @override
  String get categoryOther => 'Other';

  @override
  String get designSheet => 'Porphyry & Tessera';

  @override
  String get designIntro =>
      'A measuring instrument for Istanbul: distance, depth and light.';

  @override
  String get directionA => 'A · Lamp first';

  @override
  String get directionB => 'B · Marble & porphyry';

  @override
  String get paletteTitle => 'Pigments and surfaces';

  @override
  String get typeTitle => 'Inscriptions and measures';

  @override
  String get componentsTitle => 'Instruments';

  @override
  String get porphyry => 'Porphyry';

  @override
  String get tesseraGold => 'Tessera gold · material & rewards';

  @override
  String get cobalt => 'İznik cobalt';

  @override
  String get bole => 'İznik bole red';

  @override
  String get turquoise => 'Turquoise';

  @override
  String get verdigris => 'Verdigris';

  @override
  String get bronze => 'Bronze';

  @override
  String get gridLabel => '4 dp grid · 2 dp maximum radius · no elevation';

  @override
  String get fontSpecimen =>
      'İstanbul Ayasofya Süleymaniye Eyüpsultan Kılıç Ali Paşa Şehzadebaşı ığüşöçİĞÜŞÖÇ · Η ΑΝΑϹΤΑϹΙϹ ΙϹ ΧϹ · XLVII · 3,4 mil';

  @override
  String get displayRole => 'Cinzel · Greek fallback Noto Serif Display';

  @override
  String get bodyRole => 'Noto Sans · tabular measurements';

  @override
  String get stratumTitle => 'Metochites’ Chora';

  @override
  String get stratumBody =>
      'Mosaic and fresco share the walls, vaults and domes.';

  @override
  String get leaderCaption => 'Adam’s wrist';

  @override
  String get north => 'North';

  @override
  String get northLetter => 'N';

  @override
  String scaleDistance(String metres) {
    return '$metres m';
  }

  @override
  String get dimensionHandle => 'Drag to close sheet';

  @override
  String get sheetTitle => 'Artwork note';

  @override
  String get openSheet => 'Open dimension sheet';

  @override
  String get emptyTitle => 'No saved notes';

  @override
  String get emptyBody => 'Open a Chora artwork and save your first note.';

  @override
  String get errorTitle => 'Artwork image unavailable';

  @override
  String get errorBody =>
      'The image file could not be read. Try loading it again.';

  @override
  String get motionTitle => 'Settle · dig · sweep';

  @override
  String get motionInfo =>
      'Settle · 160 ms · easeOutCubic\nDig · 360 ms · easeInOutCubic\nSweep · 520 ms · easeOutQuart\nReduced motion: immediate state change.';

  @override
  String get hapticDetent => 'Feel a detent';

  @override
  String get hapticCollect => 'Feel collection';

  @override
  String get iconDome => 'Dome';

  @override
  String get iconMinaret => 'Minaret';

  @override
  String get iconColumn => 'Column';

  @override
  String get iconGate => 'Gate';

  @override
  String get iconCistern => 'Cistern';

  @override
  String get iconVitrine => 'Vitrine';

  @override
  String get iconRoute => 'Route';

  @override
  String get iconTessera => 'Tessera';

  @override
  String get iconCameraEye => 'Camera eye';

  @override
  String get iconSound => 'Sound';

  @override
  String get iconLight => 'Light';

  @override
  String get iconLayers => 'Layers';

  @override
  String get iconStory => 'Story';

  @override
  String scalePercent(String percent) {
    return '$percent% text';
  }

  @override
  String milestoneNumber(String numeral) {
    return 'Milestone $numeral';
  }

  @override
  String get measurementTitle => 'Distance from mile zero';

  @override
  String get strataTitle => 'Layers of Chora';

  @override
  String get focusChora => 'Chora · 103 artworks';

  @override
  String get chapterByzantine => 'Byzantine chapter';

  @override
  String get plates => 'Two plates';

  @override
  String get openJudgment => 'Open the Last Judgment';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get resetView => 'Reset view';

  @override
  String get sceneOptions => 'Scene options';

  @override
  String get studies => 'Restoration studies';

  @override
  String get studyUnavailable => 'Restoration study could not be loaded.';

  @override
  String get sceneUnavailable => 'Scene assets unavailable.';

  @override
  String get loadingArtwork => 'Loading artwork';

  @override
  String get overview => 'Overview';

  @override
  String get chooseDetail => 'Choose a detail';

  @override
  String get detailHint =>
      'Pinch to enlarge. Choose a detail to move to its position.';

  @override
  String get detailMarkers => 'Leader lines';

  @override
  String get showMarkers => 'Show leader lines';

  @override
  String get hideMarkers => 'Hide leader lines';

  @override
  String get gestureStudy => 'Gesture study';

  @override
  String get gestureBody =>
      'One gentle, imagined beat. The source photograph stays one tap away.';

  @override
  String get playGesture => 'Play one gesture';

  @override
  String get pauseGesture => 'Pause gesture';

  @override
  String get still => 'Still';

  @override
  String get pose => 'Pose';

  @override
  String get movement => 'Movement';

  @override
  String get gentle => 'Gentle';

  @override
  String get singleGesture => '6 s · once';

  @override
  String get reducedMotionHint =>
      'Automatic motion is off. You can adjust the pose manually.';

  @override
  String gesturePercent(String percent) {
    return '$percent% of gesture';
  }

  @override
  String movementPercent(String percent) {
    return '$percent% movement';
  }

  @override
  String get blend => 'Blend';

  @override
  String get restorationAmount => 'Reconstruction opacity';

  @override
  String get restorationNotice =>
      'Reconstruction · source photograph preserved';

  @override
  String get studyNotice =>
      'Interpretive reconstruction. Facial details are inferred; the source photograph is unchanged.';

  @override
  String get restoredFresco => '4K fresco reconstruction';

  @override
  String get restoredVault => '4K vault reconstruction';

  @override
  String get detailChrist => 'Christ';

  @override
  String get detailAdam => 'Adam';

  @override
  String get detailEve => 'Eve';

  @override
  String get detailLeft => 'Left figures';

  @override
  String get detailRight => 'Right figures';

  @override
  String get detailGates => 'Gates';

  @override
  String get detailDeesis => 'Deesis';

  @override
  String get detailApostles => 'Apostles';

  @override
  String get detailHeavens => 'Heavens';

  @override
  String get detailThrone => 'Throne';

  @override
  String get detailRiver => 'River of fire';

  @override
  String get anastasisChristBody =>
      'The light robe stands against the star-filled mandorla.';

  @override
  String get adamBody => 'Joined hands lead from the tomb toward the centre.';

  @override
  String get eveBody => 'The red robe, bowed face and extended arm mark Eve.';

  @override
  String get leftBody => 'Faces, crowns and halos overlap on the left.';

  @override
  String get rightBody => 'Faces and robe folds meet the painted rock.';

  @override
  String get gatesBody => 'Broken gates lie beneath Christ.';

  @override
  String get judgmentChristBody =>
      'The face and mandorla centre the heavenly court.';

  @override
  String get deesisBody => 'Two standing figures flank the central figure.';

  @override
  String get apostlesBody =>
      'Seated figures hold books beneath overlapping halos.';

  @override
  String get heavensBody => 'An angel carries the circular, rolled-up heavens.';

  @override
  String get throneBody => 'The prepared throne stands above kneeling figures.';

  @override
  String get riverBody =>
      'The red-orange river runs toward the vault’s lower right.';

  @override
  String get noCamera => 'No camera found on this device.';

  @override
  String get cameraError => 'Camera unavailable';

  @override
  String get liveUnavailable =>
      'Live recognition is unavailable on this device.';

  @override
  String get scanFailed =>
      'The image could not be analysed. Try another image.';

  @override
  String get lightFailed => 'The camera light could not be switched.';

  @override
  String get liveOn => 'Live recognition on';

  @override
  String get liveOff => 'Live recognition off';

  @override
  String get pickGallery => 'Pick from gallery';

  @override
  String get gallery => 'Gallery';

  @override
  String get light => 'Light';

  @override
  String get noSceneDetected => 'No scene detected · frame a Chora artwork';

  @override
  String get startCamera => 'Starting the camera';

  @override
  String get cameraGuide => 'Frame a mosaic or fresco';

  @override
  String get analysingScene => 'Analysing the artwork';

  @override
  String get topMatch => 'Top match';

  @override
  String get resultHint => 'Tap a result for details and notes';

  @override
  String get demoResult =>
      'Suggested matches. Compare each result with the artwork before identifying it.';

  @override
  String get scanAgain => 'Scan again';

  @override
  String get localeTr => 'TR';

  @override
  String get localeEn => 'EN';

  @override
  String get waveByzantine => 'Byzantine · gold on porphyry';

  @override
  String get waveMosque => 'Mosques · cobalt / turquoise';

  @override
  String get waveMuseum => 'Museums · verdigris / bronze';

  @override
  String get cameraErrorBody =>
      'Allow camera access in Android settings, then try again. You can also choose a photo from the gallery.';
}
