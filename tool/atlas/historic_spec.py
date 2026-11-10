"""The Atlas's historic layers (P10), hand-authored: what each feature is,
when it stood, how sure we are of its line, and where its positions come from.

tool/atlas/build_historic.py resolves the geometry references below into
studio/atlas/historic/*.geojson, which tool/atlas/build_atlas.py compacts into
assets/atlas/historic.json. A reference is one of:

  ('wd', 'Q…')             the item's P625 in the pinned Wikidata response
  ('label', 'English')     an item found by its English label, likewise
  ('place', 'id')          a registry place's checked coordinates
  ('towers', series, a, b) the numbered towers of a wall, a to b inclusive,
                           in that order, from the Wikidata wall inventory
  ('osm', way, reverse)    a surveyed way from the pinned Overpass walls query
  ('at', lat, lng)         a hand-placed point: allowed only in features whose
                           certainty is approximate or conjectural, and each
                           is explained in the feature's note

Dates are years (negative = BC); "to" is the last year the feature stood (or
was water), None if it still does. Certainty:
  surviving    stands today, positions surveyed
  traced       drawn through surviving or recorded points
  approximate  the line is known in outline only
  conjectural  the course is known only from texts
"""

WALL_INVENTORY = {
    # series key → the Turkish label pattern in the Wikidata inventory
    'land': r'^Kara Surları, Ana Sur, T(\d+)$',
    'golden-horn': r'^Haliç Surları, (\d+)\. Kule$',
    'marmara': r'^Marmara Surları, (\d+)\. Kule$',
}

WP = 'https://en.wikipedia.org/w/index.php?oldid='


def wp(sid, title, revid):
    return {
        'id': sid,
        'title': {'en': f'{title} — Wikipedia (revision {revid})',
                  'tr': f'{title} — Wikipedia ({revid} numaralı sürüm)'},
        'url': f'{WP}{revid}',
        'author': {'en': 'Wikipedia contributors', 'tr': 'Wikipedia katkıcıları'},
        'accessedAt': '2026-11-10',
        'licence': {'en': 'CC BY-SA 4.0', 'tr': 'CC BY-SA 4.0'},
    }


