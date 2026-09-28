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
  /// **'Straight-line distance · 1 Roman mile ≈ 1,480 m'**
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
  /// **'Chora references: project-owner captures, Wikimedia Commons and Kültür Envanteri. Source URLs are recorded; public-release rights review is pending.'**
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
  /// **'Straight-line distance · Roman miles rounded\n1 mil ≈ 1,480 m · bearings from true north'**
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

  /// No description provided for @studyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Restoration study could not be loaded.'**
  String get studyUnavailable;

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
