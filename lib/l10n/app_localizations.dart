import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Milion · Istanbul from mile zero'**
  String get appTitle;

  /// No description provided for @brandName.
  ///
  /// In en, this message translates to:
  /// **'MILION'**
  String get brandName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Istanbul from mile zero'**
  String get tagline;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @collection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get collection;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @openAnastasis.
  ///
  /// In en, this message translates to:
  /// **'Open Anastasis'**
  String get openAnastasis;

  /// No description provided for @anastasis.
  ///
  /// In en, this message translates to:
  /// **'Anastasis'**
  String get anastasis;

  /// No description provided for @judgment.
  ///
  /// In en, this message translates to:
  /// **'The Last Judgment'**
  String get judgment;

  /// No description provided for @chora.
  ///
  /// In en, this message translates to:
  /// **'Chora / Kariye'**
  String get chora;

  /// No description provided for @choraLocation.
  ///
  /// In en, this message translates to:
  /// **'Fatih · Chora / Kariye'**
  String get choraLocation;

  /// No description provided for @anastasisHook.
  ///
  /// In en, this message translates to:
  /// **'Christ holds Adam and Eve by the wrist.'**
  String get anastasisHook;

  /// No description provided for @judgmentHook.
  ///
  /// In en, this message translates to:
  /// **'An angel rolls up the sky like a scroll.'**
  String get judgmentHook;

  /// No description provided for @original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get original;

  /// No description provided for @depth.
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get depth;

  /// No description provided for @reconstruction.
  ///
  /// In en, this message translates to:
  /// **'Reconstruction'**
  String get reconstruction;

  /// No description provided for @imagined.
  ///
  /// In en, this message translates to:
  /// **'Imagined'**
  String get imagined;

  /// No description provided for @originalDescription.
  ///
  /// In en, this message translates to:
  /// **'The unchanged source photograph.'**
  String get originalDescription;

  /// No description provided for @depthDescription.
  ///
  /// In en, this message translates to:
  /// **'Source pixels with added depth or light.'**
  String get depthDescription;

  /// No description provided for @reconstructionDescription.
  ///
  /// In en, this message translates to:
  /// **'Added pixels or geometry based on cited evidence.'**
  String get reconstructionDescription;

  /// No description provided for @imaginedDescription.
  ///
  /// In en, this message translates to:
  /// **'A proposed interpretation, not historical evidence.'**
  String get imaginedDescription;

  /// No description provided for @mileZero.
  ///
  /// In en, this message translates to:
  /// **'Mile zero'**
  String get mileZero;

  /// No description provided for @milionCoordinates.
  ///
  /// In en, this message translates to:
  /// **'41.008043° N · 28.978066° E'**
  String get milionCoordinates;

  /// No description provided for @fromMilion.
  ///
  /// In en, this message translates to:
  /// **'From the Milion'**
  String get fromMilion;

  /// No description provided for @bearing.
  ///
  /// In en, this message translates to:
  /// **'{degrees}° from true north'**
  String bearing(String degrees);

  /// No description provided for @straightLine.
  ///
  /// In en, this message translates to:
  /// **'Straight-line distance · 1 Roman mile is about 1,480 m'**
  String get straightLine;

  /// No description provided for @catalogueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} artworks · Chora / Kariye'**
  String catalogueCount(String count);

  /// No description provided for @viewCollection.
  ///
  /// In en, this message translates to:
  /// **'View collection'**
  String get viewCollection;

  /// No description provided for @scanScene.
  ///
  /// In en, this message translates to:
  /// **'Scan a scene'**
  String get scanScene;

  /// No description provided for @aboutCredits.
  ///
  /// In en, this message translates to:
  /// **'About and credits'**
  String get aboutCredits;

  /// No description provided for @loadingCollection.
  ///
  /// In en, this message translates to:
  /// **'Opening the collection'**
  String get loadingCollection;

  /// No description provided for @collectionError.
  ///
  /// In en, this message translates to:
  /// **'The collection could not open'**
  String get collectionError;

  /// No description provided for @collectionErrorBody.
  ///
  /// In en, this message translates to:
  /// **'The bundled Chora catalogue could not be read. Try again.'**
  String get collectionErrorBody;

  /// No description provided for @scannerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The scanner is unavailable'**
  String get scannerUnavailable;

  /// No description provided for @scannerUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Scene recognition could not start. The collection is available offline.'**
  String get scannerUnavailableBody;

  /// No description provided for @preparingScanner.
  ///
  /// In en, this message translates to:
  /// **'Preparing the scanner'**
  String get preparingScanner;

  /// No description provided for @preparingScannerBody.
  ///
  /// In en, this message translates to:
  /// **'Loading the 103-artwork Chora model.'**
  String get preparingScannerBody;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @searchScenes.
  ///
  /// In en, this message translates to:
  /// **'Search artwork, room or detail'**
  String get searchScenes;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @allRooms.
  ///
  /// In en, this message translates to:
  /// **'All rooms'**
  String get allRooms;

  /// No description provided for @interactive.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get interactive;

  /// No description provided for @noScenes.
  ///
  /// In en, this message translates to:
  /// **'No artworks match'**
  String get noScenes;

  /// No description provided for @noScenesBody.
  ///
  /// In en, this message translates to:
  /// **'Change the search text or room filter.'**
  String get noScenesBody;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @hasNote.
  ///
  /// In en, this message translates to:
  /// **'Has a note'**
  String get hasNote;

  /// No description provided for @room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get room;

  /// No description provided for @lookFor.
  ///
  /// In en, this message translates to:
  /// **'Look for'**
  String get lookFor;

  /// No description provided for @where.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get where;

  /// No description provided for @yourNote.
  ///
  /// In en, this message translates to:
  /// **'Your note'**
  String get yourNote;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Write a note about this artwork'**
  String get noteHint;

  /// No description provided for @saveNote.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get saveNote;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved for {id}'**
  String noteSaved(String id);

  /// No description provided for @exploreRelief.
  ///
  /// In en, this message translates to:
  /// **'Open artwork'**
  String get exploreRelief;

  /// No description provided for @modelMatch.
  ///
  /// In en, this message translates to:
  /// **'Model match {percent}% · unverified'**
  String modelMatch(String percent);

  /// No description provided for @contentEnglish.
  ///
  /// In en, this message translates to:
  /// **'This artwork’s text is awaiting Turkish review.'**
  String get contentEnglish;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get systemLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @marble.
  ///
  /// In en, this message translates to:
  /// **'Marble'**
  String get marble;

  /// No description provided for @lamp.
  ///
  /// In en, this message translates to:
  /// **'Lamp'**
  String get lamp;

  /// No description provided for @aboutStory.
  ///
  /// In en, this message translates to:
  /// **'The Milion marked Constantinople’s mile zero. Its surviving fragment stands on Divanyolu beside the Basilica Cistern. Milion measures Istanbul from that point.'**
  String get aboutStory;

  /// No description provided for @aboutRecognition.
  ///
  /// In en, this message translates to:
  /// **'The camera suggests matches among 103 Chora artworks. Recognition runs on the device, offline.'**
  String get aboutRecognition;

  /// No description provided for @recognitionLimits.
  ///
  /// In en, this message translates to:
  /// **'Recognition limits'**
  String get recognitionLimits;

  /// No description provided for @recognitionLimitsBody.
  ///
  /// In en, this message translates to:
  /// **'Matches are suggestions. The prototype rejected at most 67% of 231 unrelated test images; it cannot confirm an artwork on its own.'**
  String get recognitionLimitsBody;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Sources and credits'**
  String get credits;

  /// No description provided for @creditsBody.
  ///
  /// In en, this message translates to:
  /// **'Chora references: project-owner captures, Wikimedia Commons and Kültür Envanteri. Every image passes a rights review before public release. Coastline and street lines on the dial and in the opening: © OpenStreetMap contributors, ODbL 1.0.'**
  String get creditsBody;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get licenses;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Milion 1.0.0 · 1'**
  String get version;

  /// No description provided for @previewFooter.
  ///
  /// In en, this message translates to:
  /// **'Istanbul collection · Chora preview'**
  String get previewFooter;

  /// No description provided for @registry.
  ///
  /// In en, this message translates to:
  /// **'Registry'**
  String get registry;

  /// No description provided for @registryError.
  ///
  /// In en, this message translates to:
  /// **'Registry could not load.'**
  String get registryError;

  /// No description provided for @registryCounts.
  ///
  /// In en, this message translates to:
  /// **'{places} places · {artworks} artworks'**
  String registryCounts(String places, String artworks);

  /// No description provided for @draftCounts.
  ///
  /// In en, this message translates to:
  /// **'{count} drafts · hidden from public place lists'**
  String draftCounts(String count);

  /// No description provided for @registryMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Straight-line distance · Roman miles rounded\n1 mil is about 1,480 m · bearings from true north'**
  String get registryMeasurement;

  /// No description provided for @categoryCounts.
  ///
  /// In en, this message translates to:
  /// **'Counts by category'**
  String get categoryCounts;

  /// No description provided for @districtCounts.
  ///
  /// In en, this message translates to:
  /// **'Counts by district · 39'**
  String get districtCounts;

  /// No description provided for @outsideProvince.
  ///
  /// In en, this message translates to:
  /// **'Outside province'**
  String get outsideProvince;

  /// No description provided for @categoryByzantine.
  ///
  /// In en, this message translates to:
  /// **'Byzantine'**
  String get categoryByzantine;

  /// No description provided for @categoryMosque.
  ///
  /// In en, this message translates to:
  /// **'Mosque'**
  String get categoryMosque;

  /// No description provided for @categoryMuseum.
  ///
  /// In en, this message translates to:
  /// **'Museum'**
  String get categoryMuseum;

  /// No description provided for @categoryPalace.
  ///
  /// In en, this message translates to:
  /// **'Palace'**
  String get categoryPalace;

  /// No description provided for @categoryFortification.
  ///
  /// In en, this message translates to:
  /// **'Fortification'**
  String get categoryFortification;

  /// No description provided for @categoryCistern.
  ///
  /// In en, this message translates to:
  /// **'Cistern'**
  String get categoryCistern;

  /// No description provided for @categoryTower.
  ///
  /// In en, this message translates to:
  /// **'Tower'**
  String get categoryTower;

  /// No description provided for @categoryBazaar.
  ///
  /// In en, this message translates to:
  /// **'Bazaar'**
  String get categoryBazaar;

  /// No description provided for @categoryBath.
  ///
  /// In en, this message translates to:
  /// **'Bath'**
  String get categoryBath;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @designSheet.
  ///
  /// In en, this message translates to:
  /// **'Porphyry & Tessera'**
  String get designSheet;

  /// No description provided for @designIntro.
  ///
  /// In en, this message translates to:
  /// **'A measuring instrument for Istanbul: distance, depth and light.'**
  String get designIntro;

  /// No description provided for @directionA.
  ///
  /// In en, this message translates to:
  /// **'A · Lamp first'**
  String get directionA;

  /// No description provided for @directionB.
  ///
  /// In en, this message translates to:
  /// **'B · Marble & porphyry'**
  String get directionB;

  /// No description provided for @paletteTitle.
  ///
  /// In en, this message translates to:
  /// **'Pigments and surfaces'**
  String get paletteTitle;

  /// No description provided for @typeTitle.
  ///
  /// In en, this message translates to:
  /// **'Inscriptions and measures'**
  String get typeTitle;

  /// No description provided for @componentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Instruments'**
  String get componentsTitle;

  /// No description provided for @porphyry.
  ///
  /// In en, this message translates to:
  /// **'Porphyry'**
  String get porphyry;

  /// No description provided for @tesseraGold.
  ///
  /// In en, this message translates to:
  /// **'Tessera gold · material & rewards'**
  String get tesseraGold;

  /// No description provided for @cobalt.
  ///
  /// In en, this message translates to:
  /// **'İznik cobalt'**
  String get cobalt;

  /// No description provided for @bole.
  ///
  /// In en, this message translates to:
  /// **'İznik bole red'**
  String get bole;

  /// No description provided for @turquoise.
  ///
  /// In en, this message translates to:
  /// **'Turquoise'**
  String get turquoise;

  /// No description provided for @verdigris.
  ///
  /// In en, this message translates to:
  /// **'Verdigris'**
  String get verdigris;

  /// No description provided for @bronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get bronze;

  /// No description provided for @gridLabel.
  ///
  /// In en, this message translates to:
  /// **'4 dp grid · 2 dp maximum radius · no elevation'**
  String get gridLabel;

  /// No description provided for @fontSpecimen.
  ///
  /// In en, this message translates to:
  /// **'İstanbul Ayasofya Süleymaniye Eyüpsultan Kılıç Ali Paşa Şehzadebaşı ığüşöçİĞÜŞÖÇ · Η ΑΝΑϹΤΑϹΙϹ ΙϹ ΧϹ · XLVII · 3,4 mil'**
  String get fontSpecimen;

  /// No description provided for @displayRole.
  ///
  /// In en, this message translates to:
  /// **'Cinzel · Greek fallback Noto Serif Display'**
  String get displayRole;

  /// No description provided for @bodyRole.
  ///
  /// In en, this message translates to:
  /// **'Noto Sans · tabular measurements'**
  String get bodyRole;

  /// No description provided for @stratumTitle.
  ///
  /// In en, this message translates to:
  /// **'Metochites’ Chora'**
  String get stratumTitle;

  /// No description provided for @stratumBody.
  ///
  /// In en, this message translates to:
  /// **'Mosaic and fresco share the walls, vaults and domes.'**
  String get stratumBody;

  /// No description provided for @leaderCaption.
  ///
  /// In en, this message translates to:
  /// **'Adam’s wrist'**
  String get leaderCaption;

  /// No description provided for @north.
  ///
  /// In en, this message translates to:
  /// **'North'**
  String get north;

  /// No description provided for @northLetter.
  ///
  /// In en, this message translates to:
  /// **'N'**
  String get northLetter;

  /// No description provided for @scaleDistance.
  ///
  /// In en, this message translates to:
  /// **'{metres} m'**
  String scaleDistance(String metres);

  /// No description provided for @dimensionHandle.
  ///
  /// In en, this message translates to:
  /// **'Drag to close sheet'**
  String get dimensionHandle;

  /// No description provided for @sheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Artwork note'**
  String get sheetTitle;

  /// No description provided for @openSheet.
  ///
  /// In en, this message translates to:
  /// **'Open dimension sheet'**
  String get openSheet;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved notes'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Open a Chora artwork and save your first note.'**
  String get emptyBody;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Artwork image unavailable'**
  String get errorTitle;

  /// No description provided for @errorBody.
  ///
  /// In en, this message translates to:
  /// **'The image file could not be read. Try loading it again.'**
  String get errorBody;

  /// No description provided for @motionTitle.
  ///
  /// In en, this message translates to:
  /// **'Settle · dig · sweep'**
  String get motionTitle;

  /// No description provided for @motionInfo.
  ///
  /// In en, this message translates to:
  /// **'Settle · 160 ms · easeOutCubic\nDig · 360 ms · easeInOutCubic\nSweep · 520 ms · easeOutQuart\nReduced motion: immediate state change.'**
  String get motionInfo;

  /// No description provided for @hapticDetent.
  ///
  /// In en, this message translates to:
  /// **'Feel a detent'**
  String get hapticDetent;

  /// No description provided for @hapticCollect.
  ///
  /// In en, this message translates to:
  /// **'Feel collection'**
  String get hapticCollect;

  /// No description provided for @iconDome.
  ///
  /// In en, this message translates to:
  /// **'Dome'**
  String get iconDome;

  /// No description provided for @iconMinaret.
  ///
  /// In en, this message translates to:
  /// **'Minaret'**
  String get iconMinaret;

  /// No description provided for @iconColumn.
  ///
  /// In en, this message translates to:
  /// **'Column'**
  String get iconColumn;

  /// No description provided for @iconGate.
  ///
  /// In en, this message translates to:
  /// **'Gate'**
  String get iconGate;

  /// No description provided for @iconCistern.
  ///
  /// In en, this message translates to:
  /// **'Cistern'**
  String get iconCistern;

  /// No description provided for @iconVitrine.
  ///
  /// In en, this message translates to:
  /// **'Vitrine'**
  String get iconVitrine;

  /// No description provided for @iconRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get iconRoute;

  /// No description provided for @iconTessera.
  ///
  /// In en, this message translates to:
  /// **'Tessera'**
  String get iconTessera;

  /// No description provided for @iconCameraEye.
  ///
  /// In en, this message translates to:
  /// **'Camera eye'**
  String get iconCameraEye;

  /// No description provided for @iconSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get iconSound;

  /// No description provided for @iconLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get iconLight;

  /// No description provided for @iconLayers.
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get iconLayers;

  /// No description provided for @iconStory.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get iconStory;

  /// No description provided for @scalePercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% text'**
  String scalePercent(String percent);

  /// No description provided for @milestoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Milestone {numeral}'**
  String milestoneNumber(String numeral);

  /// No description provided for @measurementTitle.
  ///
  /// In en, this message translates to:
  /// **'Distance from mile zero'**
  String get measurementTitle;

  /// No description provided for @strataTitle.
  ///
  /// In en, this message translates to:
  /// **'Layers of Chora'**
  String get strataTitle;

  /// No description provided for @focusChora.
  ///
  /// In en, this message translates to:
  /// **'Chora · 103 artworks'**
  String get focusChora;

  /// No description provided for @chapterByzantine.
  ///
  /// In en, this message translates to:
  /// **'Byzantine chapter'**
  String get chapterByzantine;

  /// No description provided for @plates.
  ///
  /// In en, this message translates to:
  /// **'Two plates'**
  String get plates;

  /// No description provided for @openJudgment.
  ///
  /// In en, this message translates to:
  /// **'Open the Last Judgment'**
  String get openJudgment;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @resetView.
  ///
  /// In en, this message translates to:
  /// **'Reset view'**
  String get resetView;

  /// No description provided for @sceneOptions.
  ///
  /// In en, this message translates to:
  /// **'Scene options'**
  String get sceneOptions;

  /// No description provided for @studies.
  ///
  /// In en, this message translates to:
  /// **'Restoration studies'**
  String get studies;

  /// No description provided for @sceneUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Scene assets unavailable.'**
  String get sceneUnavailable;

  /// No description provided for @loadingArtwork.
  ///
  /// In en, this message translates to:
  /// **'Loading artwork'**
  String get loadingArtwork;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @chooseDetail.
  ///
  /// In en, this message translates to:
  /// **'Choose a detail'**
  String get chooseDetail;

  /// No description provided for @detailHint.
  ///
  /// In en, this message translates to:
  /// **'Pinch to enlarge. Choose a detail to move to its position.'**
  String get detailHint;

  /// No description provided for @detailMarkers.
  ///
  /// In en, this message translates to:
  /// **'Leader lines'**
  String get detailMarkers;

  /// No description provided for @showMarkers.
  ///
  /// In en, this message translates to:
  /// **'Show leader lines'**
  String get showMarkers;

  /// No description provided for @hideMarkers.
  ///
  /// In en, this message translates to:
  /// **'Hide leader lines'**
  String get hideMarkers;

  /// No description provided for @gestureStudy.
  ///
  /// In en, this message translates to:
  /// **'Gesture study'**
  String get gestureStudy;

  /// No description provided for @gestureBody.
  ///
  /// In en, this message translates to:
  /// **'One gentle, imagined beat. The source photograph stays one tap away.'**
  String get gestureBody;

  /// No description provided for @playGesture.
  ///
  /// In en, this message translates to:
  /// **'Play one gesture'**
  String get playGesture;

  /// No description provided for @pauseGesture.
  ///
  /// In en, this message translates to:
  /// **'Pause gesture'**
  String get pauseGesture;

  /// No description provided for @still.
  ///
  /// In en, this message translates to:
  /// **'Still'**
  String get still;

  /// No description provided for @pose.
  ///
  /// In en, this message translates to:
  /// **'Pose'**
  String get pose;

  /// No description provided for @movement.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get movement;

  /// No description provided for @gentle.
  ///
  /// In en, this message translates to:
  /// **'Gentle'**
  String get gentle;

  /// No description provided for @singleGesture.
  ///
  /// In en, this message translates to:
  /// **'6 s · once'**
  String get singleGesture;

  /// No description provided for @reducedMotionHint.
  ///
  /// In en, this message translates to:
  /// **'Automatic motion is off. You can adjust the pose manually.'**
  String get reducedMotionHint;

  /// No description provided for @gesturePercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of gesture'**
  String gesturePercent(String percent);

  /// No description provided for @movementPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% movement'**
  String movementPercent(String percent);

  /// No description provided for @blend.
  ///
  /// In en, this message translates to:
  /// **'Blend'**
  String get blend;

  /// No description provided for @restorationAmount.
  ///
  /// In en, this message translates to:
  /// **'Reconstruction opacity'**
  String get restorationAmount;

  /// No description provided for @restorationNotice.
  ///
  /// In en, this message translates to:
  /// **'Reconstruction · source photograph preserved'**
  String get restorationNotice;

  /// No description provided for @studyNotice.
  ///
  /// In en, this message translates to:
  /// **'Interpretive reconstruction. Facial details are inferred; the source photograph is unchanged.'**
  String get studyNotice;

  /// No description provided for @restoredFresco.
  ///
  /// In en, this message translates to:
  /// **'4K fresco reconstruction'**
  String get restoredFresco;

  /// No description provided for @restoredVault.
  ///
  /// In en, this message translates to:
  /// **'4K vault reconstruction'**
  String get restoredVault;

  /// No description provided for @detailChrist.
  ///
  /// In en, this message translates to:
  /// **'Christ'**
  String get detailChrist;

  /// No description provided for @detailAdam.
  ///
  /// In en, this message translates to:
  /// **'Adam'**
  String get detailAdam;

  /// No description provided for @detailEve.
  ///
  /// In en, this message translates to:
  /// **'Eve'**
  String get detailEve;

  /// No description provided for @detailLeft.
  ///
  /// In en, this message translates to:
  /// **'Left figures'**
  String get detailLeft;

  /// No description provided for @detailRight.
  ///
  /// In en, this message translates to:
  /// **'Right figures'**
  String get detailRight;

  /// No description provided for @detailGates.
  ///
  /// In en, this message translates to:
  /// **'Gates'**
  String get detailGates;

  /// No description provided for @detailDeesis.
  ///
  /// In en, this message translates to:
  /// **'Deesis'**
  String get detailDeesis;

  /// No description provided for @detailApostles.
  ///
  /// In en, this message translates to:
  /// **'Apostles'**
  String get detailApostles;

  /// No description provided for @detailHeavens.
  ///
  /// In en, this message translates to:
  /// **'Heavens'**
  String get detailHeavens;

  /// No description provided for @detailThrone.
  ///
  /// In en, this message translates to:
  /// **'Throne'**
  String get detailThrone;

  /// No description provided for @detailRiver.
  ///
  /// In en, this message translates to:
  /// **'River of fire'**
  String get detailRiver;

  /// No description provided for @anastasisChristBody.
  ///
  /// In en, this message translates to:
  /// **'The light robe stands against the star-filled mandorla.'**
  String get anastasisChristBody;

  /// No description provided for @adamBody.
  ///
  /// In en, this message translates to:
  /// **'Joined hands lead from the tomb toward the centre.'**
  String get adamBody;

  /// No description provided for @eveBody.
  ///
  /// In en, this message translates to:
  /// **'The red robe, bowed face and extended arm mark Eve.'**
  String get eveBody;

  /// No description provided for @leftBody.
  ///
  /// In en, this message translates to:
  /// **'Faces, crowns and halos overlap on the left.'**
  String get leftBody;

  /// No description provided for @rightBody.
  ///
  /// In en, this message translates to:
  /// **'Faces and robe folds meet the painted rock.'**
  String get rightBody;

  /// No description provided for @gatesBody.
  ///
  /// In en, this message translates to:
  /// **'Broken gates lie beneath Christ.'**
  String get gatesBody;

  /// No description provided for @judgmentChristBody.
  ///
  /// In en, this message translates to:
  /// **'The face and mandorla centre the heavenly court.'**
  String get judgmentChristBody;

  /// No description provided for @deesisBody.
  ///
  /// In en, this message translates to:
  /// **'Two standing figures flank the central figure.'**
  String get deesisBody;

  /// No description provided for @apostlesBody.
  ///
  /// In en, this message translates to:
  /// **'Seated figures hold books beneath overlapping halos.'**
  String get apostlesBody;

  /// No description provided for @heavensBody.
  ///
  /// In en, this message translates to:
  /// **'An angel carries the circular, rolled-up heavens.'**
  String get heavensBody;

  /// No description provided for @throneBody.
  ///
  /// In en, this message translates to:
  /// **'The prepared throne stands above kneeling figures.'**
  String get throneBody;

  /// No description provided for @riverBody.
  ///
  /// In en, this message translates to:
  /// **'The red-orange river runs toward the vault’s lower right.'**
  String get riverBody;

  /// No description provided for @noCamera.
  ///
  /// In en, this message translates to:
  /// **'No camera found on this device.'**
  String get noCamera;

  /// No description provided for @cameraError.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get cameraError;

  /// No description provided for @liveUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live recognition is unavailable on this device.'**
  String get liveUnavailable;

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'The image could not be analysed. Try another image.'**
  String get scanFailed;

  /// No description provided for @lightFailed.
  ///
  /// In en, this message translates to:
  /// **'The camera light could not be switched.'**
  String get lightFailed;

  /// No description provided for @liveOn.
  ///
  /// In en, this message translates to:
  /// **'Live recognition on'**
  String get liveOn;

  /// No description provided for @liveOff.
  ///
  /// In en, this message translates to:
  /// **'Live recognition off'**
  String get liveOff;

  /// No description provided for @pickGallery.
  ///
  /// In en, this message translates to:
  /// **'Pick from gallery'**
  String get pickGallery;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @noSceneDetected.
  ///
  /// In en, this message translates to:
  /// **'No scene detected · frame a Chora artwork'**
  String get noSceneDetected;

  /// No description provided for @startCamera.
  ///
  /// In en, this message translates to:
  /// **'Starting the camera'**
  String get startCamera;

  /// No description provided for @cameraGuide.
  ///
  /// In en, this message translates to:
  /// **'Frame a mosaic or fresco'**
  String get cameraGuide;

  /// No description provided for @analysingScene.
  ///
  /// In en, this message translates to:
  /// **'Analysing the artwork'**
  String get analysingScene;

  /// No description provided for @topMatch.
  ///
  /// In en, this message translates to:
  /// **'Top match'**
  String get topMatch;

  /// No description provided for @resultHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a result for details and notes'**
  String get resultHint;

  /// No description provided for @demoResult.
  ///
  /// In en, this message translates to:
  /// **'Suggested matches. Compare each result with the artwork before identifying it.'**
  String get demoResult;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get scanAgain;

  /// No description provided for @localeTr.
  ///
  /// In en, this message translates to:
  /// **'TR'**
  String get localeTr;

  /// No description provided for @localeEn.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get localeEn;

  /// No description provided for @waveByzantine.
  ///
  /// In en, this message translates to:
  /// **'Byzantine · gold on porphyry'**
  String get waveByzantine;

  /// No description provided for @waveMosque.
  ///
  /// In en, this message translates to:
  /// **'Mosques · cobalt / turquoise'**
  String get waveMosque;

  /// No description provided for @waveMuseum.
  ///
  /// In en, this message translates to:
  /// **'Museums · verdigris / bronze'**
  String get waveMuseum;

  /// No description provided for @cameraErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access in Android settings, then try again. You can also choose a photo from the gallery.'**
  String get cameraErrorBody;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get navCity;

  /// No description provided for @navMilestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get navMilestones;

  /// No description provided for @navMosaic.
  ///
  /// In en, this message translates to:
  /// **'Mosaic'**
  String get navMosaic;

  /// No description provided for @iconDial.
  ///
  /// In en, this message translates to:
  /// **'Mile Zero dial'**
  String get iconDial;

  /// No description provided for @iconMilestone.
  ///
  /// In en, this message translates to:
  /// **'Milestone'**
  String get iconMilestone;

  /// No description provided for @techDP.
  ///
  /// In en, this message translates to:
  /// **'Depth parallax'**
  String get techDP;

  /// No description provided for @techGL.
  ///
  /// In en, this message translates to:
  /// **'Gilded light'**
  String get techGL;

  /// No description provided for @techRL.
  ///
  /// In en, this message translates to:
  /// **'Raking light or candle'**
  String get techRL;

  /// No description provided for @techPU.
  ///
  /// In en, this message translates to:
  /// **'Pop-up layers'**
  String get techPU;

  /// No description provided for @techWR.
  ///
  /// In en, this message translates to:
  /// **'Wipe to reconstruction'**
  String get techWR;

  /// No description provided for @techSB.
  ///
  /// In en, this message translates to:
  /// **'Story beats'**
  String get techSB;

  /// No description provided for @techMM.
  ///
  /// In en, this message translates to:
  /// **'Micro-motion'**
  String get techMM;

  /// No description provided for @techSR.
  ///
  /// In en, this message translates to:
  /// **'Stroke reveal'**
  String get techSR;

  /// No description provided for @techLU.
  ///
  /// In en, this message translates to:
  /// **'Look up'**
  String get techLU;

  /// No description provided for @techCA.
  ///
  /// In en, this message translates to:
  /// **'Choisy assembly'**
  String get techCA;

  /// No description provided for @techCS.
  ///
  /// In en, this message translates to:
  /// **'Cutaway section'**
  String get techCS;

  /// No description provided for @techWK.
  ///
  /// In en, this message translates to:
  /// **'Walkable space'**
  String get techWK;

  /// No description provided for @techTT.
  ///
  /// In en, this message translates to:
  /// **'Turntable'**
  String get techTT;

  /// No description provided for @techTM.
  ///
  /// In en, this message translates to:
  /// **'Time model'**
  String get techTM;

  /// No description provided for @techSK.
  ///
  /// In en, this message translates to:
  /// **'Sky simulation'**
  String get techSK;

  /// No description provided for @techVO.
  ///
  /// In en, this message translates to:
  /// **'Voices'**
  String get techVO;

  /// No description provided for @techniqueList.
  ///
  /// In en, this message translates to:
  /// **'Techniques: {list}'**
  String techniqueList(String list);

  /// No description provided for @firstRunLine.
  ///
  /// In en, this message translates to:
  /// **'Every road started here.'**
  String get firstRunLine;

  /// No description provided for @firstRunSentence.
  ///
  /// In en, this message translates to:
  /// **'Mile zero: the Milion on Divanyolu, the stone from which the empire measured its roads, with rings in Roman miles reaching Süleymaniye, Galata Tower, Maiden’s Tower, Chora and Yedikule.'**
  String get firstRunSentence;

  /// No description provided for @firstRunStone.
  ///
  /// In en, this message translates to:
  /// **'Divanyolu, beside the Basilica Cistern'**
  String get firstRunStone;

  /// No description provided for @firstRunStill.
  ///
  /// In en, this message translates to:
  /// **'Still {number} of 3'**
  String firstRunStill(String number);

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @openToday.
  ///
  /// In en, this message translates to:
  /// **'Open Today'**
  String get openToday;

  /// No description provided for @replayFirstRun.
  ///
  /// In en, this message translates to:
  /// **'Replay mile zero'**
  String get replayFirstRun;

  /// No description provided for @replayFirstRunBody.
  ///
  /// In en, this message translates to:
  /// **'The 12-second opening: the Milion, the Roman-mile rings and five places.'**
  String get replayFirstRunBody;

  /// No description provided for @detailOfDay.
  ///
  /// In en, this message translates to:
  /// **'Detail of the day'**
  String get detailOfDay;

  /// No description provided for @openMilestoneDetail.
  ///
  /// In en, this message translates to:
  /// **'Open {numeral} at this detail'**
  String openMilestoneDetail(String numeral);

  /// No description provided for @detailSource.
  ///
  /// In en, this message translates to:
  /// **'{artwork} · {place}'**
  String detailSource(String artwork, String place);

  /// No description provided for @dialLabel.
  ///
  /// In en, this message translates to:
  /// **'Mile Zero dial'**
  String get dialLabel;

  /// No description provided for @dialHint.
  ///
  /// In en, this message translates to:
  /// **'Turn the ring: one detent per place. Tap a tick to open it.'**
  String get dialHint;

  /// No description provided for @dialValue.
  ///
  /// In en, this message translates to:
  /// **'{place}, {distance}, {degrees}° from true north'**
  String dialValue(String place, String distance, String degrees);

  /// No description provided for @showList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get showList;

  /// No description provided for @showDial.
  ///
  /// In en, this message translates to:
  /// **'Dial'**
  String get showDial;

  /// No description provided for @placesByBearing.
  ///
  /// In en, this message translates to:
  /// **'{count} places by bearing from true north'**
  String placesByBearing(String count);

  /// No description provided for @plottedPlaces.
  ///
  /// In en, this message translates to:
  /// **'{count} places · positions checked on Wikidata · {reviewed} reviewed'**
  String plottedPlaces(String count, String reviewed);

  /// No description provided for @notReviewed.
  ///
  /// In en, this message translates to:
  /// **'Not reviewed yet'**
  String get notReviewed;

  /// No description provided for @reviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get reviewed;

  /// No description provided for @openPlace.
  ///
  /// In en, this message translates to:
  /// **'Open {place}'**
  String openPlace(String place);

  /// No description provided for @nextMilestones.
  ///
  /// In en, this message translates to:
  /// **'Next in the register'**
  String get nextMilestones;

  /// No description provided for @chapterHeading.
  ///
  /// In en, this message translates to:
  /// **'Chapter {numeral} · {name}'**
  String chapterHeading(String numeral, String name);

  /// No description provided for @chapterByzantineName.
  ///
  /// In en, this message translates to:
  /// **'Byzantine'**
  String get chapterByzantineName;

  /// No description provided for @chapterMosquesName.
  ///
  /// In en, this message translates to:
  /// **'Mosques'**
  String get chapterMosquesName;

  /// No description provided for @chapterMuseumsName.
  ///
  /// In en, this message translates to:
  /// **'Museums'**
  String get chapterMuseumsName;

  /// No description provided for @chapterAbroadName.
  ///
  /// In en, this message translates to:
  /// **'Istanbul abroad'**
  String get chapterAbroadName;

  /// No description provided for @chapterCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current chapter'**
  String get chapterCurrent;

  /// No description provided for @chapterProgress.
  ///
  /// In en, this message translates to:
  /// **'{playable} of {total} playable · {approved} approved'**
  String chapterProgress(String playable, String total, String approved);

  /// No description provided for @statusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get statusPlanned;

  /// No description provided for @statusPrototype.
  ///
  /// In en, this message translates to:
  /// **'Prototype'**
  String get statusPrototype;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusOpened.
  ///
  /// In en, this message translates to:
  /// **'Opened'**
  String get statusOpened;

  /// No description provided for @flagship.
  ///
  /// In en, this message translates to:
  /// **'Flagship'**
  String get flagship;

  /// No description provided for @craftKit.
  ///
  /// In en, this message translates to:
  /// **'Craft kit'**
  String get craftKit;

  /// No description provided for @acrossCity.
  ///
  /// In en, this message translates to:
  /// **'Across the city'**
  String get acrossCity;

  /// No description provided for @registerCounts.
  ///
  /// In en, this message translates to:
  /// **'{total} Milestones · {playable} playable · {approved} approved · {planned} planned'**
  String registerCounts(
    String total,
    String playable,
    String approved,
    String planned,
  );

  /// No description provided for @milestonePlannedBody.
  ///
  /// In en, this message translates to:
  /// **'Planned: its reveal, story and exploration are not built yet. The empty slot stays outlined until it is.'**
  String get milestonePlannedBody;

  /// No description provided for @techniques.
  ///
  /// In en, this message translates to:
  /// **'Techniques'**
  String get techniques;

  /// No description provided for @labelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get labelsTitle;

  /// No description provided for @mosaicProgress.
  ///
  /// In en, this message translates to:
  /// **'{opened} of {total} Milestones opened'**
  String mosaicProgress(String opened, String total);

  /// No description provided for @mosaicNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {numeral} · {title}'**
  String mosaicNext(String numeral, String title);

  /// No description provided for @mosaicIntro.
  ///
  /// In en, this message translates to:
  /// **'One tessera per Milestone. Each one you open is set in gold.'**
  String get mosaicIntro;

  /// No description provided for @notesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your notes'**
  String get notesTitle;

  /// No description provided for @notesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} notes on Chora artworks'**
  String notesCount(String count);

  /// No description provided for @cityTitle.
  ///
  /// In en, this message translates to:
  /// **'Places by distance from mile zero'**
  String get cityTitle;

  /// No description provided for @placeDraftBody.
  ///
  /// In en, this message translates to:
  /// **'Name and position checked against Wikidata {qid} on {date}. Story, hours and entrance are not reviewed yet.'**
  String placeDraftBody(String qid, String date);

  /// No description provided for @historicalNames.
  ///
  /// In en, this message translates to:
  /// **'Historical names'**
  String get historicalNames;

  /// No description provided for @artworksHere.
  ///
  /// In en, this message translates to:
  /// **'{count} artworks'**
  String artworksHere(String count);

  /// No description provided for @milestonesHere.
  ///
  /// In en, this message translates to:
  /// **'Milestones here'**
  String get milestonesHere;

  /// No description provided for @recognise.
  ///
  /// In en, this message translates to:
  /// **'Recognise an artwork with the camera'**
  String get recognise;

  /// No description provided for @sourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sourcesTitle;

  /// No description provided for @todayError.
  ///
  /// In en, this message translates to:
  /// **'Today could not open'**
  String get todayError;

  /// No description provided for @todayErrorBody.
  ///
  /// In en, this message translates to:
  /// **'The bundled registry could not be read. Try again.'**
  String get todayErrorBody;

  /// No description provided for @photoOriginal.
  ///
  /// In en, this message translates to:
  /// **'Unaltered photograph'**
  String get photoOriginal;

  /// No description provided for @placeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} places'**
  String placeCount(String count);

  /// No description provided for @eastLetter.
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get eastLetter;

  /// No description provided for @southLetter.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get southLetter;

  /// No description provided for @westLetter.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get westLetter;

  /// No description provided for @honestyRange.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String honestyRange(String from, String to);

  /// No description provided for @digVisit.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get digVisit;

  /// No description provided for @digHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get digHours;

  /// No description provided for @digEntry.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get digEntry;

  /// No description provided for @digEtiquette.
  ///
  /// In en, this message translates to:
  /// **'Etiquette'**
  String get digEtiquette;

  /// No description provided for @digAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get digAccessibility;

  /// No description provided for @digGettingThere.
  ///
  /// In en, this message translates to:
  /// **'Getting there'**
  String get digGettingThere;

  /// No description provided for @digCheckedOn.
  ///
  /// In en, this message translates to:
  /// **'Checked {date}'**
  String digCheckedOn(String date);

  /// No description provided for @digNotChecked.
  ///
  /// In en, this message translates to:
  /// **'Not yet field-checked'**
  String get digNotChecked;

  /// No description provided for @digVisitUnverified.
  ///
  /// In en, this message translates to:
  /// **'Visit facts are not yet field-checked.'**
  String get digVisitUnverified;

  /// No description provided for @digRemotelyChecked.
  ///
  /// In en, this message translates to:
  /// **'Checked against published sources on {date}.'**
  String digRemotelyChecked(String date);

  /// No description provided for @digWalkMinutes.
  ///
  /// In en, this message translates to:
  /// **'about {minutes} min on foot'**
  String digWalkMinutes(String minutes);

  /// No description provided for @digReportChange.
  ///
  /// In en, this message translates to:
  /// **'Report a change'**
  String get digReportChange;

  /// No description provided for @digReportSubject.
  ///
  /// In en, this message translates to:
  /// **'Milion: a correction for {place}'**
  String digReportSubject(String place);

  /// No description provided for @digReportBody.
  ///
  /// In en, this message translates to:
  /// **'Place: {place} ({qid})\n\nWhat should change?\n'**
  String digReportBody(String place, String qid);

  /// No description provided for @digSources.
  ///
  /// In en, this message translates to:
  /// **'Sources ({count})'**
  String digSources(String count);

  /// No description provided for @digLayerArtworks.
  ///
  /// In en, this message translates to:
  /// **'Artworks in this layer'**
  String get digLayerArtworks;

  /// No description provided for @digLayerMilestones.
  ///
  /// In en, this message translates to:
  /// **'Enter the Milestones here'**
  String get digLayerMilestones;

  /// No description provided for @digGo.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get digGo;

  /// No description provided for @digGoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open walking directions'**
  String get digGoTooltip;

  /// No description provided for @digDiagram.
  ///
  /// In en, this message translates to:
  /// **'Section diagram — not a photograph'**
  String get digDiagram;

  /// No description provided for @digDepthGauge.
  ///
  /// In en, this message translates to:
  /// **'Depth gauge'**
  String get digDepthGauge;

  /// No description provided for @digDepthHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe the rail to move through the years.'**
  String get digDepthHint;

  /// No description provided for @digGaugeYear.
  ///
  /// In en, this message translates to:
  /// **'Year {year}'**
  String digGaugeYear(String year);

  /// No description provided for @eraAncient.
  ///
  /// In en, this message translates to:
  /// **'Ancient'**
  String get eraAncient;

  /// No description provided for @eraRoman.
  ///
  /// In en, this message translates to:
  /// **'Roman'**
  String get eraRoman;

  /// No description provided for @eraByzantine.
  ///
  /// In en, this message translates to:
  /// **'Byzantine'**
  String get eraByzantine;

  /// No description provided for @eraMedieval.
  ///
  /// In en, this message translates to:
  /// **'Medieval'**
  String get eraMedieval;

  /// No description provided for @eraOttoman.
  ///
  /// In en, this message translates to:
  /// **'Ottoman'**
  String get eraOttoman;

  /// No description provided for @eraModern.
  ///
  /// In en, this message translates to:
  /// **'Modern'**
  String get eraModern;

  /// No description provided for @placeStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get placeStatusOpen;

  /// No description provided for @placeStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get placeStatusClosed;

  /// No description provided for @placeStatusRestoration.
  ///
  /// In en, this message translates to:
  /// **'Under restoration'**
  String get placeStatusRestoration;

  /// No description provided for @placeStatusRuin.
  ///
  /// In en, this message translates to:
  /// **'Ruin'**
  String get placeStatusRuin;

  /// No description provided for @placeStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Status unknown'**
  String get placeStatusUnknown;

  /// No description provided for @placeCheckedOn.
  ///
  /// In en, this message translates to:
  /// **'Status checked {date}'**
  String placeCheckedOn(String date);

  /// No description provided for @placeFunction.
  ///
  /// In en, this message translates to:
  /// **'Current use'**
  String get placeFunction;

  /// No description provided for @plateStory.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get plateStory;

  /// No description provided for @plateLayers.
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get plateLayers;

  /// No description provided for @platePlay.
  ///
  /// In en, this message translates to:
  /// **'Play story'**
  String get platePlay;

  /// No description provided for @platePause.
  ///
  /// In en, this message translates to:
  /// **'Pause story'**
  String get platePause;

  /// No description provided for @platePrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous still'**
  String get platePrevious;

  /// No description provided for @plateNext.
  ///
  /// In en, this message translates to:
  /// **'Next still'**
  String get plateNext;

  /// No description provided for @plateTimeline.
  ///
  /// In en, this message translates to:
  /// **'Story position'**
  String get plateTimeline;

  /// No description provided for @plateGilded.
  ///
  /// In en, this message translates to:
  /// **'Gilded light'**
  String get plateGilded;

  /// No description provided for @plateRaking.
  ///
  /// In en, this message translates to:
  /// **'Raking light'**
  String get plateRaking;

  /// No description provided for @plateCandle.
  ///
  /// In en, this message translates to:
  /// **'Candle'**
  String get plateCandle;

  /// No description provided for @plateNoLight.
  ///
  /// In en, this message translates to:
  /// **'No added light'**
  String get plateNoLight;

  /// No description provided for @plateGyro.
  ///
  /// In en, this message translates to:
  /// **'Tilt with the phone'**
  String get plateGyro;

  /// No description provided for @plateGyroHint.
  ///
  /// In en, this message translates to:
  /// **'Off until you choose it. Touch the artwork to recenter.'**
  String get plateGyroHint;

  /// No description provided for @plateGyroUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No gyroscope reading. Drag the artwork to tilt.'**
  String get plateGyroUnavailable;

  /// No description provided for @plateDragHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to tilt; pinch to zoom.'**
  String get plateDragHint;

  /// No description provided for @plateRakingHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the light across the paint.'**
  String get plateRakingHint;

  /// No description provided for @plateCandleHint.
  ///
  /// In en, this message translates to:
  /// **'Hold the warm light under your finger.'**
  String get plateCandleHint;

  /// No description provided for @plateWipeHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to reveal reconstruction in damaged areas. Hold to see the original.'**
  String get plateWipeHint;

  /// No description provided for @plateOriginalHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the label to return to the original.'**
  String get plateOriginalHint;

  /// No description provided for @platePaintMotion.
  ///
  /// In en, this message translates to:
  /// **'River of fire'**
  String get platePaintMotion;

  /// No description provided for @plateScrollMotion.
  ///
  /// In en, this message translates to:
  /// **'Scroll of heaven'**
  String get plateScrollMotion;

  /// No description provided for @plateStillHint.
  ///
  /// In en, this message translates to:
  /// **'Motion is off. Use Next and Previous to read the same story as stills.'**
  String get plateStillHint;

  /// No description provided for @plateMotionCaption.
  ///
  /// In en, this message translates to:
  /// **'One imagined wrist-grip gesture; the photograph is one tap away.'**
  String get plateMotionCaption;

  /// No description provided for @plateDebug.
  ///
  /// In en, this message translates to:
  /// **'Gesture and rendering study'**
  String get plateDebug;

  /// No description provided for @plateClose.
  ///
  /// In en, this message translates to:
  /// **'Close controls'**
  String get plateClose;

  /// No description provided for @plateDetails.
  ///
  /// In en, this message translates to:
  /// **'Details in the photograph'**
  String get plateDetails;

  /// No description provided for @plateReveal.
  ///
  /// In en, this message translates to:
  /// **'10-second reveal'**
  String get plateReveal;

  /// No description provided for @plateExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore the plate'**
  String get plateExplore;

  /// No description provided for @plateStartReveal.
  ///
  /// In en, this message translates to:
  /// **'Play reveal'**
  String get plateStartReveal;

  /// No description provided for @plateSources.
  ///
  /// In en, this message translates to:
  /// **'Sources and photograph'**
  String get plateSources;

  /// No description provided for @plateLoading.
  ///
  /// In en, this message translates to:
  /// **'Preparing the plate'**
  String get plateLoading;

  /// No description provided for @plateLookUp.
  ///
  /// In en, this message translates to:
  /// **'Look up'**
  String get plateLookUp;

  /// No description provided for @plateLookUpHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to look around the dome, pinch to zoom, double-tap to return to the top.'**
  String get plateLookUpHint;

  /// No description provided for @plateLookUpSensor.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone overhead'**
  String get plateLookUpSensor;

  /// No description provided for @plateLookUpSensorHint.
  ///
  /// In en, this message translates to:
  /// **'Off until you choose it. The view follows the phone\'s rotation sensor.'**
  String get plateLookUpSensorHint;

  /// No description provided for @plateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The plate’s images could not be loaded.'**
  String get plateUnavailable;

  /// No description provided for @spaceAssemble.
  ///
  /// In en, this message translates to:
  /// **'Assemble'**
  String get spaceAssemble;

  /// No description provided for @spaceSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get spaceSection;

  /// No description provided for @spaceStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get spaceStyle;

  /// No description provided for @spaceStyleDrawing.
  ///
  /// In en, this message translates to:
  /// **'Drawing'**
  String get spaceStyleDrawing;

  /// No description provided for @spaceStyleStone.
  ///
  /// In en, this message translates to:
  /// **'Stone'**
  String get spaceStyleStone;

  /// No description provided for @spaceStyleNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get spaceStyleNight;

  /// No description provided for @spacePlay.
  ///
  /// In en, this message translates to:
  /// **'Play the assembly'**
  String get spacePlay;

  /// No description provided for @spaceAssembly.
  ///
  /// In en, this message translates to:
  /// **'Assembly, step by step'**
  String get spaceAssembly;

  /// No description provided for @spaceAssemblyValue.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} steps'**
  String spaceAssemblyValue(String done, String total);

  /// No description provided for @spaceExplode.
  ///
  /// In en, this message translates to:
  /// **'Exploded view'**
  String get spaceExplode;

  /// No description provided for @spaceTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get spaceTime;

  /// No description provided for @spaceSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get spaceSteps;

  /// No description provided for @spaceSectionPlane.
  ///
  /// In en, this message translates to:
  /// **'Section plane'**
  String get spaceSectionPlane;

  /// No description provided for @spaceSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the handle on the drawing to move the cut; the half facing you is removed.'**
  String get spaceSectionHint;

  /// No description provided for @spaceSectionHandle.
  ///
  /// In en, this message translates to:
  /// **'Section plane handle'**
  String get spaceSectionHandle;

  /// No description provided for @spaceCutPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan cut'**
  String get spaceCutPlan;

  /// No description provided for @spaceCutNorthSouth.
  ///
  /// In en, this message translates to:
  /// **'North–south cut'**
  String get spaceCutNorthSouth;

  /// No description provided for @spaceCutEastWest.
  ///
  /// In en, this message translates to:
  /// **'East–west cut'**
  String get spaceCutEastWest;

  /// No description provided for @spaceMetres.
  ///
  /// In en, this message translates to:
  /// **'{value} m'**
  String spaceMetres(String value);

  /// No description provided for @spaceChoisy.
  ///
  /// In en, this message translates to:
  /// **'Choisy’s view from below'**
  String get spaceChoisy;

  /// No description provided for @spaceChoisyHint.
  ///
  /// In en, this message translates to:
  /// **'Auguste Choisy drew vaults this way in 1899: from below, with the plan cut.'**
  String get spaceChoisyHint;

  /// No description provided for @spacePerspective.
  ///
  /// In en, this message translates to:
  /// **'Perspective'**
  String get spacePerspective;

  /// No description provided for @spaceGestureHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to turn, pinch to zoom, move with two fingers, double-tap for Choisy’s view.'**
  String get spaceGestureHint;

  /// No description provided for @spaceSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get spaceSources;

  /// No description provided for @spaceLoading.
  ///
  /// In en, this message translates to:
  /// **'Preparing the drawing'**
  String get spaceLoading;

  /// No description provided for @spaceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The drawing’s model could not be loaded.'**
  String get spaceUnavailable;

  /// No description provided for @digLayerStudies.
  ///
  /// In en, this message translates to:
  /// **'Studies in this layer'**
  String get digLayerStudies;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