SOURCES = [
    wp('wp-walls-of-constantinople-1383343183', 'Walls of Constantinople', 1383343183),
    wp('wp-harbour-of-eleutherios-1354353475', 'Harbour of Eleutherios', 1354353475),
    wp('wp-kontoskalion-1336379705', 'Kontoskalion', 1336379705),
    wp('wp-mese-1333909142', 'Mese (Constantinople)', 1333909142),
    wp('wp-seven-hills-1374999074', 'Seven hills of Istanbul', 1374999074),
    wp('wp-fall-of-constantinople-1384652386', 'Fall of Constantinople', 1384652386),
    wp('wp-galata-tower-1384690717', 'Galata Tower', 1384690717),
    wp('wp-forum-of-constantine-1253152892', 'Forum of Constantine', 1253152892),
    wp('wp-forum-of-theodosius-1307424872', 'Forum of Theodosius', 1307424872),
    wp('wp-forum-of-the-ox-1270066911', 'Forum of the Ox', 1270066911),
    wp('wp-forum-of-arcadius-1383265770', 'Forum of Arcadius', 1383265770),
    wp('wp-philadelphion-1222481634', 'Philadelphion', 1222481634),
    wp('wp-augustaion-1266611461', 'Augustaion', 1266611461),
    wp('wp-basilica-cistern-1365846547', 'Basilica Cistern', 1365846547),
    wp('wp-cistern-of-philoxenos-1365179166', 'Cistern of Philoxenos', 1365179166),
    wp('wp-theodosius-cistern-1365081953', 'Theodosius Cistern', 1365081953),
    wp('wp-great-palace-1369328015', 'Great Palace of Constantinople', 1369328015),
    wp('wp-hippodrome-1364835690', 'Hippodrome of Constantinople', 1364835690),
    wp('wp-yenikapi-1357055213', 'Yenikapı', 1357055213),
    wp('wp-rumelihisari-1369216085', 'Rumelihisarı', 1369216085),
    # Dates for the Below layer's tunnels, drawn from OSM's underground rail.
    wp('wp-tunel-1352257712', 'Tünel', 1352257712),
    wp('wp-marmaray-1384706311', 'Marmaray', 1384706311),
    {
        'id': 'trwp-galata-surlari-36016150',
        'title': {'en': 'Galata Surları — Turkish Wikipedia (revision 36016150)',
                  'tr': 'Galata Surları — Vikipedi (36016150 numaralı sürüm)'},
        'url': 'https://tr.wikipedia.org/w/index.php?oldid=36016150',
        'author': {'en': 'Wikipedia contributors', 'tr': 'Vikipedi katkıcıları'},
        'accessedAt': '2026-11-10',
        'licence': {'en': 'CC BY-SA 4.0', 'tr': 'CC BY-SA 4.0'},
    },
    {
        'id': 'wikidata-historic-2026-11-10',
        'title': {'en': 'Wikidata: wall inventory and historic sites of the walled city (SPARQL, 10 November 2026)',
                  'tr': 'Wikidata: surlar envanteri ve tarihî yarımadanın yerleri (SPARQL, 10 Kasım 2026)'},
        'url': 'https://query.wikidata.org/',
        'author': {'en': 'Wikidata contributors', 'tr': 'Wikidata katkıcıları'},
        'accessedAt': '2026-11-10',
        'licence': {'en': 'CC0 1.0', 'tr': 'CC0 1.0'},
    },
    {
        'id': 'osm-walls-2026-11-10',
        'title': {'en': 'OpenStreetMap: city walls and gates of the walled city and Galata (Overpass, 10 November 2026)',
                  'tr': 'OpenStreetMap: tarihî yarımada ve Galata surları ile kapıları (Overpass, 10 Kasım 2026)'},
        'url': 'https://www.openstreetmap.org/copyright',
        'author': {'en': 'OpenStreetMap contributors', 'tr': 'OpenStreetMap katkıcıları'},
        'accessedAt': '2026-11-10',
        'licence': {'en': 'ODbL 1.0', 'tr': 'ODbL 1.0'},
    },
]

WALLS = 'wp-walls-of-constantinople-1383343183'
WD = 'wikidata-historic-2026-11-10'
OSM = 'osm-walls-2026-11-10'


def loc(en, tr):
    return {'en': en, 'tr': tr}


