"""Usage: python3 tool/content/build_dig.py — writes the first dig layers.

Run after build_seed.py (it patches its place records). Offline and
deterministic. Writes:
  - assets/content/places/istanbul.json: Chora's six layers and visit card,
    Hagia Sophia's two draft layers;
  - assets/content/sources/dig.json: the new pinned sources;
  - assets/content/index.json: registers the new sources document.

Authored 2026-10-07; historical and visit corrections audited 2026-10-08. The place
records stay `draft`: the dig layers and the visit card are individually
sourced, while the P11/P12 wave reviews still own entrance, status and the
full artwork review (P04 Decisions, P05 Decisions).
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / 'assets/content'
DATE = '2026-10-07'
AUDIT_DATE = '2026-10-08'


def loc(en, tr):
    return dict(en=en, tr=tr)


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')


def src(id, en, tr, url, author, author_tr, licence=None, accessed_at=DATE):
    return dict(id=id, title=loc(en, tr), url=url, author=loc(author, author_tr),
                accessedAt=accessed_at, licence=None if licence is None else loc(licence, licence))


SOURCES = [
    src('muze-kariye',
        'Kariye Mosque — Müze İstanbul (visiting information)',
        'Kariye Camii — Müze İstanbul (ziyaret bilgileri)',
        'https://muze.gen.tr/muze-detay/kariye',
        'Müze İstanbul', 'Müze İstanbul', accessed_at=AUDIT_DATE),
    src('ousterhout-introduction',
        'The Kariye Camii: An Introduction — history, decoration and architecture',
        'The Kariye Camii: An Introduction — tarih, bezeme ve mimari',
        'https://www.columbia.edu/cu/wallach/exhibitions/Byzantium/pdf/ousterhout_intro.pdf',
        'Robert G. Ousterhout', 'Robert G. Ousterhout', accessed_at=AUDIT_DATE),
    src('aa-kariye-postponed-2020',
        'Kariye Mosque opening postponed — 29 October 2020',
        'Kariye Camisi’nin açılışı ertelendi — 29 Ekim 2020',
        'https://www.aa.com.tr/tr/turkiye/kariye-camisinin-acilisi-ertelendi/2023331',
        'Anadolu Agency, reporting the Diyanet announcement',
        'Anadolu Ajansı, Diyanet açıklaması', accessed_at=AUDIT_DATE),
    src('sozcu-kariye-2024',
        'Kariye Mosque: the paid-visit period began (AA-DHA)',
        'Kariye Camii’nde ücretli giriş dönemi başladı (AA-DHA)',
        'https://www.sozcu.com.tr/kariye-camii-nin-hangi-gunler-ziyarete-acik-olacak-tarihi-camide-ucretli-giris-donemi-basladi-p76376',
        'Sözcü (AA, DHA)', 'Sözcü (AA, DHA)'),
    src('cumhuriyet-kariye-2024',
        'Where is Kariye Mosque and how do you get there?',
        'Kariye Camii nerede, Kariye Camii’ye nasıl gidilir?',
        'https://www.cumhuriyet.com.tr/yasam/kariye-camii-nerede-kariye-camiiye-nasil-gidilir-2233106',
        'Cumhuriyet', 'Cumhuriyet'),
    src('daily-sabah-kariye-2024',
        'Kariye Mosque: the restoration and heritage preservation unveiled',
        'Kariye Camii: restorasyon ve mirasın korunması',
        'https://www.dailysabah.com/arts/kariye-mosque-triumph-of-restoration-heritage-preservation-unveiled-in-istanbul/news',
        'Daily Sabah with Agencies', 'Daily Sabah, Ajanslar'),
    src('hyperallergic-kariye-2024',
        'Istanbul church reopens as mosque with medieval mosaics and frescoes intact',
        'İstanbul’daki kilise, ortaçağ mozaik ve freskleri yerinde kalarak cami olarak yeniden açıldı',
        'https://hyperallergic.com/istanbul-chora-church-reopens-as-mosque-with-medieval-mosaics-and-frescoes-intact',
        'Jennifer Hattam, Hyperallergic', 'Jennifer Hattam, Hyperallergic'),
    src('chora-museum',
        'Chora Museum Istanbul — history',
        'Chora Museum Istanbul — tarihçe',
        'https://www.choramuseum.com/',
        'choramuseum.com', 'choramuseum.com'),
    src('smarthistory-hagia-sophia',
        'Hagia Sophia, Istanbul',
        'Ayasofya, İstanbul',
        'https://smarthistory.org/hagia-sophia/',
        'Smarthistory', 'Smarthistory'),
    src('britannica-hagia-sophia',
        'Hagia Sophia',
        'Ayasofya',
        'https://www.britannica.com/topic/Hagia-Sophia',
        'Encyclopaedia Britannica', 'Encyclopaedia Britannica'),
    src('whc-istanbul',
        'Historic Areas of Istanbul — World Heritage List 356',
        'İstanbul’un Tarihi Alanları — Dünya Mirası Listesi 356',
        'https://whc.unesco.org/en/list/356/',
        'UNESCO World Heritage Centre', 'UNESCO Dünya Mirası Merkezi'),
]

# --- Chora: six layers, newest first; anchors are the gauge years. ---
CHORA_VISIT = dict(
    checkedAt=AUDIT_DATE,
    hours=loc(
        'Daily except Friday, 09:00–18:00; box office until 17:55. Tourist '
        'visits pause during prayers; admission stops fifteen minutes before '
        'each prayer.',
        'Cuma hariç her gün 09.00–18.00; gişe 17.55’e kadar açık. Namaz '
        'sırasında turistik ziyaret yapılamaz; her namazdan on beş dakika '
        'önce ziyaretçi girişi durur.'),
    hoursCheckedAt=AUDIT_DATE,
    entry=loc(
        'Foreign visitors pay €20; Turkish citizens and worshippers enter '
        'free. Museum Passes are not accepted. The route starts at the north '
        'gate on Kariye Türbesi Street and passes a security check.',
        'Yabancı ziyaretçiler 20 avro öder; Türk vatandaşları ve ibadet '
        'edenler ücretsiz girer. Müze kartları geçmez. Güzergâh, Kariye '
        'Türbesi Sokağı’ndaki kuzey kapısından başlar; girişte güvenlik '
        'kontrolü vardır.'),
    etiquette=loc(
        'An active mosque: shoes come off in the prayer areas, women cover '
        'their heads, shorts are not allowed and flash is forbidden. Head '
        'and body coverings are sold at the ticket booth.',
        'Etkin bir cami: ibadet alanlarında ayakkabı çıkarılır, kadınlar '
        'başını örter, şort giyilmez ve flaş kullanılamaz. Baş ve vücut '
        'örtüleri gişede satılır.'),
    accessibility=None,
    transit=[
        dict(kind='tram', stop=loc('T4 Edirnekapı', 'T4 Edirnekapı'),
             minutes=10),
        dict(kind='metrobus', stop=loc('Metrobüs Edirnekapı', 'Metrobüs Edirnekapı'),
             minutes=5),
    ],
    sources=['muze-kariye', 'sozcu-kariye-2024', 'cumhuriyet-kariye-2024'],
)

CHORA_STRATA = [
    dict(
        id='kariye-mosque-today', fromYear=2020, toYear=None, anchorYear=2026,
        era='modern',
        title=loc('The mosque again, 2020–', 'Yeniden cami, 2020–'),
        body=loc(
            'On 21 August 2020 a presidential decree returned the building to '
            'the Directorate of Religious Affairs. A reopening planned for '
            '30 October 2020 was postponed, as Diyanet announced on '
            '29 October.\n\n'
            'A four-year conservation programme followed. The mosque reopened '
            'on 6 May 2024: the narthex cycles, the parekklesion frescoes, '
            'and much of the decoration are again on view. The three naos '
            'mosaics are behind curtains in the prayer area; visibility '
            'outside prayer times still needs an on-site check.\n\n'
            'Since 19 August 2024 foreign visitors pay €20 at the door; '
            'Turkish citizens and worshippers enter free. Fridays are '
            'reserved for worship, and entry pauses about fifteen minutes '
            'before each prayer.',
            '21 Ağustos 2020 tarihli kararnameyle yapı Diyanet İşleri '
            'Başkanlığı’na devredildi. 30 Ekim 2020 için planlanan açılış, '
            'Diyanet’in 29 Ekim’deki açıklamasıyla ertelendi.\n\n'
            'Ardından dört yıllık bir koruma programı yürütüldü. Cami 6 '
            'Mayıs 2024’te yeniden açıldı: narteks döngüleri, pareklezyon '
            'freskleri ve bezemenin büyük bölümü yeniden görülebiliyor. '
            'İbadet alanındaki üç naos mozaiği perde arkasında; namaz '
            'dışında görülebilirliği yerinde doğrulanmayı bekliyor.\n\n'
            '19 Ağustos 2024’ten beri yabancı ziyaretçiler kapıda 20 avro '
            'ödüyor; Türk vatandaşları ve ibadet edenler ücretsiz giriyor. '
            'Cuma günleri ibadete ayrılıyor ve her namazdan yaklaşık on beş '
            'dakika önce giriş durduruluyor.'),
        media=['anastasis-original'],
        artworks=[],
        sources=['muze-kariye', 'hyperallergic-kariye-2024',
                 'daily-sabah-kariye-2024', 'aa-kariye-postponed-2020', 'wd-q849489'],
    ),
    dict(
        id='museum-years', fromYear=1945, toYear=2020, anchorYear=1948,
        era='modern',
        title=loc('Museum and restoration, 1945–2020',
                  'Müze ve restorasyon yılları, 1945–2020'),
        body=loc(
            'In 1945 a cabinet decree made the mosque a national monument; '
            'from 1948 the Byzantine Institute of America, under Thomas '
            'Whittemore and then Paul A. Underwood, removed the plaster and '
            'whitewash from the mosaics and frescoes. The work continued to '
            '1958, when Kariye opened as a museum.\n\n'
            'The cleaning brought back the narthex cycles — the Deesis, the '
            'two domes with the ancestors of Christ and of the Virgin — and, '
            'in the parekklesion, the Anastasis and the Last Judgment, all '
            'documented in Underwood’s preliminary reports for Dumbarton '
            'Oaks.\n\n'
            'The museum years lasted until 2020. The legal road back to a '
            'mosque began in 2005 with a foundation’s lawsuit; in November '
            '2019 the Council of State ruled for reconversion, and the '
            'decree followed in August 2020.',
            '1945’te Bakanlar Kurulu kararıyla yapı ulusal anıt ilan '
            'edildi; 1948’den itibaren Amerikan Bizans Enstitüsü, önce '
            'Thomas Whittemore, sonra Paul A. Underwood yönetiminde mozaik '
            've fresklerin üzerindeki sıva ile badanaları söktü. Çalışma '
            '1958’de tamamlandı ve Kariye müze olarak açıldı.\n\n'
            'Temizlik narteks döngülerini — Deesis’i, İsa ile Meryem’in '
            'atalarının yer aldığı iki kubbeyi — ve pareklezyonda Anastasis '
            'ile Son Yargı’yı yeniden ortaya çıkardı; hepsi Underwood’un '
            'Dumbarton Oaks için yazdığı ön raporlarda belgelendi.\n\n'
            'Müze yılları 2020’ye kadar sürdü. Camiye dönüşün hukuk yolu '
            '2005’te bir vakfın davasıyla başladı; Kasım 2019’da Danıştay '
            'yeniden cami kararı verdi, kararname Ağustos 2020’de geldi.'),
        media=[],
        artworks=[],
        sources=['underwood-1956', 'underwood-1958', 'ousterhout-2002',
                 'wd-q849489', 'whc-istanbul'],
    ),
    dict(
        id='kariye-mosque-1511', fromYear=1511, toYear=1945, anchorYear=1511,
        era='ottoman',
        title=loc('Kariye Mosque, 1511–1945', 'Kariye Camii, 1511–1945'),
        body=loc(
            'During the last siege of the city in 1453 the Hodegetria, the '
            'icon believed to protect Constantinople, was carried to Chora. '
            'The Ottomans entered on 29 May; the church served a Christian '
            'congregation for another fifty-eight years.\n\n'
            'In 1511, under Sultan Bayezid II, Grand Vizier Hadım (Atik) Ali '
            'Pasha converted it into a mosque. A mihrab went into the apse, '
            'a brick minaret rose in place of the bell tower, and the figures '
            'were covered over time; the main church plan was retained.\n\n'
            'Ottoman records describe maintenance rather than rebuilding. '
            'Earthquakes brought repairs, and in the nineteenth century the '
            'Evkaf administration repaired the naos dome. Decoration was '
            'never entirely concealed: nineteenth-century visitors saw '
            'mosaics in the domes and paid to open shutters over others.',
            '1453’teki son kuşatmada, İstanbul’u koruduğuna inanılan '
            'Hodegetria ikonu Kariye’ye getirildi. Osmanlılar şehre 29 '
            'Mayıs’ta girdi; kilise elli sekiz yıl daha Hristiyan cemaatine '
            'hizmet etti.\n\n'
            '1511’de, II. Bayezid döneminde Sadrazam Hadım (Atik) Ali Paşa '
            'yapıyı camiye çevirtti. Apsise mihrap kondu, çan kulesinin '
            'yerini tuğla bir minare aldı; figürler zamanla örtüldü, ana '
            'kilisenin planı korundu.\n\n'
            'Osmanlı kayıtları yeniden yapımı değil bakımı anlatır. '
            'Depremler onarımları getirdi; 19. yüzyılda Evkaf idaresi '
            'naos kubbesini onardı. Bezeme hiçbir zaman bütünüyle '
            'gizlenmedi: 19. yüzyıl ziyaretçileri kubbe mozaiklerini gördü, '
            'başkalarını örten kapakları bahşişle açtırdı.'),
        media=[],
        artworks=[],
        sources=['wd-q849489', 'ousterhout-2002', 'chora-guide', 'ousterhout-introduction'],
    ),
    dict(
        id='metochites', fromYear=1315, toYear=1321, anchorYear=1321,
        era='byzantine',
        title=loc('Theodore Metochites, 1315–1321',
                  'Theodoros Metokhites, 1315–1321'),
        body=loc(
            'Theodore Metochites, keeper of the imperial treasury and later '
            'megas logothetes, funded the rebuilding of the monastery '
            'between 1315 and 1321. He added the inner and outer narthexes '
            'and the side chapel — the parekklesion — and had the interior '
            'made ready for his own burial.\n\n'
            'The new surfaces carry the fullest mosaic programme of late '
            'Byzantium: the Deesis and the two narthex domes with the '
            'ancestors of Christ and the kings of Judah, the Life of the '
            'Virgin in twenty-two scenes, and, above the door into the naos, '
            'Metochites himself in a kabbadion and tall hat, offering a '
            'model of the church to Christ.\n\n'
            'The funerary chapel is painted, not mosaicked: the Anastasis '
            'over the apse — Christ pulling Adam and Eve by the wrist — the '
            'Last Judgment in the eastern bay and the Virgin in the western dome. His '
            'name and title, “the ktetor logothetes”, are written beside the '
            'founder portrait.\n\n'
            'Metochites lost power in 1328, was exiled by Andronikos III, '
            'returned two years later and ended his life as the monk '
            'Theoleptos in the monastery he had paid for.',
            'İmparatorluk hazinesinin sorumlusu, sonradan megas logothetes '
            'olan Theodoros Metokhites manastırın yeniden yapımını 1315–1321 '
            'arasında finanse etti. İç ve dış narteksi ve yan şapeli — '
            'pareklezyonu — ekletti; iç mekânı kendi gömütü için '
            'hazırlattı.\n\n'
            'Yeni yüzeyler geç Bizans’ın en eksiksiz mozaik programını '
            'taşır: Deesis, İsa’nın ataları ile Yahuda krallarının '
            'betimlendiği iki narteks kubbesi, yirmi iki sahnede Meryem’in '
            'Hayatı ve naosa açılan kapının üstünde, kabbadionu ve uzun '
            'başlığıyla kilisenin maketini İsa’ya sunan Metokhites.\n\n'
            'Mezar şapeli mozaikle değil resimle bezelidir: apsisin üstünde '
            'Anastasis — İsa’nın Âdem ile Havva’yı bileklerinden çekişi —, '
            'doğu bölümünde Son Yargı, batı kubbesinde Meryem. Adı ve unvanı, '
            '“ktetor logothetes”, kurucu portresinin yanında yazılıdır.\n\n'
            'Metokhites 1328’de gücünü yitirdi, III. Andronikos onu '
            'sürgüne gönderdi; iki yıl sonra döndü ve ömrünü parasını '
            'verdiği manastırda Theoleptos adıyla keşiş olarak tamamladı.'),
        media=['judgment-original'],
        artworks=['F02', 'F05', 'M11', 'M13', 'M35', 'M01', 'M02', 'M03', 'M12'],
        sources=['ousterhout-2002', 'smarthistory-chora', 'chora-guide',
                 'chora-guide-parekklesion', 'wd-q849489', 'ousterhout-introduction'],
    ),
    dict(
        id='komnenian', fromYear=1077, toYear=1315, anchorYear=1077,
        era='byzantine',
        title=loc('The Komnenian church, 1077–1315',
                  'Kommenosların kilisesi, 1077–1315'),
        body=loc(
            'The naos walls were established around 1077–1081, when '
            'Maria Doukaina, mother-in-law of Alexios I Komnenos, rebuilt the '
            'monastery church as a cross-in-square: a central dome on four '
            'columns.\n\n'
            'A partial collapse early in the twelfth century, probably after '
            'an earthquake, was repaired by Isaac Komnenos, a son of Alexios '
            'I. Sturdy piers replaced the columns and carried a larger dome.\n\n'
            'The surviving naos mosaics and the Deesis belong to the '
            'fourteenth-century decoration, not to this rebuilding. In the '
            'monastery’s last Byzantine century the scholar Maximus '
            'Planudes worked here, bringing Ptolemy’s Geography back to '
            'Byzantine readers.',
            'Naos duvarlarının yerleri yaklaşık 1077–1081 arasında, I. '
            'Aleksios Komnenos’un kayınvalidesi Maria Dukaina’nın manastır '
            'kilisesini kapalı Yunan haçı planında — dört sütun üzerine '
            'oturan merkezî bir kubbeyle — yeniden yaptırdığı dönemde '
            'belirlendi.\n\n'
            '12. yüzyıl başında, büyük olasılıkla bir deprem sonrasında '
            'kısmen çöken yapıyı I. Aleksios’un oğlu İsaakios Komnenos '
            'onarttı. Sütunların yerini daha büyük kubbeyi taşıyan '
            'sağlam payeler aldı.\n\n'
            'Günümüze ulaşan naos mozaikleri ile Deesis bu yapı evresine '
            'değil, 14. yüzyıl bezemesine aittir. '
            'Manastırın son Bizans yüzyılında bilgin Maksimos Planudes '
            'burada çalıştı ve Batlamyus’un Coğrafya’sını Bizans’a yeniden '
            'kazandırdı.'),
        media=[],
        artworks=[],
        sources=['ousterhout-2002', 'wd-q849489', 'chora-guide', 'ousterhout-introduction'],
    ),
    dict(
        id='first-monastery', fromYear=300, toYear=1077, anchorYear=330,
        era='byzantine',
        title=loc('The monastery in the country',
                  'Kırlıktaki manastır'),
        body=loc(
            'Byzantine tradition places Christian use here before the city grew outward. '
            'Constantine the Great’s walls ran to the east; the church of '
            'the Holy Saviour “in the Chora” — in the countryside — kept '
            'its name after the walls of Theodosius II drew the city line '
            'past its door in 413–414.\n\n'
            'Byzantine writers read a second meaning into the name: the '
            'narthex mosaics call Christ “the Land of the Living” and the '
            'Virgin “the container of the uncontainable” — the same Greek '
            'word, chora, in both inscriptions.\n\n'
            'The earliest excavated foundations date to the sixth century; '
            'a saint’s life attributes a rebuilding to Justinian. '
            'The church that Maria Doukaina rebuilt '
            'in the eleventh century stood on that foundation.',
            'Bizans geleneği buradaki Hristiyan kullanımını şehrin büyümesinden önceye koyar. I. '
            'Konstantinos’un surları doğuda kalıyordu; “Hora’daki” — '
            'kırlıktaki — Kutsal Kurtarıcı kilisesi, II. Theodosius’un '
            'surları 413–414’te şehir çizgisini kapısının önünden '
            'geçirdikten sonra da adını korudu.\n\n'
            'Bizanslı yazarlar bu adı ikinci bir anlamla da okudu: narteks '
            'mozaikleri İsa’yı “Yaşayanların Diyarı”, Meryem’i '
            '“Sığdırılamayanı Sığdıran” diye anar — iki yazıtta da aynı '
            'Yunanca sözcük geçer: hora.\n\n'
            'Kazılardaki en eski temeller 6. yüzyıla tarihlenir; bir aziz '
            'yaşamöyküsü yeniden yapımı Justinianus’a bağlar. '
            'Maria Dukaina’nın 11. yüzyılda yaptırdığı '
            'kilise bu temelin üzerine oturur.'),
        media=[],
        artworks=[],
        sources=['wd-q849489', 'ousterhout-2002', 'chora-museum', 'ousterhout-introduction'],
    ),
]

# --- Hagia Sophia: two draft layers prove the page is data only (newest first). ---
HAGIA_SOPHIA_STRATA = [
    dict(
        id='mosque-after-1453', fromYear=1453, toYear=1934, anchorYear=1453,
        era='ottoman',
        title=loc('Mosque after 1453', '1453’ten sonra cami'),
        body=loc(
            'Mehmed II entered the city on 29 May 1453 and turned Hagia '
            'Sophia into a mosque; the first Friday prayer followed that '
            'June. For nearly five centuries minarets, a mihrab, a minbar '
            'and imperial lodges were added around Justinian’s shell.\n\n'
            'In 1934 the Council of Ministers turned it into a museum. In '
            '1985 it entered the UNESCO World Heritage listing of the '
            'Historic Areas of Istanbul, and in July 2020 the Council of '
            'State annulled the museum decree; it opened for prayer again, '
            'with the galleries visited separately.',
            'Mehmed II 29 Mayıs 1453’te şehre girdi ve Ayasofya’yı camiye '
            'çevirdi; ilk cuma namazı o yılın haziran ayında kılındı. '
            'Justinianus’un kabuğunun çevresine yaklaşık beş yüzyıl boyunca '
            'minareler, mihrap, minber ve hünkâr mahfilleri eklendi.\n\n'
            '1934’te Bakanlar Kurulu yapıyı müzeye çevirdi. 1985’te '
            'İstanbul’un Tarihi Alanları UNESCO Dünya Mirası listesine '
            'girdi; Temmuz 2020’de Danıştay müze kararını iptal etti ve '
            'yapı, üst galeriler ayrıca gezilecek biçimde yeniden ibadete '
            'açıldı.'),
        media=[],
        artworks=[],
        sources=['britannica-hagia-sophia', 'whc-istanbul', 'wd-q12506'],
    ),
    dict(
        id='justinian-church', fromYear=532, toYear=537, anchorYear=537,
        era='byzantine',
        title=loc('Justinian’s church, 532–537',
                  'Justinianus’un kilisesi, 532–537'),
        body=loc(
            'After the Nika revolt burned the previous church in 532, '
            'Justinian gave the task to two Anatolian architects, Anthemius '
            'of Tralles and Isidore of Miletus. The building was finished in '
            'five years and ten months and dedicated on 27 December 537.\n\n'
            'The first dome was shallow and the region kept moving: it '
            'collapsed in 558, and Isidore the Younger rebuilt it higher and '
            'lighter, completing the new dome in 562. What stands today is '
            'largely that second dome.',
            '532’deki Nika ayaklanması önceki kiliseyi yaktıktan sonra '
            'Justinianus işi iki Anadolulu mimara, Trallesli Anthemios ile '
            'Miletli İsidoros’a verdi. Yapı beş yıl on ayda tamamlandı ve '
            '27 Aralık 537’de açıldı.\n\n'
            'İlk kubbe yayvandı ve bölge durmadan sarsılıyordu: kubbe '
            '558’de çöktü; Genç İsidoros onu daha yüksek ve daha hafif '
            'biçimde 562’de yeniden tamamladı. Bugün ayakta duran kubbe '
            'büyük ölçüde bu ikinci kubbedir.'),
        media=[],
        artworks=[],
        sources=['smarthistory-hagia-sophia', 'britannica-hagia-sophia',
                 'wd-q12506'],
    ),
]

PLACE_SOURCES = {
    'chora': ['wd-q849489', 'chora-guide', 'ousterhout-2002',
              'underwood-1956', 'underwood-1958', 'smarthistory-chora',
              'chora-guide-parekklesion', 'muze-kariye',
              'daily-sabah-kariye-2024', 'hyperallergic-kariye-2024',
              'sozcu-kariye-2024', 'cumhuriyet-kariye-2024', 'chora-museum',
              'ousterhout-introduction', 'aa-kariye-postponed-2020'],
    'hagia-sophia': ['wd-q12506', 'smarthistory-hagia-sophia',
                     'britannica-hagia-sophia', 'whc-istanbul'],
}


def main():
    places_path = CONTENT / 'places/istanbul.json'
    document = json.loads(places_path.read_text())
    records = {record['id']: record for record in document['records']}
    for id, strata in [('chora', CHORA_STRATA),
                       ('hagia-sophia', HAGIA_SOPHIA_STRATA)]:
        record = records[id]
        record['strata'] = strata
        record['sources'] = PLACE_SOURCES[id]
        if id == 'chora':
            record['visit'] = CHORA_VISIT
    places_path.write_text(json.dumps(document, ensure_ascii=False, indent=2) + '\n')

    dig_path = CONTENT / 'sources/dig.json'
    write(dig_path, dict(schemaVersion=1, kind='sources', records=SOURCES))

    index_path = CONTENT / 'index.json'
    index = json.loads(index_path.read_text())
    rel = 'assets/content/sources/dig.json'
    if rel not in index['files']['sources']:
        index['files']['sources'].append(rel)
    index_path.write_text(json.dumps(index, ensure_ascii=False, indent=2) + '\n')

    print(f'chora: {len(CHORA_STRATA)} layers, hagia-sophia: '
          f'{len(HAGIA_SOPHIA_STRATA)} layers, {len(SOURCES)} sources')


if __name__ == '__main__':
    main()
