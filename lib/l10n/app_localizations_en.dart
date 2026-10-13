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
  String get straightLine =>
      'Straight-line distance · 1 Roman mile is about 1,480 m';

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
      'Chora references: project-owner captures, Wikimedia Commons and Kültür Envanteri. Every image passes a rights review before public release. Coastline and street lines on the dial and in the opening: © OpenStreetMap contributors, ODbL 1.0.';

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
      'Straight-line distance · Roman miles rounded\n1 mil is about 1,480 m · bearings from true north';

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

  @override
  String get navToday => 'Today';

  @override
  String get navCity => 'City';

  @override
  String get navMilestones => 'Milestones';

  @override
  String get navMosaic => 'Mosaic';

  @override
  String get iconDial => 'Mile Zero dial';

  @override
  String get iconMilestone => 'Milestone';

  @override
  String get techDP => 'Depth parallax';

  @override
  String get techGL => 'Gilded light';

  @override
  String get techRL => 'Raking light or candle';

  @override
  String get techPU => 'Pop-up layers';

  @override
  String get techWR => 'Wipe to reconstruction';

  @override
  String get techSB => 'Story beats';

  @override
  String get techMM => 'Micro-motion';

  @override
  String get techSR => 'Stroke reveal';

  @override
  String get techLU => 'Look up';

  @override
  String get techCA => 'Choisy assembly';

  @override
  String get techCS => 'Cutaway section';

  @override
  String get techWK => 'Walkable space';

  @override
  String get techTT => 'Turntable';

  @override
  String get techTM => 'Time model';

  @override
  String get techSK => 'Sky simulation';

  @override
  String get techVO => 'Voices';

  @override
  String techniqueList(String list) {
    return 'Techniques: $list';
  }

  @override
  String get firstRunLine => 'Every road started here.';

  @override
  String get firstRunSentence =>
      'Mile zero: the Milion on Divanyolu, the stone from which the empire measured its roads, with rings in Roman miles reaching Süleymaniye, Galata Tower, Maiden’s Tower, Chora and Yedikule.';

  @override
  String get firstRunStone => 'Divanyolu, beside the Basilica Cistern';

  @override
  String firstRunStill(String number) {
    return 'Still $number of 3';
  }

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get openToday => 'Open Today';

  @override
  String get replayFirstRun => 'Replay mile zero';

  @override
  String get replayFirstRunBody =>
      'The 12-second opening: the Milion, the Roman-mile rings and five places.';

  @override
  String get detailOfDay => 'Detail of the day';

  @override
  String openMilestoneDetail(String numeral) {
    return 'Open $numeral at this detail';
  }

  @override
  String detailSource(String artwork, String place) {
    return '$artwork · $place';
  }

  @override
  String get dialLabel => 'Mile Zero dial';

  @override
  String get dialHint =>
      'Turn the ring: one detent per place. Tap a tick to open it.';

  @override
  String dialValue(String place, String distance, String degrees) {
    return '$place, $distance, $degrees° from true north';
  }

  @override
  String get showList => 'List';

  @override
  String get showDial => 'Dial';

  @override
  String placesByBearing(String count) {
    return '$count places by bearing from true north';
  }

  @override
  String plottedPlaces(String count, String reviewed) {
    return '$count places · positions checked on Wikidata · $reviewed reviewed';
  }

  @override
  String get notReviewed => 'Not reviewed yet';

  @override
  String get reviewed => 'Reviewed';

  @override
  String openPlace(String place) {
    return 'Open $place';
  }

  @override
  String get nextMilestones => 'Next in the register';

  @override
  String chapterHeading(String numeral, String name) {
    return 'Chapter $numeral · $name';
  }

  @override
  String get chapterByzantineName => 'Byzantine';

  @override
  String get chapterMosquesName => 'Mosques';

  @override
  String get chapterMuseumsName => 'Museums';

  @override
  String get chapterAbroadName => 'Istanbul abroad';

  @override
  String get chapterCurrent => 'Current chapter';

  @override
  String chapterProgress(String playable, String total, String approved) {
    return '$playable of $total playable · $approved approved';
  }

  @override
  String get statusPlanned => 'Planned';

  @override
  String get statusPrototype => 'Prototype';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusOpened => 'Opened';

  @override
  String get flagship => 'Flagship';

  @override
  String get craftKit => 'Craft kit';

  @override
  String get acrossCity => 'Across the city';

  @override
  String registerCounts(
    String total,
    String playable,
    String approved,
    String planned,
  ) {
    return '$total Milestones · $playable playable · $approved approved · $planned planned';
  }

  @override
  String get milestonePlannedBody =>
      'Planned: its reveal, story and exploration are not built yet. The empty slot stays outlined until it is.';

  @override
  String get techniques => 'Techniques';

  @override
  String get labelsTitle => 'Labels';

  @override
  String mosaicProgress(String opened, String total) {
    return '$opened of $total Milestones opened';
  }

  @override
  String mosaicNext(String numeral, String title) {
    return 'Next: $numeral · $title';
  }

  @override
  String get mosaicIntro =>
      'One tessera per Milestone. Each one you open is set in gold.';

  @override
  String get notesTitle => 'Your notes';

  @override
  String notesCount(String count) {
    return '$count notes on Chora artworks';
  }

  @override
  String get cityTitle => 'Places by distance from mile zero';

  @override
  String placeDraftBody(String qid, String date) {
    return 'Name and position checked against Wikidata $qid on $date. Story, hours and entrance are not reviewed yet.';
  }

  @override
  String get historicalNames => 'Historical names';

  @override
  String artworksHere(String count) {
    return '$count artworks';
  }

  @override
  String get milestonesHere => 'Milestones here';

  @override
  String get recognise => 'Recognise an artwork with the camera';

  @override
  String get sourcesTitle => 'Sources';

  @override
  String get todayError => 'Today could not open';

  @override
  String get todayErrorBody =>
      'The bundled registry could not be read. Try again.';

  @override
  String get photoOriginal => 'Unaltered photograph';

  @override
  String placeCount(String count) {
    return '$count places';
  }

  @override
  String get eastLetter => 'E';

  @override
  String get southLetter => 'S';

  @override
  String get westLetter => 'W';

  @override
  String honestyRange(String from, String to) {
    return '$from to $to';
  }

  @override
  String get digVisit => 'Visit';

  @override
  String get digHours => 'Hours';

  @override
  String get digEntry => 'Entry';

  @override
  String get digEtiquette => 'Etiquette';

  @override
  String get digAccessibility => 'Accessibility';

  @override
  String get digGettingThere => 'Getting there';

  @override
  String digCheckedOn(String date) {
    return 'Checked $date';
  }

  @override
  String get digNotChecked => 'Not yet field-checked';

  @override
  String get digVisitUnverified => 'Visit facts are not yet field-checked.';

  @override
  String digRemotelyChecked(String date) {
    return 'Checked against published sources on $date.';
  }

  @override
  String digWalkMinutes(String minutes) {
    return 'about $minutes min on foot';
  }

  @override
  String get digReportChange => 'Report a change';

  @override
  String digReportSubject(String place) {
    return 'Milion: a correction for $place';
  }

  @override
  String digReportBody(String place, String qid) {
    return 'Place: $place ($qid)\n\nWhat should change?\n';
  }

  @override
  String digSources(String count) {
    return 'Sources ($count)';
  }

  @override
  String get digLayerArtworks => 'Artworks in this layer';

  @override
  String get digLayerMilestones => 'Enter the Milestones here';

  @override
  String get digGo => 'Go';

  @override
  String get digGoTooltip => 'Open walking directions';

  @override
  String get digDiagram => 'Section diagram — not a photograph';

  @override
  String get digDepthGauge => 'Depth gauge';

  @override
  String get digDepthHint => 'Swipe the rail to move through the years.';

  @override
  String digGaugeYear(String year) {
    return 'Year $year';
  }

  @override
  String get eraAncient => 'Ancient';

  @override
  String get eraRoman => 'Roman';

  @override
  String get eraByzantine => 'Byzantine';

  @override
  String get eraMedieval => 'Medieval';

  @override
  String get eraOttoman => 'Ottoman';

  @override
  String get eraModern => 'Modern';

  @override
  String get placeStatusOpen => 'Open';

  @override
  String get placeStatusClosed => 'Closed';

  @override
  String get placeStatusRestoration => 'Under restoration';

  @override
  String get placeStatusRuin => 'Ruin';

  @override
  String get placeStatusUnknown => 'Status unknown';

  @override
  String placeCheckedOn(String date) {
    return 'Status checked $date';
  }

  @override
  String get placeFunction => 'Current use';

  @override
  String get plateStory => 'Story';

  @override
  String get plateLayers => 'Layers';

  @override
  String get platePlay => 'Play story';

  @override
  String get platePause => 'Pause story';

  @override
  String get platePrevious => 'Previous still';

  @override
  String get plateNext => 'Next still';

  @override
  String get plateTimeline => 'Story position';

  @override
  String get plateGilded => 'Gilded light';

  @override
  String get plateRaking => 'Raking light';

  @override
  String get plateCandle => 'Candle';

  @override
  String get plateNoLight => 'No added light';

  @override
  String get plateGyro => 'Tilt with the phone';

  @override
  String get plateGyroHint =>
      'Off until you choose it. Touch the artwork to recenter.';

  @override
  String get plateGyroUnavailable =>
      'No gyroscope reading. Drag the artwork to tilt.';

  @override
  String get plateDragHint => 'Drag to tilt; pinch to zoom.';

  @override
  String get plateRakingHint => 'Drag the light across the paint.';

  @override
  String get plateCandleHint => 'Hold the warm light under your finger.';

  @override
  String get plateWipeHint =>
      'Drag to reveal reconstruction in damaged areas. Hold to see the original.';

  @override
  String get plateOriginalHint => 'Tap the label to return to the original.';

  @override
  String get platePaintMotion => 'River of fire';

  @override
  String get plateScrollMotion => 'Scroll of heaven';

  @override
  String get plateStillHint =>
      'Motion is off. Use Next and Previous to read the same story as stills.';

  @override
  String get plateMotionCaption =>
      'One imagined wrist-grip gesture; the photograph is one tap away.';

  @override
  String get plateDebug => 'Gesture and rendering study';

  @override
  String get plateClose => 'Close controls';

  @override
  String get plateDetails => 'Details in the photograph';

  @override
  String get plateReveal => '10-second reveal';

  @override
  String get plateExplore => 'Explore the plate';

  @override
  String get plateStartReveal => 'Play reveal';

  @override
  String get plateSources => 'Sources and photograph';

  @override
  String get plateLoading => 'Preparing the plate';

  @override
  String get plateLookUp => 'Look up';

  @override
  String get plateLookUpHint =>
      'Drag to look around the dome, pinch to zoom, double-tap to return to the top.';

  @override
  String get plateLookUpSensor => 'Hold the phone overhead';

  @override
  String get plateLookUpSensorHint =>
      'Off until you choose it. The view follows the phone\'s rotation sensor.';

  @override
  String get plateUnavailable => 'The plate’s images could not be loaded.';

  @override
  String get spaceAssemble => 'Assemble';

  @override
  String get spaceSection => 'Section';

  @override
  String get spaceStyle => 'Style';

  @override
  String get spaceStyleDrawing => 'Drawing';

  @override
  String get spaceStyleStone => 'Stone';

  @override
  String get spaceStyleNight => 'Night';

  @override
  String get spacePlay => 'Play the assembly';

  @override
  String get spaceAssembly => 'Assembly, step by step';

  @override
  String spaceAssemblyValue(String done, String total) {
    return '$done of $total steps';
  }

  @override
  String get spaceExplode => 'Exploded view';

  @override
  String get spaceTime => 'Time';

  @override
  String get spaceSteps => 'Steps';

  @override
  String get spaceSectionPlane => 'Section plane';

  @override
  String get spaceSectionHint =>
      'Drag the handle on the drawing to move the cut; the half facing you is removed.';

  @override
  String get spaceSectionHandle => 'Section plane handle';

  @override
  String get spaceCutPlan => 'Plan cut';

  @override
  String get spaceCutNorthSouth => 'North–south cut';

  @override
  String get spaceCutEastWest => 'East–west cut';

  @override
  String spaceMetres(String value) {
    return '$value m';
  }

  @override
  String get spaceChoisy => 'Choisy’s view from below';

  @override
  String get spaceChoisyHint =>
      'Auguste Choisy drew vaults this way in 1899: from below, with the plan cut.';

  @override
  String get spacePerspective => 'Perspective';

  @override
  String get spaceGestureHint =>
      'Drag to turn, pinch to zoom, move with two fingers, double-tap for Choisy’s view.';

  @override
  String get spaceSources => 'Sources';

  @override
  String get spaceLoading => 'Preparing the drawing';

  @override
  String get spaceUnavailable => 'The drawing’s model could not be loaded.';

  @override
  String get digLayerStudies => 'Studies in this layer';
}