FEATURES = [
    # --- walls -------------------------------------------------------------
    dict(id='theodosian-land-walls', layer='walls', kind='land-wall',
         names=loc('Theodosian Walls', 'Theodosius Surları'),
         start=413, end=None, certainty='surviving', sources=[WALLS, WD],
         note=loc('Finished in 413 under Theodosius II. Drawn through the towers of the '
                  'inner wall as the Wikidata wall inventory records them, from the Sea of '
                  'Marmara to the Palace of the Porphyrogenitus.',
                  '413’te II. Theodosius döneminde tamamlandı. İç surun kuleleri üzerinden, '
                  'Wikidata sur envanterindeki konumlarıyla, Marmara’dan Tekfur Sarayı’na '
                  'kadar çizildi.'),
         line=[('wd', 'Q116046933'), ('towers', 'land', 1, 99)]),
    dict(id='blachernae-walls', layer='walls', kind='land-wall',
         names=loc('Wall of Manuel Komnenos', 'Manuel Komnenos Suru'),
         start=1180, end=None, certainty='traced', sources=[WALLS, WD, OSM],
         note=loc('Built by Manuel I Komnenos (r. 1143–1180) to protect the Palace of '
                  'Blachernae; shown here from the end of his reign. Drawn through its gates '
                  'to the Golden Horn. Before it, the northern end of the land walls lay on '
                  'another line that is not drawn.',
                  'I. Manuel Komnenos (h. 1143–1180) Blahernai Sarayı’nı korumak için yaptırdı; '
                  'burada saltanatının sonundan itibaren gösterilir. Kapıları üzerinden '
                  'Haliç’e kadar çizildi. Ondan önce kara surlarının kuzey ucu, çizilmeyen '
                  'başka bir hattaydı.'),
         line=[('towers', 'land', 99, 99), ('wd', 'Q122051355'), ('wd', 'Q135429327'),
               ('wd', 'Q135429326'), ('osm', 331862820, False),
               ('towers', 'golden-horn', 1, 1)]),
    dict(id='golden-horn-walls', layer='walls', kind='sea-wall',
         names=loc('Golden Horn Walls', 'Haliç Surları'),
         start=439, end=1870, certainty='approximate', sources=[WALLS, WD],
         note=loc('The sea walls are first recorded in 439, when the prefect Cyrus completed '
                  'them; most of the Golden Horn wall was demolished in the 1870s. Drawn '
                  'through the 21 towers Wikidata records, so long stretches between them '
                  'are straight lines; between Cibali and Sirkeci, where none is recorded, '
                  'two points are placed by hand behind the old shore.',
                  'Deniz surlarından ilk kez 439’da, şehir valisi Kyros onları tamamladığında '
                  'söz edilir; Haliç surlarının çoğu 1870’lerde yıkıldı. Wikidata’nın kaydettiği '
                  '21 kule üzerinden çizildi; aralarındaki uzun bölümler düz çizgidir. Kule '
                  'kaydı olmayan Cibali–Sirkeci arasında eski kıyının gerisine elle iki nokta '
                  'konuldu.'),
         line=[('towers', 'golden-horn', 1, 56), ('at', 41.0215, 28.9645),
               ('at', 41.0180, 28.9720), ('towers', 'golden-horn', 106, 107)]),
    dict(id='marmara-sea-walls', layer='walls', kind='sea-wall',
         names=loc('Marmara Sea Walls', 'Marmara Surları'),
         start=439, end=None, certainty='traced', sources=[WALLS, WD],
         note=loc('Completed by 439 along the shore of the Sea of Marmara; long stretches '
                  'still stand behind the coast road. Drawn through the towers Wikidata '
                  'records, from Seraglio Point to the Marble Tower.',
                  '439’a kadar Marmara kıyısı boyunca tamamlandı; uzun bölümleri sahil '
                  'yolunun arkasında hâlâ ayakta. Wikidata’nın kaydettiği kuleler üzerinden, '
                  'Sarayburnu’ndan Mermer Kule’ye kadar çizildi.'),
         line=[('towers', 'golden-horn', 107, 107), ('towers', 'marmara', 4, 98),
               ('wd', 'Q116046933')]),
    dict(id='constantinian-wall', layer='walls', kind='land-wall',
         names=loc('Wall of Constantine', 'Konstantin Suru'),
         start=330, end=867, certainty='conjectural', sources=[WALLS, WD],
         note=loc('Only its approximate course is known: from the Golden Horn near today’s '
                  'Atatürk Bridge, southwest and then south, east of the open cisterns of '
                  'Aspar and Mocius, to the Marmara between the sea gates of St Aemilianus '
                  'and Psamathia. The line is placed by those clues and passes west of the '
                  'Forum of Arcadius, the last forum inside it. A stretch is recorded '
                  'collapsing in an earthquake in 867.',
                  'Yalnızca yaklaşık güzergâhı biliniyor: bugünkü Atatürk Köprüsü yakınında '
                  'Haliç’ten güneybatıya, sonra güneye, Aspar ve Mokios açık sarnıçlarının '
                  'doğusundan geçerek Aziz Aemilianus ile Psamatya deniz kapıları arasında '
                  'Marmara’ya. Hat bu ipuçlarına göre yerleştirildi ve içindeki son forum olan '
                  'Arkadios Forumu’nun batısından geçer. Bir bölümünün 867’deki depremde '
                  'yıkıldığı kayıtlıdır.'),
         line=[('at', 41.0226, 28.9616), ('at', 41.0170, 28.9525), ('at', 41.0100, 28.9400),
               ('at', 41.0040, 28.9386), ('towers', 'marmara', 82, 82)]),
    dict(id='galata-walls', layer='walls', kind='land-wall',
         names=loc('Walls of Galata', 'Galata Surları'),
         start=1349, end=1864, certainty='conjectural',
         sources=['trwp-galata-surlari-36016150', 'wp-galata-tower-1384690717', OSM],
         note=loc('The Genoese colony’s walls, extended north in 1349, 1387, 1397 and 1404, '
                  'mostly demolished in 1864. Schematic: from the shore at Azapkapı through '
                  'the surviving fragments and the Galata Tower down towards Karaköy; the '
                  'shore ends are placed by hand.',
                  'Ceneviz kolonisinin surları; 1349, 1387, 1397 ve 1404’te kuzeye uzatıldı, '
                  'çoğu 1864’te yıkıldı. Şematik: Azapkapı kıyısından ayakta kalan parçalar ve '
                  'Galata Kulesi üzerinden Karaköy’e doğru; kıyıdaki uçlar elle yerleştirildi.'),
         line=[('at', 41.0250, 28.9675), ('osm', 708327980, False), ('osm', 708327979, False),
               ('place', 'galata-tower'), ('osm', 708327981, True), ('at', 41.0238, 28.9788)]),
    # Gates: land walls 413, Komnenian 1180, sea walls 439.
    *[dict(id=gid, layer='walls', kind='gate', names=names, start=start, end=None,
           certainty='surviving', sources=[WALLS, WD],
           note=loc('Position from Wikidata.', 'Konum Wikidata’dan.'), point=('wd', q))
      for gid, q, names, start in [
          ('golden-gate', 'Q592270', loc('Golden Gate', 'Altın Kapı'), 413),
          ('gate-of-xylokerkos', 'Q3908912', loc('Xylokerkos Gate (Belgrade Gate)', 'Belgrat Kapı'), 413),
          ('gate-of-the-spring', 'Q135479138', loc('Gate of the Spring (Silivri Gate)', 'Silivri Kapı'), 413),
          ('gate-of-rhegium', 'Q135429342', loc('Gate of Rhegium (Mevlevihane Gate)', 'Mevlevihane Kapı'), 413),
          ('gate-of-st-romanus', 'Q980626', loc('Gate of St Romanus (Topkapı)', 'Topkapı (Romanos Kapısı)'), 413),
          ('gate-of-charisius', 'Q135479137', loc('Gate of Charisius (Edirne Gate)', 'Edirnekapı'), 413),
          ('gate-of-kaligaria', 'Q122051355', loc('Gate of Kaligaria (Eğrikapı)', 'Eğrikapı'), 1180),
          ('gate-of-gyrolimne', 'Q135429327', loc('Gate of Gyrolimne', 'Gyrolimne Kapısı'), 1180),
          ('gate-ayakapi', 'Q121423111', loc('Ayakapı', 'Ayakapı'), 439),
          ('gate-cibali', 'Q135429340', loc('Cibali Gate', 'Cibali Kapısı'), 439),
          ('gate-samatya', 'Q135429341', loc('Psamathia Gate (Samatya)', 'Samatya Kapısı'), 439),
          ('gate-ahirkapi', 'Q135429338', loc('Ahırkapı', 'Ahırkapı'), 439),
      ]],

    # --- coast -------------------------------------------------------------
    dict(id='harbour-of-theodosius', layer='coast', kind='water-then',
         names=loc('Harbour of Theodosius', 'Theodosius Limanı'),
         start=330, end=1100, certainty='conjectural',
         sources=['wp-harbour-of-eleutherios-1354353475', 'wp-yenikapi-1357055213', WD],
         note=loc('Built in the late 4th century at the mouth of the Lycus and used until the '
                  'eleventh; silt from the stream then filled it. Its basin was found at '
                  'Yenikapı during the Marmaray works. The outline is schematic, around the '
                  'position Wikidata gives.',
                  '4. yüzyılın sonunda Likos deresinin ağzında yapıldı, 11. yüzyıla kadar '
                  'kullanıldı; sonra derenin getirdiği alüvyonla doldu. Havzası Marmaray '
                  'çalışmalarında Yenikapı’da bulundu. Sınır şematiktir, Wikidata’nın verdiği '
                  'konumun çevresinde.'),
         polygon=[('at', 41.0068, 28.9472), ('at', 41.0073, 28.9535), ('at', 41.0061, 28.9570),
                  ('at', 41.0040, 28.9574), ('at', 41.0031, 28.9520), ('at', 41.0040, 28.9476)]),
    dict(id='harbour-of-julian', layer='coast', kind='water-then',
         names=loc('Harbour of Julian (Kadırga)', 'Julianus Limanı (Kadırga)'),
         start=362, end=1750, certainty='conjectural',
         sources=['wp-kontoskalion-1336379705', WD],
         note=loc('Built by Julian in 362 and renamed after the empress Sophia; the Ottoman '
                  'galley harbour of Kadırga. It decayed after 1515 and was filled with the '
                  'earth dug for the Nuruosmaniye Mosque from 1748. Outline schematic.',
                  '362’de Julianus yaptırdı, sonra İmparatoriçe Sophia’nın adını aldı; Osmanlı’nın '
                  'Kadırga Limanı. 1515’ten sonra geriledi ve 1748’den itibaren Nuruosmaniye '
                  'Camii için kazılan toprakla dolduruldu. Sınır şematiktir.'),
         polygon=[('at', 41.0047, 28.9672), ('at', 41.0050, 28.9705), ('at', 41.0035, 28.9722),
                  ('at', 41.0022, 28.9708), ('at', 41.0024, 28.9676)]),

    # --- streets and forums ------------------------------------------------
    dict(id='mese', layer='streets', kind='street',
         names=loc('Mese', 'Mese'), start=330, end=1453, certainty='approximate',
         sources=['wp-mese-1333909142', WD],
         note=loc('The main street, 25 metres wide and colonnaded, from the Milion through the '
                  'forums of Constantine and Theodosius to the Philadelphion. Drawn as '
                  'straight lines between those positions.',
                  'Milion’dan Konstantin ve Theodosius forumlarından geçip Philadelphion’a '
                  'uzanan, 25 metre genişliğinde, revaklı ana cadde. Bu konumlar arasında düz '
                  'çizgilerle çizildi.'),
         line=[('place', 'milion'), ('wd', 'Q1231380'), ('wd', 'Q1247291'), ('wd', 'Q548109')]),
    dict(id='mese-north', layer='streets', kind='street',
         names=loc('Mese, northern branch', 'Mese, kuzey kolu'), start=413, end=1453,
         certainty='approximate', sources=['wp-mese-1333909142', WD],
         note=loc('Past the Theodosian forum the Mese divided: this branch ran northwest past '
                  'the Church of the Holy Apostles (where the Fatih Mosque stands) to the Gate '
                  'of Charisius.',
                  'Theodosius Forumu’ndan sonra Mese ikiye ayrılırdı: bu kol kuzeybatıya, Havariler '
                  'Kilisesi’nin (bugün Fatih Camii’nin) önünden Kharisios Kapısı’na giderdi.'),
         line=[('wd', 'Q548109'), ('place', 'fatih-mosque'), ('wd', 'Q135479137')]),
    dict(id='mese-south', layer='streets', kind='street',
         names=loc('Mese, southern branch', 'Mese, güney kolu'), start=413, end=1453,
         certainty='approximate', sources=['wp-mese-1333909142', WD],
         note=loc('The other branch ran southwest through the Forum of the Ox and the Forum of '
                  'Arcadius to the Golden Gate, where it joined the Via Egnatia.',
                  'Diğer kol güneybatıya, Bous ve Arkadios forumlarından geçip Altın Kapı’ya '
                  'giderek Via Egnatia’ya bağlanırdı.'),
         line=[('wd', 'Q548109'), ('wd', 'Q4845769'), ('wd', 'Q1247271'), ('wd', 'Q592270')]),
    *[dict(id=fid, layer='streets', kind='forum', names=names, start=start, end=end,
           certainty='traced', sources=[src, WD], note=note, point=('wd', q))
      for fid, q, names, start, end, src, note in [
          ('augustaion', 'Q1187380', loc('Augustaion', 'Augusteion'), 330, 1453,
           'wp-augustaion-1266611461',
           loc('The ceremonial square before Hagia Sophia; it survived until the late '
               'Byzantine period, in ruins.',
               'Ayasofya’nın önündeki tören meydanı; geç Bizans dönemine kadar, harap hâlde de '
               'olsa ayakta kaldı.')),
          ('forum-of-constantine', 'Q1231380', loc('Forum of Constantine', 'Konstantin Forumu'),
           330, 1453, 'wp-forum-of-constantine-1253152892',
           loc('Built at the foundation of the city, round, with the Column of Constantine at '
               'its centre; the column still stands.',
               'Şehrin kuruluşunda yapıldı; yuvarlaktı, ortasında Çemberlitaş vardı. Sütun hâlâ '
               'ayakta.')),
          ('forum-of-theodosius', 'Q1247291', loc('Forum of Theodosius', 'Theodosius Forumu'),
           393, 1453, 'wp-forum-of-theodosius-1307424872',
           loc('Constantine’s Forum of the Bull, rebuilt and renamed for Theodosius I in 393; '
               'today Beyazıt Square.',
               'Konstantin’in Boğa Forumu; 393’te I. Theodosius için yeniden yapılıp adı '
               'değiştirildi. Bugün Beyazıt Meydanı.')),
          ('philadelphion', 'Q548109', loc('Philadelphion', 'Philadelphion'), 330, 1453,
           'wp-philadelphion-1222481634',
           loc('The square where the Mese forked.', 'Mese’nin ikiye ayrıldığı meydan.')),
          ('forum-of-the-ox', 'Q4845769', loc('Forum of the Ox', 'Bous Forumu'), 330, 1453,
           'wp-forum-of-the-ox-1270066911',
           loc('A square in the Lycus valley on the southern Mese; it disappeared completely '
               'after the end of the Byzantine Empire. Its founding date is not known.',
               'Güney Mese üzerinde, Likos vadisinde bir meydan; Bizans’ın sonundan sonra '
               'tamamen kayboldu. Kuruluş tarihi bilinmiyor.')),
          ('forum-of-arcadius', 'Q1247271', loc('Forum of Arcadius', 'Arkadios Forumu'),
           403, 1453, 'wp-forum-of-arcadius-1383265770',
           loc('Built in 403 on the Xerolophos, the last forum before the Constantinian wall.',
               '403’te Kserolofos tepesinde yapıldı; Konstantin Suru’ndan önceki son forum.')),
      ]],

    # --- hills -------------------------------------------------------------
    *[dict(id=f'hill-{n}', layer='hills', kind='hill', names=loc(numeral, numeral),
           start=-700, end=None, certainty='approximate',
           sources=['wp-seven-hills-1374999074', WD], note=note, point=ref)
      for n, numeral, ref, note in [
          (1, 'I', ('place', 'hagia-sophia'),
           loc('The first hill, where Byzantium was founded: Seraglio Point, Hagia Sophia, '
               'the Topkapı Palace.',
               'Bizantion’un kurulduğu birinci tepe: Sarayburnu, Ayasofya, Topkapı Sarayı.')),
          (2, 'II', ('place', 'column-of-constantine'),
           loc('The second hill: the Column of Constantine, the Grand Bazaar, Nuruosmaniye.',
               'İkinci tepe: Çemberlitaş, Kapalıçarşı, Nuruosmaniye.')),
          (3, 'III', ('place', 'suleymaniye'),
           loc('The third hill: Istanbul University, the Bayezid II and Süleymaniye mosques.',
               'Üçüncü tepe: İstanbul Üniversitesi, Beyazıt ve Süleymaniye camileri.')),
          (4, 'IV', ('place', 'fatih-mosque'),
           loc('The fourth hill: the Church of the Holy Apostles, then the Fatih Mosque.',
               'Dördüncü tepe: Havariler Kilisesi, sonra Fatih Camii.')),
          (5, 'V', ('label', 'Yavuz Selim Mosque'),
           loc('The fifth hill: the Mosque of Sultan Selim.', 'Beşinci tepe: Yavuz Selim Camii.')),
          (6, 'VI', ('place', 'mihrimah-edirnekapi'),
           loc('The sixth hill: Edirnekapı and the Mihrimah Sultan Mosque.',
               'Altıncı tepe: Edirnekapı ve Mihrimah Sultan Camii.')),
          (7, 'VII', ('wd', 'Q776353'),
           loc('The seventh hill, the Xerolophos or “dry hill”, marked here by the base of '
               'the Column of Arcadius.',
               'Yedinci tepe, Kserolofos ya da “kuru tepe”; burada Arkadios Sütunu’nun '
               'kaidesiyle gösterildi.')),
      ]],

    # --- 1453 --------------------------------------------------------------
    dict(id='siege-chain', layer='siege1453', kind='siege',
         names=loc('The chain across the Golden Horn', 'Haliç zinciri'),
         start=1453, end=1453, certainty='approximate',
         sources=[WALLS, 'wp-fall-of-constantinople-1384652386', WD],
         note=loc('A chain on floating barrels closed the Golden Horn, from the Tower of '
                  'Eugenius at Sirkeci to the Kastellion in Galata, whose basement became the '
                  'Yeraltı Mosque.',
                  'Yüzen fıçılar üzerindeki bir zincir Haliç’i kapattı: Sirkeci’deki Eugenios '
                  'Kulesi’nden, bodrumu sonra Yeraltı Camii olan Galata’daki Kastellion’a.'),
         line=[('wd', 'Q133817567'), ('wd', 'Q12885210')]),
    dict(id='siege-ships', layer='siege1453', kind='siege',
         names=loc('The fleet dragged overland, 22 April', 'Karadan yürütülen donanma, 22 Nisan'),
         start=1453, end=1453, certainty='conjectural',
         sources=['wp-fall-of-constantinople-1384652386'],
         note=loc('Mehmed had a road of greased logs built across Galata and dragged his ships '
                  'over the hill into the Golden Horn, bypassing the chain. The source gives no '
                  'exact route; this line, from the Bosphorus shore to Kasımpaşa, is schematic.',
                  'Mehmed Galata’nın arkasına yağlanmış kütüklerden bir yol yaptırdı ve '
                  'gemilerini tepenin üzerinden Haliç’e indirerek zinciri aştı. Kaynak kesin '
                  'güzergâh vermiyor; Boğaz kıyısından Kasımpaşa’ya uzanan bu çizgi şematiktir.'),
         line=[('at', 41.0300, 28.9875), ('at', 41.0345, 28.9800), ('at', 41.0352, 28.9730),
               ('at', 41.0322, 28.9668)]),
    dict(id='siege-mesoteichion', layer='siege1453', kind='siege',
         names=loc('Mesoteichion: the guns and the Janissaries', 'Mesoteikhion: toplar ve yeniçeriler'),
         start=1453, end=1453, certainty='traced',
         sources=['wp-fall-of-constantinople-1384652386', WALLS, WD],
         note=loc('The stretch of the land walls in the Lycus valley, from the Gate of St '
                  'Romanus to the Gate of Charisius. Mehmed pitched his tent near it, where the '
                  'guns and the elite Janissary regiments stood.',
                  'Kara surlarının Likos vadisindeki bölümü, Romanos Kapısı’ndan Kharisios '
                  'Kapısı’na. Mehmed çadırını toplar ve seçkin yeniçeri birliklerinin bulunduğu '
                  'bu kesimin yakınına kurdu.'),
         line=[('towers', 'land', 66, 86)]),
    dict(id='rumeli-hisari-1452', layer='siege1453', kind='siege',
         names=loc('Rumeli Hisarı, built 1452', 'Rumeli Hisarı, 1452'),
         start=1452, end=1453, certainty='surviving',
         sources=['wp-rumelihisari-1369216085'],
         note=loc('Built by Mehmed II in 1452 to close the Bosphorus before the siege.',
                  'II. Mehmed, kuşatmadan önce Boğaz’ı kapatmak için 1452’de yaptırdı.'),
         point=('place', 'rumeli-hisari')),

    # --- below -------------------------------------------------------------
    dict(id='below-basilica-cistern', layer='below', kind='cistern',
         names=loc('Basilica Cistern', 'Yerebatan Sarnıcı'), start=532, end=None,
         certainty='surviving', sources=['wp-basilica-cistern-1365846547', WD],
         note=loc('Built under Justinian I in the 6th century; shown from 532.',
                  'VI. yüzyılda I. Justinianus döneminde yapıldı; 532’den itibaren gösterilir.'),
         point=('place', 'basilica-cistern')),
    dict(id='below-philoxenos', layer='below', kind='cistern',
         names=loc('Cistern of Philoxenos', 'Binbirdirek Sarnıcı'), start=450, end=None,
         certainty='surviving', sources=['wp-cistern-of-philoxenos-1365179166', WD],
         note=loc('Built under a palace in the 5th century; shown from 450.',
                  'V. yüzyılda bir sarayın altına yapıldı; 450’den itibaren gösterilir.'),
         point=('place', 'binbirdirek')),
    dict(id='below-theodosius-cistern', layer='below', kind='cistern',
         names=loc('Theodosius Cistern', 'Şerefiye Sarnıcı'), start=443, end=None,
         certainty='surviving', sources=['wp-theodosius-cistern-1365081953', WD],
         note=loc('Built 428–443.', '428–443 yılları arasında yapıldı.'),
         point=('place', 'theodosius-cistern')),
    dict(id='below-great-palace', layer='below', kind='substructure',
         names=loc('Great Palace terraces', 'Büyük Saray terasları'), start=330, end=None,
         certainty='approximate', sources=['wp-great-palace-1369328015', WD],
         note=loc('The palace descended some 33 m from the Hippodrome to the shore on six '
                  'terraces carried on substructures and vaults. Outline through the Chalke, '
                  'the Magnaura, the Ahırkapı gate and the Boukoleon.',
                  'Saray Hipodrom’dan kıyıya yaklaşık 33 m, altyapılar ve tonozlar üzerinde '
                  'altı terasla inerdi. Sınır Khalke, Magnaura, Ahırkapı ve Bukoleon üzerinden.'),
         polygon=[('wd', 'Q2724254'), ('wd', 'Q2630180'), ('wd', 'Q135429338'),
                  ('wd', 'Q133493236'), ('wd', 'Q1003322')]),
    dict(id='below-sphendone', layer='below', kind='substructure',
         names=loc('Sphendone of the Hippodrome', 'Hipodrom Sfendonu'), start=330, end=None,
         certainty='surviving', sources=['wp-hippodrome-1364835690', OSM],
         note=loc('The curved southern end of the Hippodrome, whose vaulted lower part still '
                  'survives. Line as surveyed in OpenStreetMap.',
                  'Hipodrom’un kavisli güney ucu; tonozlu alt kısmı hâlâ ayakta. Çizgi '
                  'OpenStreetMap ölçümünden.'),
         line=[('osm', 321386212, False)]),
    dict(id='below-anemas', layer='below', kind='substructure',
         names=loc('Anemas Dungeons', 'Anemas Zindanları'), start=1107, end=None,
         certainty='surviving', sources=[WALLS, WD],
         note=loc('Vaulted chambers in the walls at Blachernae, named after Michael Anemas, '
                  'imprisoned there in the early 12th century.',
                  'Blahernai’de surların içindeki tonozlu odalar; 12. yüzyılın başında burada '
                  'hapsedilen Mikhail Anemas’ın adını taşır.'),
         point=('place', 'anemas-prisons')),
    dict(id='below-yenikapi', layer='below', kind='excavation',
         names=loc('Yenikapı excavation', 'Yenikapı kazısı'), start=2004, end=None,
         certainty='approximate',
         sources=['wp-yenikapi-1357055213', 'wp-harbour-of-eleutherios-1354353475', WD],
         note=loc('Found in 2004 while building the Marmaray and metro station: the silted '
                  'Harbour of Theodosius and its shipwrecks. Outline schematic, around the '
                  'transfer centre.',
                  '2004’te Marmaray ve metro istasyonu yapılırken bulundu: dolmuş Theodosius '
                  'Limanı ve batıkları. Sınır şematiktir, aktarma merkezinin çevresinde.'),
         polygon=[('at', 41.0068, 28.9488), ('at', 41.0066, 28.9545), ('at', 41.0046, 28.9548),
                  ('at', 41.0044, 28.9486)]),
]
