// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Milion · İstanbul’un sıfır noktası';

  @override
  String get brandName => 'MİLİON';

  @override
  String get tagline => 'İstanbul’un sıfır noktası';

  @override
  String get home => 'Ana sayfa';

  @override
  String get today => 'Bugün';

  @override
  String get collection => 'Koleksiyon';

  @override
  String get scan => 'Tara';

  @override
  String get about => 'Hakkında';

  @override
  String get openAnastasis => 'Anastasis’i aç';

  @override
  String get anastasis => 'Anastasis';

  @override
  String get judgment => 'Son Yargı';

  @override
  String get chora => 'Hora / Kariye';

  @override
  String get choraLocation => 'Fatih · Hora / Kariye';

  @override
  String get anastasisHook => 'İsa, Âdem ile Havva’yı bileklerinden tutuyor.';

  @override
  String get judgmentHook => 'Bir melek göğü tomar gibi sarıyor.';

  @override
  String get original => 'Özgün';

  @override
  String get depth => 'Derinlik';

  @override
  String get reconstruction => 'Rekonstrüksiyon';

  @override
  String get imagined => 'Hayalî';

  @override
  String get originalDescription => 'Kaynak fotoğraf, değiştirilmeden.';

  @override
  String get depthDescription =>
      'Kaynak görüntüye derinlik veya ışık eklenmiş.';

  @override
  String get reconstructionDescription =>
      'Kaynaklara dayanarak eklenmiş görüntü veya geometri.';

  @override
  String get imaginedDescription => 'Tarihî kanıt sayılmayan bir yorum.';

  @override
  String get mileZero => 'Sıfırıncı mil';

  @override
  String get milionCoordinates => '41.008043° K · 28.978066° D';

  @override
  String get fromMilion => 'Milyon Taşı’ndan';

  @override
  String bearing(String degrees) {
    return 'Gerçek kuzeyden $degrees°';
  }

  @override
  String get straightLine => 'Kuş uçuşu uzaklık · 1 Roma mili yaklaşık 1.480 m';

  @override
  String catalogueCount(String count) {
    return '$count eser · Hora / Kariye';
  }

  @override
  String get viewCollection => 'Koleksiyonu aç';

  @override
  String get scanScene => 'Bir eseri tara';

  @override
  String get aboutCredits => 'Hakkında ve kaynaklar';

  @override
  String get loadingCollection => 'Koleksiyon açılıyor';

  @override
  String get collectionError => 'Koleksiyon açılamadı';

  @override
  String get collectionErrorBody =>
      'Cihazdaki Kariye kataloğu okunamadı. Yeniden deneyin.';

  @override
  String get scannerUnavailable => 'Tarayıcı kullanılamıyor';

  @override
  String get scannerUnavailableBody =>
      'Eser tanıma başlatılamadı. Koleksiyon çevrimdışı kullanılabilir.';

  @override
  String get preparingScanner => 'Tarayıcı hazırlanıyor';

  @override
  String get preparingScannerBody => '103 eserlik Kariye modeli yükleniyor.';

  @override
  String get retry => 'Yeniden dene';

  @override
  String get loading => 'Yükleniyor';

  @override
  String get searchScenes => 'Eser, bölüm veya ayrıntı ara';

  @override
  String get clearSearch => 'Aramayı temizle';

  @override
  String get allRooms => 'Tüm bölümler';

  @override
  String get interactive => 'Etkileşimli';

  @override
  String get noScenes => 'Eşleşen eser yok';

  @override
  String get noScenesBody => 'Arama metnini veya bölüm filtresini değiştirin.';

  @override
  String get clearFilters => 'Filtreleri temizle';

  @override
  String get hasNote => 'Not eklendi';

  @override
  String get room => 'Bölüm';

  @override
  String get lookFor => 'Şunlara bakın';

  @override
  String get where => 'Konum';

  @override
  String get yourNote => 'Notunuz';

  @override
  String get noteHint => 'Bu eser için bir not yazın';

  @override
  String get saveNote => 'Notu kaydet';

  @override
  String get saved => 'Kaydedildi';

  @override
  String noteSaved(String id) {
    return '$id için not kaydedildi';
  }

  @override
  String get exploreRelief => 'Eseri aç';

  @override
  String modelMatch(String percent) {
    return 'Model eşleşmesi %$percent · doğrulanmadı';
  }

  @override
  String get contentEnglish => 'Bu eserin Türkçe metni henüz hazırlanmadı.';

  @override
  String get language => 'Dil';

  @override
  String get systemLanguage => 'Cihaz dili';

  @override
  String get english => 'English';

  @override
  String get turkish => 'Türkçe';

  @override
  String get appearance => 'Görünüm';

  @override
  String get marble => 'Mermer';

  @override
  String get lamp => 'Kandil';

  @override
  String get aboutStory =>
      'Milion, Konstantinopolis’in sıfırıncı mil taşıydı. Günümüze kalan parçası Divanyolu’nda, Yerebatan Sarnıcı’nın yanında duruyor. Uygulama İstanbul’un uzaklıklarını bu noktadan ölçüyor.';

  @override
  String get aboutRecognition =>
      'Kamera, Kariye’deki 103 eser arasından olası eşleşmeleri gösterir. Tanıma cihazda, çevrimdışı çalışır.';

  @override
  String get recognitionLimits => 'Tanımanın sınırları';

  @override
  String get recognitionLimitsBody =>
      'Eşleşmeler birer öneridir. Prototip, eser içermeyen 231 test görüntüsünün en fazla %67’sini eledi; tek başına eser doğrulaması yapamaz.';

  @override
  String get credits => 'Kaynaklar ve katkılar';

  @override
  String get creditsBody =>
      'Kariye görselleri: proje sahibinin çekimleri, Wikimedia Commons ve Kültür Envanteri. Her görsel yayından önce hak incelemesinden geçer. Kadrandaki ve açılıştaki kıyı ve sokak çizgileri: © OpenStreetMap katkıda bulunanları, ODbL 1.0.';

  @override
  String get licenses => 'Açık kaynak lisansları';

  @override
  String get version => 'Milion 1.0.0 · 1';

  @override
  String get previewFooter => 'İstanbul koleksiyonu · Kariye önizlemesi';

  @override
  String get registry => 'İçerik kaydı';

  @override
  String get registryError => 'İçerik kaydı yüklenemedi.';

  @override
  String registryCounts(String places, String artworks) {
    return '$places yer · $artworks eser';
  }

  @override
  String draftCounts(String count) {
    return '$count taslak · genel yer listelerinde gösterilmez';
  }

  @override
  String get registryMeasurement =>
      'Kuş uçuşu uzaklık · Roma mili yuvarlanır\n1 mil yaklaşık 1.480 m · açılar gerçek kuzeye göre';

  @override
  String get categoryCounts => 'Kategoriye göre sayılar';

  @override
  String get districtCounts => 'İlçeye göre sayılar · 39';

  @override
  String get outsideProvince => 'İl dışı';

  @override
  String get categoryByzantine => 'Bizans';

  @override
  String get categoryMosque => 'Cami';

  @override
  String get categoryMuseum => 'Müze';

  @override
  String get categoryPalace => 'Saray';

  @override
  String get categoryFortification => 'Savunma yapısı';

  @override
  String get categoryCistern => 'Sarnıç';

  @override
  String get categoryTower => 'Kule';

  @override
  String get categoryBazaar => 'Çarşı';

  @override
  String get categoryBath => 'Hamam';

  @override
  String get categoryOther => 'Diğer';

  @override
  String get designSheet => 'Porfir ve Tessera';

  @override
  String get designIntro =>
      'İstanbul için bir ölçü aracı: uzaklık, derinlik ve ışık.';

  @override
  String get directionA => 'A · Önce kandil';

  @override
  String get directionB => 'B · Mermer ve porfir';

  @override
  String get paletteTitle => 'Renkler ve yüzeyler';

  @override
  String get typeTitle => 'Yazılar ve ölçüler';

  @override
  String get componentsTitle => 'Ölçü araçları';

  @override
  String get porphyry => 'Porfir';

  @override
  String get tesseraGold => 'Tessera altını · malzeme ve ödüller';

  @override
  String get cobalt => 'İznik kobaltı';

  @override
  String get bole => 'İznik kırmızısı';

  @override
  String get turquoise => 'Turkuaz';

  @override
  String get verdigris => 'Bakır yeşili';

  @override
  String get bronze => 'Bronz';

  @override
  String get gridLabel => '4 dp ızgara · en fazla 2 dp köşe · gölgesiz';

  @override
  String get fontSpecimen =>
      'İstanbul Ayasofya Süleymaniye Eyüpsultan Kılıç Ali Paşa Şehzadebaşı ığüşöçİĞÜŞÖÇ · Η ΑΝΑϹΤΑϹΙϹ ΙϹ ΧϹ · XLVII · 3,4 mil';

  @override
  String get displayRole => 'Cinzel · Yunanca için Noto Serif Display';

  @override
  String get bodyRole => 'Noto Sans · eş genişlikli rakamlar';

  @override
  String get stratumTitle => 'Metokhites’in Kariye’si';

  @override
  String get stratumBody =>
      'Mozaik ve fresk; duvarları, tonozları ve kubbeleri paylaşır.';

  @override
  String get leaderCaption => 'Âdem’in bileği';

  @override
  String get north => 'Kuzey';

  @override
  String get northLetter => 'K';

  @override
  String scaleDistance(String metres) {
    return '$metres m';
  }

  @override
  String get dimensionHandle => 'Kapatmak için aşağı sürükleyin';

  @override
  String get sheetTitle => 'Eser notu';

  @override
  String get openSheet => 'Ölçü çizgili paneli aç';

  @override
  String get emptyTitle => 'Kayıtlı not yok';

  @override
  String get emptyBody => 'Bir Kariye eseri açıp ilk notunuzu kaydedin.';

  @override
  String get errorTitle => 'Eser görseli açılamadı';

  @override
  String get errorBody =>
      'Görsel dosyası okunamadı. Yeniden yüklemeyi deneyin.';

  @override
  String get motionTitle => 'Yerleşme · katman · tarama';

  @override
  String get motionInfo =>
      'Yerleşme · 160 ms · easeOutCubic\nKatman açma · 360 ms · easeInOutCubic\nTarama · 520 ms · easeOutQuart\nAzaltılmış hareket: anında durum değişikliği.';

  @override
  String get hapticDetent => 'Hafif titreşim';

  @override
  String get hapticCollect => 'Toplama titreşimi';

  @override
  String get iconDome => 'Kubbe';

  @override
  String get iconMinaret => 'Minare';

  @override
  String get iconColumn => 'Sütun';

  @override
  String get iconGate => 'Kapı';

  @override
  String get iconCistern => 'Sarnıç';

  @override
  String get iconVitrine => 'Vitrin';

  @override
  String get iconRoute => 'Rota';

  @override
  String get iconTessera => 'Tessera';

  @override
  String get iconCameraEye => 'Kamera gözü';

  @override
  String get iconSound => 'Ses';

  @override
  String get iconLight => 'Işık';

  @override
  String get iconLayers => 'Katmanlar';

  @override
  String get iconStory => 'Anlatı';

  @override
  String scalePercent(String percent) {
    return '%$percent metin';
  }

  @override
  String milestoneNumber(String numeral) {
    return 'Taş $numeral';
  }

  @override
  String get measurementTitle => 'Sıfırıncı milden uzaklık';

  @override
  String get strataTitle => 'Kariye’nin katmanları';

  @override
  String get focusChora => 'Kariye · 103 eser';

  @override
  String get chapterByzantine => 'Bizans bölümü';

  @override
  String get plates => 'İki levha';

  @override
  String get openJudgment => 'Son Yargı’yı aç';

  @override
  String get zoomIn => 'Yaklaştır';

  @override
  String get zoomOut => 'Uzaklaştır';

  @override
  String get resetView => 'Görünümü sıfırla';

  @override
  String get sceneOptions => 'Eser seçenekleri';

  @override
  String get studies => 'Rekonstrüksiyon çalışmaları';

  @override
  String get sceneUnavailable => 'Eser dosyaları açılamadı.';

  @override
  String get loadingArtwork => 'Eser yükleniyor';

  @override
  String get overview => 'Genel görünüm';

  @override
  String get chooseDetail => 'Bir ayrıntı seçin';

  @override
  String get detailHint =>
      'Yakınlaştırmak için iki parmağınızı açın. Konumuna gitmek için bir ayrıntı seçin.';

  @override
  String get detailMarkers => 'Kılavuz çizgileri';

  @override
  String get showMarkers => 'Kılavuz çizgilerini göster';

  @override
  String get hideMarkers => 'Kılavuz çizgilerini gizle';

  @override
  String get gestureStudy => 'Jest çalışması';

  @override
  String get gestureBody =>
      'Tek ve hafif bir hayalî hareket. Kaynak fotoğrafa tek dokunuşla dönün.';

  @override
  String get playGesture => 'Jesti bir kez oynat';

  @override
  String get pauseGesture => 'Jesti duraklat';

  @override
  String get still => 'Hareketsiz';

  @override
  String get pose => 'Poz';

  @override
  String get movement => 'Hareket';

  @override
  String get gentle => 'Hafif';

  @override
  String get singleGesture => '6 sn · tek sefer';

  @override
  String get reducedMotionHint =>
      'Otomatik hareket kapalı. Pozu elle ayarlayabilirsiniz.';

  @override
  String gesturePercent(String percent) {
    return 'Jestin %$percent kadarı';
  }

  @override
  String movementPercent(String percent) {
    return '%$percent hareket';
  }

  @override
  String get blend => 'Karışım';

  @override
  String get restorationAmount => 'Rekonstrüksiyon saydamlığı';

  @override
  String get restorationNotice => 'Rekonstrüksiyon · kaynak fotoğraf korunur';

  @override
  String get studyNotice =>
      'Yorum içeren rekonstrüksiyon. Yüz ayrıntıları varsayımsaldır; kaynak fotoğraf değiştirilmemiştir.';

  @override
  String get restoredFresco => '4K fresk rekonstrüksiyonu';

  @override
  String get restoredVault => '4K tonoz rekonstrüksiyonu';

  @override
  String get detailChrist => 'İsa';

  @override
  String get detailAdam => 'Âdem';

  @override
  String get detailEve => 'Havva';

  @override
  String get detailLeft => 'Soldaki figürler';

  @override
  String get detailRight => 'Sağdaki figürler';

  @override
  String get detailGates => 'Kapılar';

  @override
  String get detailDeesis => 'Deesis';

  @override
  String get detailApostles => 'Havariler';

  @override
  String get detailHeavens => 'Gökler';

  @override
  String get detailThrone => 'Taht';

  @override
  String get detailRiver => 'Ateş ırmağı';

  @override
  String get anastasisChristBody =>
      'Açık renk giysi, yıldızlı mandorlanın önünde beliriyor.';

  @override
  String get adamBody => 'Birleşen eller, mezardan merkeze doğru uzanıyor.';

  @override
  String get eveBody => 'Kırmızı giysisi, eğik başı ve uzanan koluyla Havva.';

  @override
  String get leftBody => 'Solda yüzler, taçlar ve haleler üst üste geliyor.';

  @override
  String get rightBody =>
      'Yüzler ile giysi kıvrımları, resmedilmiş kayayla birleşiyor.';

  @override
  String get gatesBody =>
      'İsa’nın ayaklarının altında kırılmış kapılar yatıyor.';

  @override
  String get judgmentChristBody =>
      'Yüz ve mandorla, göksel mahkemenin merkezinde.';

  @override
  String get deesisBody =>
      'Merkezdeki figürün iki yanında ayakta duran figürler var.';

  @override
  String get apostlesBody =>
      'Oturan figürlerin ellerinde kitaplar, başlarında üst üste gelen haleler var.';

  @override
  String get heavensBody =>
      'Bir melek, daire biçiminde dürülen gökleri taşıyor.';

  @override
  String get throneBody =>
      'Hazırlanmış tahtın altında diz çökmüş figürler var.';

  @override
  String get riverBody => 'Kızıl turuncu ırmak, tonozun sağ altına uzanıyor.';

  @override
  String get noCamera => 'Bu cihazda kamera bulunamadı.';

  @override
  String get cameraError => 'Kamera kullanılamıyor';

  @override
  String get liveUnavailable => 'Bu cihazda canlı tanıma kullanılamıyor.';

  @override
  String get scanFailed => 'Görüntü çözümlenemedi. Başka bir görüntü deneyin.';

  @override
  String get lightFailed => 'Kamera ışığı değiştirilemedi.';

  @override
  String get liveOn => 'Canlı tanıma açık';

  @override
  String get liveOff => 'Canlı tanıma kapalı';

  @override
  String get pickGallery => 'Galeriden seç';

  @override
  String get gallery => 'Galeri';

  @override
  String get light => 'Işık';

  @override
  String get noSceneDetected =>
      'Eser bulunamadı · bir Kariye eserini kadraja alın';

  @override
  String get startCamera => 'Kamera açılıyor';

  @override
  String get cameraGuide => 'Bir mozaik veya freski kadraja alın';

  @override
  String get analysingScene => 'Eser çözümleniyor';

  @override
  String get topMatch => 'En yakın eşleşme';

  @override
  String get resultHint => 'Ayrıntılar ve notlar için bir sonuca dokunun';

  @override
  String get demoResult =>
      'Olası eşleşmeler. Eseri adlandırmadan önce sonucu gördüğünüz eserle karşılaştırın.';

  @override
  String get scanAgain => 'Yeniden tara';

  @override
  String get localeTr => 'TR';

  @override
  String get localeEn => 'EN';

  @override
  String get waveByzantine => 'Bizans · porfir üstünde altın';

  @override
  String get waveMosque => 'Camiler · kobalt / turkuaz';

  @override
  String get waveMuseum => 'Müzeler · bakır yeşili / bronz';

  @override
  String get cameraErrorBody =>
      'Android ayarlarında kamera iznini açıp yeniden deneyin. Galeriden bir fotoğraf da seçebilirsiniz.';

  @override
  String get navToday => 'Bugün';

  @override
  String get navCity => 'Şehir';

  @override
  String get navMilestones => 'Taşlar';

  @override
  String get navMosaic => 'Mozaik';

  @override
  String get iconDial => 'Sıfırıncı mil kadranı';

  @override
  String get iconMilestone => 'Mil taşı';

  @override
  String get techDP => 'Derinlik paralaksı';

  @override
  String get techGL => 'Yaldız ışığı';

  @override
  String get techRL => 'Yalayan ışık ya da mum';

  @override
  String get techPU => 'Açılır katmanlar';

  @override
  String get techWR => 'Silerek rekonstrüksiyon';

  @override
  String get techSB => 'Anlatı adımları';

  @override
  String get techMM => 'Mikro hareket';

  @override
  String get techSR => 'Çizgi çizgi açılış';

  @override
  String get techLU => 'Yukarı bakış';

  @override
  String get techCA => 'Choisy montajı';

  @override
  String get techCS => 'Kesit';

  @override
  String get techWK => 'Yürünebilir mekân';

  @override
  String get techTT => 'Döner tabla';

  @override
  String get techTM => 'Zaman modeli';

  @override
  String get techSK => 'Gökyüzü benzetimi';

  @override
  String get techVO => 'Sesler';

  @override
  String techniqueList(String list) {
    return 'Teknikler: $list';
  }

  @override
  String get firstRunLine => 'Bütün yollar buradan başladı.';

  @override
  String get firstRunSentence =>
      'Sıfırıncı mil: İmparatorluğun yollarını ölçtüğü taş, Divanyolu’ndaki Milion; Roma mili halkaları Süleymaniye’ye, Galata Kulesi’ne, Kız Kulesi’ne, Kariye’ye ve Yedikule’ye uzanıyor.';

  @override
  String get firstRunStone => 'Divanyolu, Yerebatan Sarnıcı’nın yanında';

  @override
  String firstRunStill(String number) {
    return 'Durağan görüntü $number/3';
  }

  @override
  String get skip => 'Geç';

  @override
  String get next => 'İleri';

  @override
  String get openToday => 'Bugün’ü aç';

  @override
  String get replayFirstRun => 'Sıfırıncı mili yeniden oynat';

  @override
  String get replayFirstRunBody =>
      '12 saniyelik açılış: Milion, Roma mili halkaları ve beş yer.';

  @override
  String get detailOfDay => 'Günün ayrıntısı';

  @override
  String openMilestoneDetail(String numeral) {
    return '$numeral taşını bu ayrıntıda aç';
  }

  @override
  String detailSource(String artwork, String place) {
    return '$artwork · $place';
  }

  @override
  String get dialLabel => 'Sıfırıncı mil kadranı';

  @override
  String get dialHint =>
      'Halkayı çevirin: her yerde bir tık. Açmak için bir çizgiye dokunun.';

  @override
  String dialValue(String place, String distance, String degrees) {
    return '$place, $distance, gerçek kuzeyden $degrees°';
  }

  @override
  String get showList => 'Liste';

  @override
  String get showDial => 'Kadran';

  @override
  String placesByBearing(String count) {
    return 'Gerçek kuzeye göre açı sırasıyla $count yer';
  }

  @override
  String plottedPlaces(String count, String reviewed) {
    return '$count yer · konumlar Wikidata’da doğrulandı · $reviewed incelendi';
  }

  @override
  String get notReviewed => 'Henüz incelenmedi';

  @override
  String get reviewed => 'İncelendi';

  @override
  String openPlace(String place) {
    return '$place sayfasını aç';
  }

  @override
  String get nextMilestones => 'Listede sıradakiler';

  @override
  String chapterHeading(String numeral, String name) {
    return '$numeral. bölüm · $name';
  }

  @override
  String get chapterByzantineName => 'Bizans';

  @override
  String get chapterMosquesName => 'Camiler';

  @override
  String get chapterMuseumsName => 'Müzeler';

  @override
  String get chapterAbroadName => 'Yurt dışındaki İstanbul';

  @override
  String get chapterCurrent => 'Şu anki bölüm';

  @override
  String chapterProgress(String playable, String total, String approved) {
    return '$total taştan $playable tanesi açılabilir · $approved onaylı';
  }

  @override
  String get statusPlanned => 'Planlandı';

  @override
  String get statusPrototype => 'Prototip';

  @override
  String get statusApproved => 'Onaylandı';

  @override
  String get statusOpened => 'Açıldı';

  @override
  String get flagship => 'Öne çıkan';

  @override
  String get craftKit => 'Zanaat seti';

  @override
  String get acrossCity => 'Şehir genelinde';

  @override
  String registerCounts(
    String total,
    String playable,
    String approved,
    String planned,
  ) {
    return '$total taş · $playable açılabilir · $approved onaylı · $planned planlandı';
  }

  @override
  String get milestonePlannedBody =>
      'Planlandı: açılışı, anlatısı ve keşfi henüz hazır değil. Hazır olana dek yeri boş çerçeve olarak kalır.';

  @override
  String get techniques => 'Teknikler';

  @override
  String get labelsTitle => 'Etiketler';

  @override
  String mosaicProgress(String opened, String total) {
    return '$total taştan $opened tanesini açtınız';
  }

  @override
  String mosaicNext(String numeral, String title) {
    return 'Sıradaki: $numeral · $title';
  }

  @override
  String get mosaicIntro =>
      'Her taş için bir tessera. Açtığınız her biri altınla yerine oturur.';

  @override
  String get notesTitle => 'Notlarınız';

  @override
  String notesCount(String count) {
    return 'Kariye eserlerinde $count not';
  }

  @override
  String get cityTitle => 'Sıfırıncı milden uzaklığa göre yerler';

  @override
  String placeDraftBody(String qid, String date) {
    return 'Ad ve konum $date tarihinde Wikidata $qid kaydıyla karşılaştırıldı. Anlatı, ziyaret saatleri ve giriş henüz incelenmedi.';
  }

  @override
  String get historicalNames => 'Tarihî adlar';

  @override
  String artworksHere(String count) {
    return '$count eser';
  }

  @override
  String get milestonesHere => 'Buradaki taşlar';

  @override
  String get recognise => 'Bir eseri kamerayla tanıyın';

  @override
  String get sourcesTitle => 'Kaynaklar';

  @override
  String get todayError => 'Bugün açılamadı';

  @override
  String get todayErrorBody =>
      'Cihazdaki içerik kaydı okunamadı. Yeniden deneyin.';

  @override
  String get photoOriginal => 'Değiştirilmemiş fotoğraf';

  @override
  String placeCount(String count) {
    return '$count yer';
  }

  @override
  String get eastLetter => 'D';

  @override
  String get southLetter => 'G';

  @override
  String get westLetter => 'B';

  @override
  String honestyRange(String from, String to) {
    return '$from ile $to arası';
  }

  @override
  String get digVisit => 'Ziyaret';

  @override
  String get digHours => 'Ziyaret saatleri';

  @override
  String get digEntry => 'Giriş';

  @override
  String get digEtiquette => 'Görgü kuralları';

  @override
  String get digAccessibility => 'Erişilebilirlik';

  @override
  String get digGettingThere => 'Ulaşım';

  @override
  String digCheckedOn(String date) {
    return 'Denetlendi: $date';
  }

  @override
  String get digNotChecked => 'Yerinde henüz doğrulanmadı';

  @override
  String get digVisitUnverified =>
      'Ziyaret bilgileri yerinde henüz doğrulanmadı.';

  @override
  String digRemotelyChecked(String date) {
    return 'Yayımlanmış kaynaklara göre $date tarihinde denetlendi.';
  }

  @override
  String digWalkMinutes(String minutes) {
    return 'yürüyüş yaklaşık $minutes dk';
  }

  @override
  String get digReportChange => 'Değişiklik bildir';

  @override
  String digReportSubject(String place) {
    return 'Milion: $place için düzeltme';
  }

  @override
  String digReportBody(String place, String qid) {
    return 'Yer: $place ($qid)\n\nNe değişmeli?\n';
  }

  @override
  String digSources(String count) {
    return 'Kaynaklar ($count)';
  }

  @override
  String get digLayerArtworks => 'Bu katmandaki eserler';

  @override
  String get digLayerMilestones => 'Taşlara buradan girin';

  @override
  String get digGo => 'Git';

  @override
  String get digGoTooltip => 'Yürüyüş tarifini aç';

  @override
  String get digDiagram => 'Kesit şeması — fotoğraf değil';

  @override
  String get digDepthGauge => 'Derinlik göstergesi';

  @override
  String get digDepthHint => 'Yıllar arasında gezinmek için rayı kaydırın.';

  @override
  String digGaugeYear(String year) {
    return '$year yılı';
  }

  @override
  String get eraAncient => 'Antik';

  @override
  String get eraRoman => 'Roma';

  @override
  String get eraByzantine => 'Bizans';

  @override
  String get eraMedieval => 'Orta Çağ';

  @override
  String get eraOttoman => 'Osmanlı';

  @override
  String get eraModern => 'Modern';

  @override
  String get placeStatusOpen => 'Açık';

  @override
  String get placeStatusClosed => 'Kapalı';

  @override
  String get placeStatusRestoration => 'Restorasyonda';

  @override
  String get placeStatusRuin => 'Harabe';

  @override
  String get placeStatusUnknown => 'Durum bilinmiyor';

  @override
  String placeCheckedOn(String date) {
    return 'Durum $date tarihinde doğrulandı';
  }

  @override
  String get placeFunction => 'Bugünkü işlev';

  @override
  String get plateStory => 'Öykü';

  @override
  String get plateLayers => 'Katmanlar';

  @override
  String get platePlay => 'Öyküyü oynat';

  @override
  String get platePause => 'Öyküyü duraklat';

  @override
  String get platePrevious => 'Önceki kare';

  @override
  String get plateNext => 'Sonraki kare';

  @override
  String get plateTimeline => 'Öyküdeki konum';

  @override
  String get plateGilded => 'Altın ışığı';

  @override
  String get plateRaking => 'Eğik ışık';

  @override
  String get plateCandle => 'Mum';

  @override
  String get plateNoLight => 'Ek ışık yok';

  @override
  String get plateGyro => 'Telefonu eğerek bak';

  @override
  String get plateGyroHint =>
      'Sen açana kadar kapalı. Ortalamak için esere dokun.';

  @override
  String get plateGyroUnavailable =>
      'Jiroskop verisi alınamıyor. Eseri sürükleyerek eğ.';

  @override
  String get plateDragHint =>
      'Eğmek için sürükle; büyütmek için iki parmağını kullan.';

  @override
  String get plateRakingHint => 'Işığı resmin üzerinde sürükle.';

  @override
  String get plateCandleHint => 'Sıcak ışığı parmağının altında tut.';

  @override
  String get plateWipeHint =>
      'Hasarlı alanlarda rekonstrüksiyonu açmak için sürükle. Özgün fotoğraf için basılı tut.';

  @override
  String get plateOriginalHint => 'Özgün fotoğrafa dönmek için etikete dokun.';

  @override
  String get platePaintMotion => 'Ateş nehri';

  @override
  String get plateScrollMotion => 'Göğün tomar gibi açılması';

  @override
  String get plateStillHint =>
      'Hareket kapalı. Aynı öyküyü kare kare okumak için Sonraki ve Önceki düğmelerini kullan.';

  @override
  String get plateMotionCaption =>
      'Bilekten çekişi gösteren tek bir hayalî hareket; fotoğraf bir dokunuş uzağında.';

  @override
  String get plateDebug => 'Hareket ve çizim çalışması';

  @override
  String get plateClose => 'Denetimleri kapat';

  @override
  String get plateDetails => 'Fotoğraftaki ayrıntılar';

  @override
  String get plateReveal => '10 saniyelik ilk bakış';

  @override
  String get plateExplore => 'Eseri incele';

  @override
  String get plateStartReveal => 'İlk bakışı oynat';

  @override
  String get plateSources => 'Kaynaklar ve fotoğraf';

  @override
  String get plateLoading => 'Eser hazırlanıyor';

  @override
  String get plateLookUp => 'Yukarı bak';

  @override
  String get plateLookUpHint =>
      'Kubbede gezinmek için sürükle, büyütmek için iki parmağını kullan, tepeye dönmek için iki kez dokun.';

  @override
  String get plateLookUpSensor => 'Telefonu başının üstüne kaldır';

  @override
  String get plateLookUpSensorHint =>
      'Sen açana kadar kapalı. Görüntü, telefonun dönüş sensörünü izler.';

  @override
  String get plateUnavailable => 'Eserin görselleri yüklenemedi.';

  @override
  String get spaceAssemble => 'Kur';

  @override
  String get spaceSection => 'Kesit';

  @override
  String get spaceStyle => 'Görünüm';

  @override
  String get spaceStyleDrawing => 'Çizim';

  @override
  String get spaceStyleStone => 'Taş';

  @override
  String get spaceStyleNight => 'Gece';

  @override
  String get spacePlay => 'Kuruluşu oynat';

  @override
  String get spaceAssembly => 'Adım adım kuruluş';

  @override
  String spaceAssemblyValue(String done, String total) {
    return '$done / $total adım';
  }

  @override
  String get spaceExplode => 'Patlatılmış görünüş';

  @override
  String get spaceTime => 'Zaman';

  @override
  String get spaceSteps => 'Adımlar';

  @override
  String get spaceSectionPlane => 'Kesit düzlemi';

  @override
  String get spaceSectionHint =>
      'Kesiti kaydırmak için çizimdeki tutamacı sürükle; sana bakan yarı kaldırılır.';

  @override
  String get spaceSectionHandle => 'Kesit düzlemi tutamacı';

  @override
  String get spaceCutPlan => 'Plan kesiti';

  @override
  String get spaceCutNorthSouth => 'Kuzey–güney kesiti';

  @override
  String get spaceCutEastWest => 'Doğu–batı kesiti';

  @override
  String get spaceCutLong => 'Boyuna kesit';

  @override
  String get spaceCutCross => 'Enine kesit';

  @override
  String get spaceStudies => '3B çizimler';

  @override
  String spaceMetres(String value) {
    return '$value m';
  }

  @override
  String get spaceChoisy => 'Choisy’nin alttan görünüşü';

  @override
  String get spaceChoisyHint =>
      'Auguste Choisy 1899’da tonozları böyle çizdi: alttan, planı keserek.';

  @override
  String get spacePerspective => 'Perspektif';

  @override
  String get spaceGestureHint =>
      'Döndürmek için sürükle, büyütmek için iki parmağını aç, iki parmakla kaydır, Choisy görünüşü için iki kez dokun.';

  @override
  String get spaceSources => 'Kaynaklar';

  @override
  String get spaceLoading => 'Çizim hazırlanıyor';

  @override
  String get spaceUnavailable => 'Çizimin modeli yüklenemedi.';

  @override
  String get digLayerStudies => 'Bu katmandaki incelemeler';
}
