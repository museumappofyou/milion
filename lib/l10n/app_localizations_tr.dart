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
  String get straightLine => 'Kuş uçuşu uzaklık · 1 Roma mili ≈ 1.480 m';

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
      'Kariye görselleri: proje sahibinin çekimleri, Wikimedia Commons ve Kültür Envanteri. Kaynak bağlantıları kayıtlıdır; yayın öncesi hak incelemesi sürüyor.';

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
      'Kuş uçuşu uzaklık · Roma mili yuvarlanır\n1 mil ≈ 1.480 m · açılar gerçek kuzeye göre';

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
    return 'Milestone $numeral';
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
  String get studyUnavailable => 'Rekonstrüksiyon görseli yüklenemedi.';

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
}
