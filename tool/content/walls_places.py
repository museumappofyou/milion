"""Usage: python3.11 tool/content/walls_places.py

P15's authored inputs for tool/content/build_walls.py: writes
studio/walls/sources.json, places.json, milestones.json and routes.json.
Every line is checked against the research log kept in
studio/cache/p15/research/claims.jsonl (gitignored): figures that log
corrects (the moat's 10 m, the gun's seven shots a day, Grant the Scot)
are said its way, and what it marks disputed or legend is said so here.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STUDIO = ROOT / 'studio/walls'


def loc(en, tr):
    return {'en': en, 'tr': tr}


def source(id, title, url, author, accessed, licence=None):
    return dict(id=id, title=title, url=url, author=author, accessedAt=accessed,
                licence=licence)


PD = loc('Public domain', 'Kamu malı')
WP = loc('Wikipedia contributors', 'Wikipedia katkıcıları')
BYSA = loc('CC BY-SA 4.0', 'CC BY-SA 4.0')


def wp(slug, title, rev, accessed='2026-11-20'):
    return source(f'wp-{slug}-{rev}',
                  loc(f'{title} — Wikipedia (revision {rev})',
                      f'{title} — Wikipedia ({rev} numaralı sürüm)'),
                  f'https://en.wikipedia.org/w/index.php?oldid={rev}', WP, accessed, BYSA)


SOURCES = [
    source('van-millingen-1899',
           loc('Byzantine Constantinople: The Walls of the City and Adjoining Historical Sites '
               '(London, 1899)',
               'Byzantine Constantinople: The Walls of the City and Adjoining Historical Sites '
               '(Londra, 1899)'),
           'https://archive.org/details/byzantineconstan00vanm',
           loc('Alexander van Millingen', 'Alexander van Millingen'), '2026-11-20', PD),
    source('byzleg-theodosian-walls', loc('Theodosian Walls', 'Theodosius Surları'),
           'https://www.thebyzantinelegacy.com/theodosian-walls',
           loc('David Hendrix, The Byzantine Legacy', 'David Hendrix, The Byzantine Legacy'),
           '2026-11-20'),
    source('doukas-magoulias-1975',
           loc('Decline and Fall of Byzantium to the Ottoman Turks, an annotated translation of '
               'the Historia Turco-Byzantina by Harry J. Magoulias (Detroit, 1975)',
               'Decline and Fall of Byzantium to the Ottoman Turks; Historia Turco-Byzantina’nın '
               'Harry J. Magoulias’ın notlu çevirisi (Detroit, 1975)'),
           'https://archive.org/details/doukas_decline_fall_byzantium_to_ottoman_turks',
           loc('Doukas; trans. Harry J. Magoulias', 'Dukas; çev. Harry J. Magoulias'),
           '2026-11-20'),
    source('barbaro-1856',
           loc('Giornale dell’assedio di Costantinopoli 1453, ed. Enrico Cornet (Vienna, 1856)',
               'Giornale dell’assedio di Costantinopoli 1453, yay. Enrico Cornet (Viyana, 1856)'),
           'https://archive.org/details/giornale-dell-assedio-di-costantinopoli-1453-1856',
           loc('Nicolò Barbaro; ed. Enrico Cornet', 'Nicolò Barbaro; yay. Enrico Cornet'),
           '2026-11-20', PD),
    source('pears-1903',
           loc('The Destruction of the Greek Empire and the Story of the Capture of '
               'Constantinople by the Turks (London, 1903)',
               'The Destruction of the Greek Empire and the Story of the Capture of '
               'Constantinople by the Turks (Londra, 1903)'),
           'https://archive.org/details/destructionofgre00pear',
           loc('Edwin Pears', 'Edwin Pears'), '2026-11-20', PD),
    wp('fall-of-constantinople', 'Fall of Constantinople', 1386410654),
    wp('johannes-grant', 'Johannes Grant', 1368880213),
    wp('basilic', 'Basilic (cannon)', 1368250139),
    wp('historic-areas-of-istanbul', 'Historic Areas of Istanbul', 1382728989),
    wp('anadoluhisari', 'Anadoluhisarı', 1365021404),
    source('ktb-rumeli-hisari',
           loc('İstanbul Rumeli Hisarı Fortress Museum (Turkish Museums portal)',
               'İstanbul Rumeli Hisarı Müzesi (Türkiye Müzeleri portalı)'),
           'https://turkishmuseums.com/museum/detail/2077-istanbul-rumeli-hisari-fortress-museum/2077/4',
           loc('Republic of Türkiye Ministry of Culture and Tourism',
               'T.C. Kültür ve Turizm Bakanlığı'), '2026-11-20'),
    source('kritoboulos-muller-1870',
           loc('Kritoboulos, Historiae (Greek text), in Fragmenta Historicorum Graecorum V.1, '
               'ed. Karl Müller (Paris, 1870)',
               'Kritobulos, Historiae (Grekçe metin), Fragmenta Historicorum Graecorum V.1, '
               'yay. Karl Müller (Paris, 1870)'),
           'https://archive.org/details/fragmentahistori05unse',
           loc('Kritoboulos of Imbros; ed. Karl Müller', 'İmrozlu Kritobulos; yay. Karl Müller'),
           '2026-11-20', PD),
    source('apz-atsiz-1949',
           loc('Âşıkpaşaoğlu Ahmed Âşıkî, Tevârih-i Âl-i Osman, chapter 123, in Osmanlı '
               'Tarihleri I, ed. Çiftçioğlu Nihal Atsız (Istanbul, 1949)',
               'Âşıkpaşaoğlu Ahmed Âşıkî, Tevârih-i Âl-i Osman, 123. bab, Osmanlı Tarihleri I, '
               'yay. Çiftçioğlu Nihal Atsız (İstanbul, 1949)'),
           'https://archive.org/details/OsmanlTarihleri',
           loc('Âşıkpaşaoğlu; ed. Nihal Atsız', 'Âşıkpaşaoğlu; yay. Nihal Atsız'),
           '2026-11-20'),
    source('eclipsewise-1453-05-22',
           loc('Partial Lunar Eclipse of 1453 May 22 (EclipseWise)',
               '22 Mayıs 1453 kısmi ay tutulması (EclipseWise)'),
           'https://www.eclipsewise.com/lunar/LEprime/1401-1500/LE1453May22Pprime.html',
           loc('Fred Espenak', 'Fred Espenak'), '2026-11-20'),
]

SOURCES += [
    wp('yedikule-fortress', 'Yedikule Fortress', 1374719027),
    wp('palace-of-the-porphyrogenitus', 'Palace of the Porphyrogenitus', 1365989313),
    wp('prison-of-anemas', 'Prison of Anemas', 1311891019),
    source('byzleg-porphyrogenitus', loc('Palace of the Porphyrogenitus', 'Porphyrogennetos Sarayı'),
           'https://www.thebyzantinelegacy.com/porphyrogenitus',
           loc('David Hendrix, The Byzantine Legacy', 'David Hendrix, The Byzantine Legacy'),
           '2026-11-20'),
    source('byzleg-sea-walls', loc('Sea Walls', 'Deniz Surları'),
           'https://www.thebyzantinelegacy.com/sea-walls',
           loc('David Hendrix, The Byzantine Legacy', 'David Hendrix, The Byzantine Legacy'),
           '2026-11-20'),
    source('ibb-tekfur',
           loc('Tekfur Palace (Istanbul Metropolitan Municipality, Directorate of Libraries and '
               'Museums)',
               'Tekfur Sarayı (İBB Kütüphane ve Müzeler Müdürlüğü)'),
           'https://ataturkkitapligi.ibb.gov.tr/en/Kitaplik/Muzelerimiz/Tekfur-Palace/10',
           loc('Istanbul Metropolitan Municipality', 'İstanbul Büyükşehir Belediyesi'), '2026-11-20'),
    source('trthaber-yedikule-2026',
           loc('Yedikule Hisarı’ndaki Hazine Kulesi’nde restorasyon sürüyor (TRT Haber, 5 August 2026)',
               'Yedikule Hisarı’ndaki Hazine Kulesi’nde restorasyon sürüyor (TRT Haber, 5 Ağustos 2026)'),
           'https://www.trthaber.com/haber/kultur-sanat/yedikule-hisarindaki-hazine-kulesinde-restorasyon-suruyor-953158.html',
           loc('TRT Haber', 'TRT Haber'), '2026-11-20'),
    source('tgrthaber-anemas-2025',
           loc('Karanlık odaları ve ürkütücü atmosferi Bizans döneminden kaldı (TGRT Haber, '
               '9 May 2025)',
               'Karanlık odaları ve ürkütücü atmosferi Bizans döneminden kaldı (TGRT Haber, '
               '9 Mayıs 2025)'),
           'https://www.tgrthaber.com/mavikadin/karanlik-odalari-ve-urkutucu-atmosferi-bizans-doneminden-kaldi',
           loc('TGRT Haber', 'TGRT Haber'), '2026-11-20'),
    source('cumhuriyet-anadolu-hisari-2022',
           loc('İBB, Anadolu Hisarı’nda restorasyon çalışmalarına başladı (Cumhuriyet, 9 March 2022)',
               'İBB, Anadolu Hisarı’nda restorasyon çalışmalarına başladı (Cumhuriyet, 9 Mart 2022)'),
           'https://www.cumhuriyet.com.tr/kultur-sanat/ibb-anadolu-hisarinda-restorasyon-calismalarina-basladi-1914260',
           loc('Cumhuriyet', 'Cumhuriyet'), '2026-11-20'),
    source('lepetitjournal-walls-2013',
           loc('Les murailles de Théodose II, un patrimoine en danger (Le Petit Journal Istanbul, '
               '9 April 2013)',
               'Les murailles de Théodose II, un patrimoine en danger (Le Petit Journal İstanbul, '
               '9 Nisan 2013)'),
           'https://lepetitjournal.com/istanbul/actualites/les-murailles-de-theodose-ii-un-patrimoine-en-danger-82867',
           loc('Le Petit Journal Istanbul', 'Le Petit Journal İstanbul'), '2026-11-20'),
    source('commons-tavernier-1455',
           loc('File:Siege of Constantinople BnF MS Fr 9087.jpg (Jean Le Tavernier’s miniature, Lille, '
               '1455; Bibliothèque nationale de France, MS fr. 9087, fol. 207v)',
               'Dosya: Siege of Constantinople BnF MS Fr 9087.jpg (Jean Le Tavernier’in minyatürü, '
               'Lille, 1455; Fransa Ulusal Kütüphanesi, MS fr. 9087, yk. 207v)'),
           'https://commons.wikimedia.org/wiki/File:Siege_of_Constantinople_BnF_MS_Fr_9087.jpg',
           loc('Jean Le Tavernier; Bibliothèque nationale de France; Wikimedia Commons',
               'Jean Le Tavernier; Fransa Ulusal Kütüphanesi; Wikimedia Commons'), '2026-11-20', PD),
    source('commons-mevlanakapi',
           loc('File:Outside walls at Mevlana Kapı 5457.jpg (description page)',
               'Dosya: Outside walls at Mevlana Kapı 5457.jpg (açıklama sayfası)'),
           'https://commons.wikimedia.org/wiki/File:Outside_walls_at_Mevlana_Kap%C4%B1_5457.jpg',
           loc('Dosseman (photographer), Wikimedia Commons', 'Dosseman (fotoğrafçı), Wikimedia Commons'),
           '2026-11-20', BYSA),
    source('commons-golden-gate',
           loc('File:Istanbul Yedikule exterior Golden Gate side 3110.jpg (description page)',
               'Dosya: Istanbul Yedikule exterior Golden Gate side 3110.jpg (açıklama sayfası)'),
           'https://commons.wikimedia.org/wiki/File:Istanbul_Yedikule_exterior_Golden_Gate_side_3110.jpg',
           loc('Dosseman (photographer), Wikimedia Commons', 'Dosseman (fotoğrafçı), Wikimedia Commons'),
           '2026-11-20', BYSA),
    source('commons-topkapi',
           loc('File:Istanbul Wall outside Topkapı gate 3067.jpg (description page)',
               'Dosya: Istanbul Wall outside Topkapı gate 3067.jpg (açıklama sayfası)'),
           'https://commons.wikimedia.org/wiki/File:Istanbul_Wall_outside_Topkap%C4%B1_gate_3067.jpg',
           loc('Dosseman (photographer), Wikimedia Commons', 'Dosseman (fotoğrafçı), Wikimedia Commons'),
           '2026-11-20', BYSA),
    source('osm-node-11254781787',
           loc('OpenStreetMap node 11254781787 (gate in Yedikule’s outline, beside the museum)',
               'OpenStreetMap düğümü 11254781787 (Yedikule’nin çevresinde, müzenin yanındaki kapı)'),
           'https://www.openstreetmap.org/node/11254781787',
           loc('OpenStreetMap contributors', 'OpenStreetMap katkıcıları'), '2026-11-20',
           loc('ODbL 1.0', 'ODbL 1.0')),
]


def stratum(id, era, years, anchor, title, en, tr, sources):
    start, end = years
    return dict(id=id, fromYear=start, toYear=end, era=era, title=title,
                body=dict(en='\n\n'.join(en), tr='\n\n'.join(tr)), media=[], sources=sources,
                anchorYear=anchor)


WALLS = ['van-millingen-1899', 'wp-walls-of-constantinople-1383343183']

PLACES = [
    dict(id='land-walls', strata=[
        stratum('lw-heritage', 'modern', (1985, None), 1985,
                loc('World Heritage, and rebuilt, 1985–', 'Dünya Mirası ve yeniden yapım, 1985–'),
                ['In 1985 the land walls became one of the four parts of the World Heritage Site '
                 '“Historic Areas of Istanbul”.',
                 'From the 1980s to the mid-2000s long stretches were rebuilt. The work was widely '
                 'criticised for taking down and replacing original masonry with new; what you '
                 'see is often a modern rebuilding on the old line.'],
                ['1985’te kara surları, “İstanbul’un Tarihî Alanları” Dünya Mirası alanının dört '
                 'bölümünden biri oldu.',
                 '1980’lerden 2000’lerin ortasına kadar uzun kesimler yeniden yapıldı. Çalışmalar, '
                 'özgün duvarları söküp yenisiyle değiştirdiği için geniş çapta eleştirildi; '
                 'görülen çoğu zaman eski hat üzerinde modern bir yeniden yapımdır.'],
                ['whc-istanbul', 'wp-historic-areas-of-istanbul-1382728989',
                 'byzleg-theodosian-walls', 'lepetitjournal-walls-2013']),
        stratum('lw-ottoman', 'ottoman', (1453, 1985), 1458,
                loc('Repaired, then outgrown, 1453–1985', 'Onarıldı, sonra aşıldı, 1453–1985'),
                ['After the conquest Mehmed II had the walls repaired, and in about 1457–58 built '
                 'Yedikule around the Golden Gate. Ottoman repair inscriptions run on through the '
                 '17th and 18th centuries.',
                 'The sea walls went first. The railway of 1871 cut through the Marmara walls, '
                 'the Golden Horn walls were lost bit by bit to streets and quays in the 19th '
                 'century, and the coastal road of the late 1950s took more of the Marmara side.'],
                ['Fetihten sonra II. Mehmed surları onarttı ve 1457–58 dolaylarında Altınkapı’nın '
                 'çevresine Yedikule’yi yaptırdı. Osmanlı onarım yazıtları 17. ve 18. yüzyıla '
                 'kadar sürer.',
                 'Önce deniz surları gitti. 1871 demiryolu Marmara surlarını yardı, Haliç surları '
                 '19. yüzyılda yollar ve rıhtımlar için parça parça yok oldu, 1950’lerin sonundaki '
                 'sahil yolu Marmara tarafından daha fazlasını aldı.'],
                WALLS + ['byzleg-theodosian-walls', 'byzleg-sea-walls']),
        stratum('lw-1453', 'byzantine', (1453, 1453), 1453,
                loc('The siege of 1453', '1453 kuşatması'),
                ['From 6 April to 29 May 1453 Mehmed II’s guns battered the land walls, hardest in '
                 'the Lycus valley, where the defenders patched the broken outer wall each night '
                 'with a stockade. The last assault broke through there on 29 May.',
                 'Milestone XIX follows the 53 days on the map, with the accounts of each side.'],
                ['6 Nisan–29 Mayıs 1453 arasında II. Mehmed’in topları kara surlarını dövdü; en '
                 'çok da savunanların yıkılan dış suru her gece bir şarampoleyle yamadığı Likos '
                 'vadisinde. Son saldırı 29 Mayıs’ta orada yarma açtı.',
                 'XIX. Kilometre Taşı 53 günü haritada, iki tarafın anlatılarıyla izler.'],
                ['pears-1903', 'barbaro-1856', 'van-millingen-1899']),
        stratum('lw-medieval', 'byzantine', (627, 1453), 1150,
                loc('Blachernae and the long repairs, 7th–15th century',
                    'Blakherna ve uzun onarımlar, 7.–15. yüzyıl'),
                ['North of the Theodosian line the wall was rebuilt as a single wall without a '
                 'moat: under Heraclius after 626, Leo V in 813 and above all Manuel I Komnenos '
                 '(1143–1180), who pushed it out around the Blachernae palace. Theophilos rebuilt '
                 'the sea walls in the 830s and put his name on them more than any other emperor.',
                 'Repairs are dated on the walls down to John VIII Palaiologos in the late 1430s. '
                 'On 25 July 1261 the troops of Alexios Strategopoulos got in through the Gate of '
                 'the Spring and took the city back from the Latins.'],
                ['Theodosius hattının kuzeyinde sur, hendeksiz tek bir sur olarak yeniden yapıldı: '
                 '626’dan sonra Herakleios, 813’te V. Leon ve en çok da surları Blakherna Sarayı’nın '
                 'çevresine genişleten I. Manuel Komnenos (1143–1180) döneminde. Theophilos 830’larda '
                 'deniz surlarını yeniden yaptırdı ve adını surlara her imparatordan çok yazdırdı.',
                 'Onarımlar surların üzerinde VIII. İoannes Palaiologos’un 1430’ların sonuna kadar '
                 'tarihlenir. 25 Temmuz 1261’de Aleksios Strategopulos’un askerleri Pege Kapısı’ndan '
                 'girip şehri Latinlerden geri aldı.'],
                WALLS + ['byzleg-theodosian-walls', 'byzleg-sea-walls']),
        stratum('lw-447', 'byzantine', (447, 447), 447,
                loc('Sixty days, 447', 'Altmış gün, 447'),
                ['On 6 November 447 an earthquake threw down much of the new wall, 57 towers among '
                 'it, while Attila’s Huns were ravaging the Balkans. The prefect Constantine had it '
                 'rebuilt within about two months with the help of the circus factions; Greek and '
                 'Latin inscriptions at Mevlanakapı say so.',
                 'Most scholars date the outer wall and the moat to this rebuilding; some argue they '
                 'were planned with the inner wall from the start.'],
                ['6 Kasım 447’de bir deprem, Attila’nın Hunları Balkanlar’ı yağmalarken, yeni surun '
                 'büyük kısmını ve 57 kulesini yıktı. Vali Konstantinos, hipodrom gruplarının da '
                 'yardımıyla, surları iki ay kadar içinde yeniden yaptırdı; Mevlanakapı’daki Grekçe '
                 've Latince yazıtlar bunu anlatır.',
                 'Araştırmacıların çoğu dış suru ve hendeği bu onarıma tarihler; bazıları ise '
                 'bunların baştan iç surla birlikte tasarlandığını savunur.'],
                ['van-millingen-1899', 'byzleg-theodosian-walls',
                 'wp-walls-of-constantinople-1383343183']),
        stratum('lw-theodosian', 'byzantine', (405, 439), 413,
                loc('Theodosius II’s wall, 413', 'II. Theodosius’un suru, 413'),
                ['The inner wall was built for the boy emperor Theodosius II by the praetorian '
                 'prefect Anthemius, about 1.5 km west of Constantine’s wall, and was finished by '
                 '413. In 439 the prefect Cyrus carried the sea walls along the Marmara and the '
                 'Golden Horn round to meet it.',
                 'The land walls run about 5.7 km from the Marble Tower on the Marmara to the '
                 'Palace of the Porphyrogenitus, and some 6.5 km to the Golden Horn: moat, '
                 'breastwork, outer terrace, outer wall, peribolos and the inner wall with 96 great '
                 'towers, a belt about 60 m deep. Milestone XVIII draws it as one strip.'],
                ['İç sur, çocuk imparator II. Theodosius için praetorium valisi Anthemius tarafından, '
                 'Konstantin’in surunun yaklaşık 1,5 km batısına yapıldı ve 413’e kadar bitirildi. '
                 '439’da vali Kyros, Marmara ve Haliç boyunca uzanan deniz surlarını ona kadar '
                 'getirdi.',
                 'Kara surları Marmara kıyısındaki Mermer Kule’den Porphyrogennetos Sarayı’na '
                 'yaklaşık 5,7 km, Haliç’e kadar 6,5 km kadar uzanır: hendek, göğüs duvarı, dış '
                 'teras, dış sur, peribolos ve 96 büyük kuleli iç sur; yaklaşık 60 m derinliğinde '
                 'bir kuşak. XVIII. Kilometre Taşı onu tek bir şerit olarak çizer.'],
                ['van-millingen-1899', 'byzleg-theodosian-walls',
                 'wp-walls-of-constantinople-1383343183']),
    ], review=dict(
        note='Walls of Constantinople promoted to reviewed (P15), checked remotely on 2026-11-20. '
             'An open-air monument with no single entrance: the pin is the Gate of St Romanus '
             '(Topkapı), Wikidata’s point, where the walk’s first two sections meet. A walk along '
             'the line stays open.',
        review='reviewed',
        entrance={'lat': 41.021655, 'lng': 28.926297},
        status={'value': 'open', 'checkedAt': '2026-11-20'},
        currentFunction=loc(
            'An open-air monument: the moat, the terraces and the gates are open ground; towers '
            'and wall-walks are often fenced off or under restoration.',
            'Açık hava anıtı: hendek, teraslar ve kapılar açık alandır; kuleler ve sur '
            'yürüyüş yolları çoğu zaman çitle kapalı ya da onarımdadır.'),
        hook=loc('Moat, two walls and 96 great towers, from the Marmara to the Golden Horn.',
                 'Hendek, iki sur ve 96 büyük kule; Marmara’dan Haliç’e.'),
        visit=dict(
            checkedAt='2026-11-20',
            hours=loc('Open air, with no gate or ticket. Some towers and stretches are fenced for '
                      'restoration.',
                      'Açık hava; giriş kapısı ya da bilet yok. Bazı kuleler ve kesimler onarım için '
                      'çitle kapatılmıştır.'),
            hoursCheckedAt='2026-11-20',
            entry=loc('Reach the line at any of its gates. Stay on the paths, do not climb the '
                      'walls, and walk the quieter stretches in daylight.',
                      'Hatta kapılarının herhangi birinden ulaşılır. Patikalarda kalın, surlara '
                      'tırmanmayın ve tenha kesimleri gün ışığında yürüyün.'),
            etiquette=None, accessibility=None, transit=[],
            sources=['wikidata-historic-2026-11-10', 'lepetitjournal-walls-2013',
                     'trthaber-yedikule-2026']),
        tags=['entrance-remote'],
        sources=['van-millingen-1899', 'byzleg-theodosian-walls', 'whc-istanbul'])),

    dict(id='yedikule', strata=[
        stratum('yk-museum', 'modern', (1895, None), 2020,
                loc('A museum, and a restoration site', 'Bir müze ve bir onarım alanı'),
                ['The fortress became a museum; the sources give 1895 and 1935, perhaps an Ottoman '
                 'and a Republican opening.',
                 'Since 2020 the Fatih municipality has been restoring it, the Treasury Tower among '
                 'its works, and it has stayed open to visitors as an open restoration site.'],
                ['Hisar bir müze oldu; kaynaklar 1895 ve 1935 yıllarını verir, belki biri Osmanlı '
                 'biri Cumhuriyet dönemindeki açılıştır.',
                 'Fatih Belediyesi 2020’den beri Hazine Kulesi dahil hisarı onarıyor; hisar açık bir '
                 'restorasyon alanı olarak ziyarete açık kaldı.'],
                ['wp-yedikule-fortress-1374719027', 'trthaber-yedikule-2026']),
        stratum('yk-ottoman', 'ottoman', (1457, 1895), 1458,
                loc('The Seven Towers, 1457–58', 'Yedi Kule, 1457–58'),
                ['In about 1457–58 Mehmed II joined three new towers and curtain walls to four '
                 'towers of the Theodosian wall, two of them the Golden Gate’s, and made a '
                 'fortress of seven towers. It held the treasury, until that moved to Topkapı in '
                 'the 16th century, then archives and a state prison.',
                 'The young sultan Osman II was killed here by the Janissaries in May 1622; the last '
                 'prisoner left in 1837.'],
                ['II. Mehmed 1457–58 dolaylarında, Theodosius surunun ikisi Altınkapı’nın olan dört '
                 'kulesine üç yeni kule ve beden duvarları ekleyip yedi kuleli bir hisar yaptı. '
                 'Hisar 16. yüzyılda Topkapı’ya taşınana kadar hazineyi, sonra arşivleri ve bir '
                 'devlet zindanını barındırdı.',
                 'Genç padişah II. Osman Mayıs 1622’de burada Yeniçeriler tarafından öldürüldü; son '
                 'mahkûm 1837’de çıktı.'],
                ['wp-yedikule-fortress-1374719027', 'wp-walls-of-constantinople-1383343183',
                 'byzleg-theodosian-walls']),
        stratum('yk-golden-gate', 'byzantine', (388, 1453), 1389,
                loc('The Golden Gate', 'Altınkapı'),
                ['The Golden Gate, a triple marble arch between two marble towers, was the '
                 'emperors’ gate for triumphs; it is dated either to Theodosius I (388–391) or to '
                 'Theodosius II’s wall. The last triumph through it was Michael VIII’s on 15 '
                 'August 1261.',
                 'John V Palaiologos made a fort of it in 1389–90 and had to raze it in 1391 when '
                 'the Ottoman sultan Bayezid I demanded it.'],
                ['Altınkapı, iki mermer kule arasında üç açıklıklı bir mermer kemer, imparatorların '
                 'zafer kapısıydı; I. Theodosius’a (388–391) ya da II. Theodosius’un suruna '
                 'tarihlenir. Son zafer alayı 15 Ağustos 1261’de VIII. Mikhael’inkiydi.',
                 'V. İoannes Palaiologos 1389–90’da onu bir kaleye çevirdi; 1391’de Osmanlı sultanı '
                 'I. Bayezid isteyince yıktırmak zorunda kaldı.'],
                WALLS + ['byzleg-theodosian-walls']),
    ], review=dict(
        note='Yedikule promoted to reviewed (P15), checked remotely on 2026-11-20. The entrance '
             'pin is an OpenStreetMap gate in the fortress outline beside its museum node, on the '
             'city side. Open during its restoration by an August 2026 report; no official hours '
             'page was found. A site visit stays open.',
        review='reviewed',
        entrance={'lat': 40.9934924, 'lng': 28.923915},
        status={'value': 'open', 'checkedAt': '2026-11-20'},
        currentFunction=loc('A museum, open while its restoration goes on.',
                            'Onarımı süren, ziyarete açık bir müze.'),
        hook=loc('Mehmed II’s seven-towered treasury, built round the emperors’ Golden Gate.',
                 'II. Mehmed’in yedi kuleli hazinesi; imparatorların Altınkapı’sının çevresine '
                 'kuruldu.'),
        visit=dict(
            checkedAt='2026-11-20',
            hours=loc('Open to visitors during the restoration, by a report of August 2026. No '
                      'official hours were found: check before you go.',
                      'Ağustos 2026 tarihli bir habere göre onarım sürerken ziyarete açık. Resmî '
                      'saatler bulunamadı: gitmeden önce kontrol edin.'),
            hoursCheckedAt='2026-11-20',
            entry=None, etiquette=None, accessibility=None, transit=[],
            sources=['trthaber-yedikule-2026', 'osm-node-11254781787']),
        tags=['entrance-remote'],
        sources=['wp-yedikule-fortress-1374719027', 'trthaber-yedikule-2026'])),

    dict(id='tekfur-palace', strata=[
        stratum('tk-museum', 'modern', (1955, None), 2019,
                loc('Restored, rebuilt, a museum', 'Onarıldı, yeniden yapıldı, müze oldu'),
                ['The palace was restored in 1955–70. Excavations from 1995 found the kilns of its '
                 'Ottoman tile workshop. A reconstruction in the 2010s, criticised as heavy-handed, '
                 'roofed and rebuilt it, and it opened as a museum of the municipality in 2019.',
                 'It shows the Tekfur Sarayı tiles found on the site.'],
                ['Saray 1955–70’te onarıldı. 1995’ten itibaren yapılan kazılar Osmanlı çini '
                 'atölyesinin fırınlarını buldu. 2010’larda ağır bulunarak eleştirilen bir yeniden '
                 'yapım onu çatısıyla yeniden kurdu; 2019’da belediyenin müzesi olarak açıldı.',
                 'Alanda bulunan Tekfur Sarayı çinilerini sergiler.'],
                ['byzleg-porphyrogenitus', 'ibb-tekfur',
                 'wp-palace-of-the-porphyrogenitus-1365989313']),
        stratum('tk-workshop', 'ottoman', (1453, 1955), 1719,
                loc('Menagerie, poorhouse, kilns', 'Hayvanat bahçesi, yoksul evi, fırınlar'),
                ['After 1453 the palace kept the sultan’s menagerie in the 16th century and later '
                 'housed a Jewish poorhouse until a fire in 1864.',
                 'In 1719, under Ahmed III, a tile workshop was set up in its courtyard, with five '
                 'kilns, to revive İznik’s craft; Tekfur Sarayı tiles went into the Fountain of '
                 'Ahmed III (1728) and the Hekimoğlu Ali Pasha Mosque (1734). Glass was made here in '
                 'the 18th and early 19th centuries.'],
                ['1453’ten sonra saray 16. yüzyılda padişahın hayvanlarını barındırdı, sonra 1864’teki '
                 'bir yangına kadar bir Yahudi yoksul evi oldu.',
                 '1719’da, III. Ahmed döneminde, avlusunda İznik zanaatini canlandırmak için beş '
                 'fırınlı bir çini atölyesi kuruldu; Tekfur Sarayı çinileri III. Ahmed Çeşmesi’ne '
                 '(1728) ve Hekimoğlu Ali Paşa Camii’ne (1734) gitti. 18. yüzyılda ve 19. yüzyılın '
                 'başında burada cam da yapıldı.'],
                ['byzleg-porphyrogenitus', 'wp-palace-of-the-porphyrogenitus-1365989313',
                 'ibb-tekfur']),
        stratum('tk-palace', 'byzantine', (1261, 1453), 1291,
                loc('A palace between the walls', 'Surlar arasında bir saray'),
                ['Built in the late 13th century, about 1261–91 by one reading, as a wing of the '
                 'Blachernae palace, between the inner and outer walls where the Theodosian line '
                 'ends.',
                 'Its name comes from Kritoboulos, who called it the palace of the '
                 'Porphyrogenitus; it is linked to Constantine, a son of Michael VIII. Its banded '
                 'brick and stone front is one of the best-kept pieces of late Byzantine '
                 'palace building.'],
                ['13. yüzyılın sonunda, bir okumaya göre 1261–91 dolaylarında, Blakherna Sarayı’nın '
                 'bir kanadı olarak, Theodosius hattının bittiği yerde iç ve dış sur arasına '
                 'yapıldı.',
                 'Adını, onu Porphyrogennetos’un sarayı diye anan Kritobulos’tan alır; VIII. '
                 'Mikhael’in oğlu Konstantinos’la ilişkilendirilir. Tuğla ve taş bantlı cephesi, '
                 'geç Bizans saray mimarisinin en iyi korunmuş örneklerinden biridir.'],
                ['byzleg-porphyrogenitus', 'wp-palace-of-the-porphyrogenitus-1365989313',
                 'van-millingen-1899']),
    ], review=dict(
        note='Tekfur Sarayı checked remotely on 2026-11-20 (P15) and kept a draft: the museum’s '
             'hours are from the municipality’s page, but no entrance could be pinned from '
             'OpenStreetMap. A site visit stays open.',
        review='draft',
        status={'value': 'open', 'checkedAt': '2026-11-20'},
        visit=dict(
            checkedAt='2026-11-20',
            hours=loc('Tuesday to Sunday 10:00–18:00; closed on Mondays (the municipality’s page).',
                      'Salı–pazar 10.00–18.00; pazartesi kapalı (belediyenin sayfası).'),
            hoursCheckedAt='2026-11-20',
            weekly=[{'days': ['tue', 'wed', 'thu', 'fri', 'sat', 'sun'], 'opens': '10:00',
                     'closes': '18:00'}],
            entry=None, etiquette=None, accessibility=None, transit=[],
            sources=['ibb-tekfur']),
        sources=['byzleg-porphyrogenitus', 'ibb-tekfur'])),

    dict(id='anemas-prisons', strata=[
        stratum('an-today', 'modern', (1899, None), 2025,
                loc('A name in question', 'Sorgulanan bir ad'),
                ['Van Millingen found the two towers built in the wrong order for the names they '
                 'carry, and the vaulted rooms may have been substructures of the Blachernae palace '
                 'terrace rather than cells. The traditional name stays in use.',
                 'By a report of May 2025 the building was still not fully open; visits needed '
                 'permission or a guided tour.'],
                ['Van Millingen, iki kulenin taşıdıkları adlara göre ters sırayla yapıldığını '
                 'buldu; tonozlu odalar hücre değil, Blakherna Sarayı terasının alt yapıları '
                 'olabilir. Geleneksel ad kullanılmaya devam ediyor.',
                 'Mayıs 2025 tarihli bir habere göre yapı hâlâ tam olarak ziyarete açılmamıştı; '
                 'ziyaret izin ya da rehberli tur gerektiriyordu.'],
                ['van-millingen-1899', 'wp-prison-of-anemas-1311891019',
                 'tgrthaber-anemas-2025']),
        stratum('an-prison', 'byzantine', (1105, 1453), 1376,
                loc('The prison of Anemas, by tradition', 'Geleneğe göre Anemas zindanı'),
                ['Under the Blachernae terrace, inside an outer wall up to 23 m high, are twelve '
                 'vaulted compartments. Tradition names them after Michael Anemas, who plotted '
                 'against Alexios I Komnenos around 1105 and was the first held here.',
                 'Andronikos I was held in 1185. In the 1370s Andronikos IV was imprisoned by his '
                 'father John V, escaped, and then held John V and his sons here himself.'],
                ['Blakherna terasının altında, yüksekliği 23 m’yi bulan bir dış surun içinde on iki '
                 'tonozlu bölme vardır. Gelenek onlara, 1105 dolaylarında I. Aleksios Komnenos’a '
                 'karşı komplo kuran ve burada tutulan ilk kişi olan Mikhael Anemas’ın adını verir.',
                 'I. Andronikos 1185’te burada tutuldu. 1370’lerde IV. Andronikos babası V. İoannes '
                 'tarafından hapsedildi, kaçtı ve sonra V. İoannes’i oğullarıyla birlikte burada '
                 'kendisi hapsetti.'],
                ['van-millingen-1899', 'wp-prison-of-anemas-1311891019']),
    ], review=dict(
        note='Anemas checked remotely on 2026-11-20 (P15) and kept a draft: a May 2025 report says '
             'it is not fully open, and no official page was found.',
        review='draft',
        sources=['van-millingen-1899', 'wp-prison-of-anemas-1311891019'])),

    dict(id='rumeli-hisari', strata=[
        stratum('rh-museum', 'modern', (1953, None), 1958,
                loc('Restored for the 500th year', '500. yıl için onarıldı'),
                ['Restored from 1953 to 1958 for the five-hundredth anniversary of the conquest, '
                 'it became a museum; the sources give 1960 and 1968 for the opening. Concerts are '
                 'held in its open court.',
                 'A popular story says its plan spells the names Muhammad and Mehmed in Arabic '
                 'letters. It is a legend: no evidence supports it, and the plan follows the '
                 'steep ground.'],
                ['Fethin beş yüzüncü yılı için 1953–1958 arasında onarıldı ve müze oldu; kaynaklar '
                 'açılış için 1960 ve 1968 yıllarını verir. Açık avlusunda konserler yapılır.',
                 'Yaygın bir hikâyeye göre planı Arap harfleriyle Muhammed ve Mehmed adlarını yazar. '
                 'Bu bir efsanedir: destekleyen bir kanıt yok; plan dik araziyi izler.'],
                ['ktb-rumeli-hisari', 'wp-rumelihisari-1369216085']),
        stratum('rh-ottoman', 'ottoman', (1453, 1953), 1746,
                loc('A prison and a fire', 'Bir zindan ve bir yangın'),
                ['After 1453 the fortress lost its purpose and served from the 16th century as a '
                 'state prison.',
                 'A fire in 1746 damaged it, and it was repaired under Selim III.'],
                ['1453’ten sonra hisar işlevini yitirdi ve 16. yüzyıldan itibaren devlet zindanı '
                 'olarak kullanıldı.',
                 '1746’da bir yangın hisara zarar verdi; III. Selim döneminde onarıldı.'],
                ['ktb-rumeli-hisari']),
        stratum('rh-1452', 'ottoman', (1452, 1453), 1452,
                loc('The strait-cutter, 1452', 'Boğazkesen, 1452'),
                ['Mehmed II built it on the European shore where the Bosphorus is narrowest, '
                 'opposite his great-grandfather’s Anadolu Hisarı, from March to August 1452. Its '
                 'three great towers carry the names of the viziers who built them: Çandarlı Halil '
                 'Pasha’s by the shore, Zağanos Pasha’s to the south and Saruca Pasha’s to the '
                 'north, the tallest at about 28 m.',
                 'Doukas calls it Baş-kesen. That winter its guns sank a Venetian ship that would '
                 'not lower sail. With the fortress opposite, the strait was closed to the city’s '
                 'help from the Black Sea.'],
                ['II. Mehmed onu Mart–Ağustos 1452’de, Boğaz’ın en dar yerinde, büyük dedesinin '
                 'Anadolu Hisarı’nın karşısına, Avrupa yakasına yaptırdı. Üç büyük kulesi onları '
                 'yaptıran vezirlerin adını taşır: kıyıdaki Çandarlı Halil Paşa, güneydeki Zağanos '
                 'Paşa ve kuzeydeki, yaklaşık 28 m ile en yükseği olan Saruca Paşa kulesi.',
                 'Dukas ona Baş-kesen der. O kış topları, yelken indirmeyen bir Venedik gemisini '
                 'batırdı. Karşıdaki hisarla birlikte Boğaz, şehre Karadeniz’den gelecek yardıma '
                 'kapandı.'],
                ['ktb-rumeli-hisari', 'barbaro-1856', 'doukas-magoulias-1975',
                 'wp-rumelihisari-1369216085']),
    ], review=dict(
        note='Rumeli Hisarı checked remotely on 2026-11-20 (P15) and kept a draft: the hours are '
             'the Ministry’s, but no entrance could be pinned from OpenStreetMap.',
        review='draft',
        status={'value': 'open', 'checkedAt': '2026-11-20'},
        visit=dict(
            checkedAt='2026-11-20',
            hours=loc('Closed on Mondays; 09:00–19:30 in summer and 09:00–17:00 in winter (the '
                      'Ministry’s page).',
                      'Pazartesi kapalı; yazın 09.00–19.30, kışın 09.00–17.00 (Bakanlığın sayfası).'),
            hoursCheckedAt='2026-11-20',
            entry=None, etiquette=None, accessibility=None, transit=[],
            sources=['ktb-rumeli-hisari']),
        sources=['ktb-rumeli-hisari', 'wp-rumelihisari-1369216085'])),

    dict(id='anadolu-hisari', strata=[
        stratum('ah-restoration', 'modern', (1991, None), 2022,
                loc('Closed, then restored', 'Kapalı kaldı, sonra onarıldı'),
                ['After a restoration in 1991–93 the fortress stayed closed to visitors for some '
                 'thirty years.',
                 'The Istanbul municipality began restoring it in 2021–22 and opened it to visitors '
                 'during the works; its present opening was not confirmed.'],
                ['1991–93’teki bir onarımdan sonra hisar yaklaşık otuz yıl ziyarete kapalı kaldı.',
                 'İstanbul Büyükşehir Belediyesi 2021–22’de onarıma başladı ve hisarı çalışmalar '
                 'sürerken ziyarete açtı; bugünkü durumu doğrulanamadı.'],
                ['cumhuriyet-anadolu-hisari-2022', 'wp-anadoluhisari-1365021404']),
        stratum('ah-1390s', 'ottoman', (1390, 1991), 1394,
                loc('Bayezid I’s fortress, 1390s', 'I. Bayezid’in hisarı, 1390’lar'),
                ['Bayezid I built the fortress, once called Güzelce Hisar, on the Asian shore in '
                 'the 1390s, round a main tower about 25 m high.',
                 'Before 1453 Mehmed II gave it outer walls; with Rumeli Hisarı across the water it '
                 'closed the strait.'],
                ['Bir zamanlar Güzelce Hisar diye anılan hisarı I. Bayezid 1390’larda Anadolu '
                 'yakasına, yaklaşık 25 m yüksekliğinde bir ana kulenin çevresine yaptırdı.',
                 '1453’ten önce II. Mehmed ona dış surlar ekletti; suyun karşısındaki Rumeli '
                 'Hisarı’yla birlikte Boğaz’ı kapattı.'],
                ['wp-anadoluhisari-1365021404', 'cumhuriyet-anadolu-hisari-2022']),
    ], review=dict(
        note='Anadolu Hisarı checked remotely on 2026-11-20 (P15) and kept a draft: the latest '
             'report read is from 2022.',
        review='draft',
        sources=['wp-anadoluhisari-1365021404']))
]

MILESTONES = [
    dict(id='milestone-xviii', places=['land-walls'],
         sources=['van-millingen-1899', 'byzleg-theodosian-walls',
                  'wp-walls-of-constantinople-1383343183', 'wikidata-historic-2026-11-10',
                  'commons-golden-gate', 'commons-mevlanakapi', 'commons-topkapi'],
         techniques=['PU', 'SB'], manifestPath='assets/walls/land-walls/strip.json',
         honesty=['ORIGINAL', 'RECONSTRUCTION', 'IMAGINED'], status='prototype'),
    dict(id='milestone-xix', places=['land-walls', 'golden-horn'],
         sources=['barbaro-1856', 'doukas-magoulias-1975', 'kritoboulos-muller-1870',
                  'apz-atsiz-1949', 'pears-1903', 'commons-tavernier-1455'],
         techniques=['TM', 'SB'], manifestPath='assets/siege/1453/siege.json',
         honesty=['ORIGINAL', 'RECONSTRUCTION', 'IMAGINED'], status='prototype'),
]

ROUTE_SOURCES = ['wikidata-historic-2026-11-10', 'wp-walls-of-constantinople-1383343183']
ROUTES = [
    dict(id='walls-1-marmara-topkapi',
         title=loc('Walk the walls, 1: the Marmara to Topkapı',
                   'Surları yürü, 1: Marmara’dan Topkapı’ya'),
         body=loc('About 3.9 km along the wall from the Marble Tower on the Marmara: the Golden '
                  'Gate and Yedikule, Belgradkapı, Silivrikapı and Mevlanakapı with its 447 '
                  'inscriptions, to Topkapı.',
                  'Marmara kıyısındaki Mermer Kule’den sur boyunca yaklaşık 3,9 km: Altınkapı ve '
                  'Yedikule, Belgradkapı, Silivrikapı ve 447 yazıtlı Mevlanakapı’dan Topkapı’ya.'),
         places=['land-walls', 'yedikule'], sources=ROUTE_SOURCES),
    dict(id='walls-2-topkapi-edirnekapi',
         title=loc('Walk the walls, 2: Topkapı to Edirnekapı',
                   'Surları yürü, 2: Topkapı’dan Edirnekapı’ya'),
         body=loc('About 1.2 km down into the Lycus valley, where the walls were broken in 1453, '
                  'and up to Edirnekapı, the highest gate. Two busy roads cross the line.',
                  '1453’te surların yarıldığı Likos vadisine inen ve en yüksek kapı Edirnekapı’ya '
                  'çıkan yaklaşık 1,2 km. Hattı iki işlek cadde keser.'),
         places=['land-walls'], sources=ROUTE_SOURCES + ['byzleg-theodosian-walls']),
    dict(id='walls-3-edirnekapi-ayvansaray',
         title=loc('Walk the walls, 3: Edirnekapı to the Golden Horn',
                   'Surları yürü, 3: Edirnekapı’dan Haliç’e'),
         body=loc('About 1.5 km past the Palace of the Porphyrogenitus, the wall of Manuel '
                  'Komnenos with Eğrikapı and the Anemas complex, down to the Golden Horn at '
                  'Ayvansaray. Steep in places.',
                  'Porphyrogennetos Sarayı, Eğrikapı’lı Manuel Komnenos suru ve Anemas yapıları '
                  'boyunca, Ayvansaray’da Haliç’e inen yaklaşık 1,5 km. Yer yer dik.'),
         places=['land-walls', 'tekfur-palace', 'anemas-prisons'], sources=ROUTE_SOURCES),
]


def write(name, records, note):
    STUDIO.mkdir(parents=True, exist_ok=True)
    (STUDIO / name).write_text(json.dumps(dict(note=note, records=records), ensure_ascii=False,
                                          indent=1) + '\n', encoding='utf-8')


def main():
    write('sources.json', SOURCES,
          'P15: the sources the walls’ places, Milestone XVIII’s strip and XIX’s map cite. '
          'Pages read on 2026-11-20; the research log is studio/cache/p15/research/claims.jsonl.')
    write('places.json', PLACES,
          'P15: dated strata for the six places, newest first. Land walls and Yedikule are '
          'reviewed remotely with pinned entrances; Tekfur Sarayı, Rumeli Hisarı, the Anemas '
          'prisons and Anadolu Hisarı stay drafts with what could be checked.')
    write('milestones.json', MILESTONES,
          'P15: XVIII (tool/walls/build_strip.py) and XIX (tool/siege/build_siege.py) take their '
          'path, status and honesty here.')
    write('routes.json', ROUTES,
          'P15: the “Walk the walls” seed for P21, three sections; lengths along the strip’s line.')


if __name__ == '__main__':
    main()
