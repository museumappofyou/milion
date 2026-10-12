"""Usage: python3 tool/content/build_details.py — writes the Detail-of-the-day pool.

Offline and deterministic. Writes assets/content/details/chora.json and
assets/content/sources/details.json. Windows and anchors are normalised to the
Milestone's master photograph (I: assets/anastasis/conch_reference.jpg,
2048×1091; II: assets/last_judgment/vault_reference.jpg, 1600×1067; III–V: the
P07 masters assets/plates/{metochites,genealogy,enrollment}/original.jpg,
1600×1067 / 1600×1067 / 1600×1068); the photo is shown untouched, so every
detail is ORIGINAL. I–II sentences were checked against the cited restoration
reports and guides on 2026-10-01, III–V against Underwood's 1966 description
(printed pages) and Ousterhout on 2026-10-12, and placed on the photographs.
Order alternates artworks so consecutive days change; P07's details follow
P04's seventeen unchanged.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATE = '2026-10-01'
P07 = '2026-10-12'


def src(id, en, url, author, tr=None, licence=None, date=DATE):
    return dict(id=id, title=dict(en=en, tr=tr or en), url=url,
                author=dict(en=author, tr=author), accessedAt=date,
                licence=None if licence is None else dict(en=licence, tr=licence))


SOURCES = [
    src('underwood-1956', 'First Preliminary Report on the Restoration of the Frescoes in the Kariye Camii at Istanbul by the Byzantine Institute, 1952–1954 (Dumbarton Oaks Papers 9/10)',
        'https://archive.org/details/DOP09-10_09_Underwood', 'Paul A. Underwood'),
    src('underwood-1958', 'Third Preliminary Report on the Restoration of the Frescoes in the Kariye Camii at Istanbul by the Byzantine Institute, 1956 (Dumbarton Oaks Papers 12)',
        'https://archive.org/details/DOP12_09_Underwood', 'Paul A. Underwood'),
    src('ousterhout-2002', 'The Art of the Kariye Camii',
        'https://archive.org/details/ousterhout-r.-the-art-of-kariye-camii-2002-compressed', 'Robert G. Ousterhout'),
    src('smarthistory-chora', 'Picturing salvation — Chora’s brilliant mosaics and frescoes',
        'https://smarthistory.org/picturing-salvation/', 'Evan Freeman'),
    src('chora-guide-parekklesion', 'Guide to the Kariye Mosaics — G. Parekklesion frescoes',
        'https://kulturenvanteri.com/tr/kariye-mozaikleri-rehberi/#g-parekklesion-freskleri-pareklezyon',
        'Caner Cangül, Engin Mutlu, Kader Ali Çayır', tr='Kariye Mozaikleri Rehberi — G. Parekklesion freskleri'),
    src('revelation-6-14', 'Revelation 6:14 (King James Version)',
        'https://www.biblegateway.com/passage/?search=Revelation%206%3A14&version=KJV', 'Bible Gateway',
        tr='Vahiy 6:14 (King James çevirisi)'),
    src('daniel-7-10', 'Daniel 7:10 (King James Version)',
        'https://www.biblegateway.com/passage/?search=Daniel%207%3A10&version=KJV', 'Bible Gateway',
        tr='Daniel 7:10 (King James çevirisi)'),
    src('underwood-1966', 'The Kariye Djami, Vol. 1: Historical Introduction and Description of the Mosaics and Frescoes',
        'https://archive.org/details/kariyedjami0001paul', 'Paul A. Underwood',
        tr='The Kariye Djami, 1. cilt: Tarihsel giriş ve mozaik ile fresklerin tanımı', date=P07),
    src('psalm-116-9', 'Psalm 116:9 (King James Version)',
        'https://www.biblegateway.com/passage/?search=Psalm%20116%3A9&version=KJV', 'Bible Gateway',
        tr='Mezmurlar 116:9 (King James çevirisi)', date=P07),
    src('luke-2-1-5', 'Luke 2:1–5 (King James Version)',
        'https://www.biblegateway.com/passage/?search=Luke%202%3A1-5&version=KJV', 'Bible Gateway',
        tr='Luka 2:1–5 (King James çevirisi)', date=P07),
]

# id, milestone, artwork, title EN/TR, sentence EN/TR, window (l, t, r, b), anchor (x, y), sources
I, II = ('milestone-i', 'F02'), ('milestone-ii', 'F05')
DETAILS = [
    ('adam-wrist', I, ('Adam’s wrist', 'Âdem’in bileği'),
     ('Christ grips Adam by the wrist, not by the hand.',
      'İsa, Âdem’i elinden değil, bileğinden kavrıyor.'),
     (.28, .29, .54, .83), (.405, .552), ['ousterhout-2002', 'smarthistory-chora', 'chora-guide-parekklesion']),
    ('scroll-of-heaven', II, ('The rolled-up heavens', 'Dürülen gökler'),
     ('An angel rolls up the heavens like a scroll, with the sun, moon and stars on it.',
      'Bir melek gökleri tomar gibi dürüyor; tomarın üstünde güneş, ay ve yıldızlar var.'),
     (.34, .2, .66, .73), (.5, .44), ['underwood-1958', 'revelation-6-14']),
    ('eve-wrist', I, ('Eve’s covered hand', 'Havva’nın örtülü eli'),
     ('Christ pulls Eve up by the wrist; her other hand stays hidden under her red mantle.',
      'İsa, Havva’yı da bileğinden çekiyor; Havva’nın öbür eli kırmızı örtüsünün altında.'),
     (.5, .3, .76, .84), (.553, .493), ['underwood-1956', 'chora-guide-parekklesion']),
    ('river-of-fire', II, ('The river of fire', 'Ateş ırmağı'),
     ('A fiery stream pours from before Christ’s feet toward the lake of fire.',
      'İsa’nın ayaklarının önünden doğan ateş ırmağı, ateş gölüne doğru akıyor.'),
     (.48, .5, .82, 1.0), (.6, .8), ['underwood-1958', 'daniel-7-10']),
    ('anastasis-title', I, ('Η ΑΝΑϹΤΑϹΙϹ', 'Η ΑΝΑϹΤΑϹΙϹ'),
     ('The white letters above Christ read Η ΑΝΑϹΤΑϹΙϹ, “the Resurrection”.',
      'İsa’nın üstündeki beyaz harfler Η ΑΝΑϹΤΑϹΙϹ, yani “Diriliş” yazıyor.'),
     (.36, .08, .62, .62), (.475, .197), ['underwood-1956']),
    ('deesis', II, ('The Deesis', 'Deesis'),
     ('The Virgin and John the Baptist stand either side of Christ the Judge, pleading.',
      'Meryem ile Vaftizci Yahya, Yargıç İsa’nın iki yanında yakarıyor.'),
     (.34, .42, .68, .92), (.506, .64), ['underwood-1958', 'chora-guide-parekklesion']),
    ('gates-of-hell', I, ('The broken gates', 'Kırık kapılar'),
     ('Christ stands at the edge of the black pit, the broken gates of Hell beneath his feet.',
      'İsa kara çukurun kıyısında duruyor; cehennemin kırık kapıları ayaklarının altında.'),
     (.36, .46, .64, 1.0), (.445, .81), ['underwood-1956']),
    ('apostles', II, ('The apostles’ bench', 'Havarilerin sırası'),
     ('The twelve apostles sit on benches either side, books open, with angels in a row behind.',
      'On iki havari iki yandaki sıralarda kitapları açık oturuyor; arkalarında bir sıra melek var.'),
     (.16, .42, .5, .88), (.27, .6), ['underwood-1958']),
    ('hades-bound', I, ('Hades bound', 'Bağlı Hades'),
     ('Bound hand and foot, Hades lies sprawled across one leaf of the broken gates.',
      'Elleri ve ayakları bağlı Hades (Şeytan), kırık kapı kanatlarından birinin üstüne yüzüstü serilmiş.'),
     (.4, .5, .7, 1.0), (.52, .86), ['underwood-1956', 'smarthistory-chora', 'chora-guide-parekklesion']),
    ('choirs-of-the-elect', II, ('The choir of bishops', 'Piskoposlar korosu'),
     ('Choirs of the elect kneel on clouds, each named in Greek; the bishops’ vestments are patterned with black crosses.',
      'Seçilmişlerin koroları bulutlarda diz çökmüş, her birinin adı Yunanca yazılı; piskoposların giysileri siyah haçlarla bezeli.'),
     (.56, .12, .86, .62), (.74, .37), ['underwood-1958']),
    ('locks-and-keys', I, ('Locks and keys', 'Kilitler ve anahtarlar'),
     ('Locks, keys, bolts, hinges and nails from the shattered gates litter the black pit.',
      'Parçalanan kapıların kilitleri, anahtarları, sürgüleri, menteşeleri ve çivileri kara çukura saçılmış.'),
     (.26, .5, .52, 1.0), (.37, .83), ['underwood-1956']),
    ('lost-band', II, ('The lost strip', 'Kaybolan şerit'),
     ('A strip of lost paint, filled with toned plaster, cuts across the apostles on the right.',
      'Sağdaki havarilerin üzerinden, boyası tümüyle yitmiş ve renklendirilmiş sıvayla doldurulmuş bir şerit geçiyor.'),
     (.52, .42, .86, .92), (.7, .65), ['underwood-1958']),
    ('kings', I, ('David and Solomon', 'Davud ve Süleyman'),
     ('At left, John the Baptist points to Christ; the crowned kings David and Solomon stand behind him.',
      'Solda Vaftizci Yahya İsa’yı gösteriyor; taçlı krallar Davud ile Süleyman onun arkasında duruyor.'),
     (.17, .18, .43, .72), (.255, .31), ['underwood-1956']),
    ('prepared-throne', II, ('The prepared throne', 'Hazırlanmış taht'),
     ('Below Christ, Adam and Eve bow with covered hands before the prepared throne.',
      'İsa’nın altında Âdem ile Havva, örtülü elleriyle hazırlanmış tahtın önünde eğiliyor.'),
     (.36, .5, .7, 1.0), (.515, .83), ['underwood-1958', 'chora-guide-parekklesion']),
    ('abel', I, ('Abel’s crook', 'Habil’in değneği'),
     ('Young Abel, holding a shepherd’s crook, stands beside Eve in her sarcophagus.',
      'Genç Habil, elinde çoban değneğiyle, Havva’nın lahdinde onun yanında duruyor.'),
     (.56, .2, .82, .74), (.632, .3), ['underwood-1956']),
    ('weighing-of-souls', II, ('The balance', 'Terazi'),
     ('A balance hangs from the throne’s foot; a black devil drags one pan down with a hooked stick.',
      'Tahtın ayağından bir terazi sarkıyor; kara bir şeytan kancalı bir sopayla kefelerden birini aşağı çekiyor.'),
     (.34, .5, .68, 1.0), (.5, .925), ['underwood-1958']),
    ('mandorla-stars', I, ('Eight-pointed stars', 'Sekiz köşeli yıldızlar'),
     ('Christ’s mandorla is scattered with eight-pointed stars, first laid in gold leaf.',
      'İsa’nın mandorlasına sekiz köşeli yıldızlar serpilmiş; ilk hâlleri varak altındandı.'),
     (.37, .22, .63, .76), (.488, .3), ['underwood-1956']),
]

# P07, Milestones III–V. Underwood = The Kariye Djami vol. 1 (1966), printed pages.
III, IV, V = ('milestone-iii', 'M11'), ('milestone-iv', 'M13'), ('milestone-v', 'M35')
U = 'underwood-1966'
METOCHITES = [
    ('metochites-hat', III, ('The skiadion', 'Skiadion'),
     ('Metochites wears a skiadion, a “sunshade” hat of white fabric, probably silk, with gold stripes edged in red.',
      'Metokhites’in başında bir skiadion, yani “güneşlik” var: büyük olasılıkla ipek, beyaz bir kumaş; kırmızı kenarlı altın şeritlerle.'),
     (.12, .44, .33, .66), (.235, .515), [U]),  # Underwood p. 42
    ('metochites-title', III, ('The founder’s title', 'Kurucunun unvanı'),
     ('The Greek beside him reads “The founder, Logothete of the Genikon, Theodore Metochites”: head of the general treasury.',
      'Yanındaki Grekçe yazı: “Kurucu, Genikon logothetesi Theodoros Metokhites”; yani genel hazinenin başı.'),
     (.08, .47, .21, .82), (.135, .6), [U]),  # p. 42 and n. 1
    ('church-model', III, ('The church in his hands', 'Elindeki kilise'),
     ('His model of Chora leaves out the parekklesion and shows only three bays of the outer narthex.',
      'Elindeki Kariye maketi parekklesionu dışarıda bırakıyor; dış narteksin yalnızca üç bölmesini gösteriyor.'),
     (.2, .55, .36, .82), (.29, .66), [U]),  # p. 43
    ('land-of-the-living', III, ('The land of the living', 'Yaşayanların diyarı'),
     ('Beside Christ: “Ἡ χώρα τῶν ζώντων”, the dwelling-place of the living, a play on the name Chora.',
      'İsa’nın iki yanında “Ἡ χώρα τῶν ζώντων” yazıyor: yaşayanların diyarı; Kariye’nin adı Khora’ya bir gönderme.'),
     (.3, .3, .55, .62), (.385, .4), [U, 'ousterhout-2002', 'psalm-116-9']),  # p. 42; Ousterhout pp. 104–105
    ('jewelled-gospel', III, ('The jewelled Gospel', 'Mücevherli İncil'),
     ('Christ blesses with his right hand; the closed Gospel on his left knee is set with white stones and red and green glass.',
      'İsa sağ eliyle takdis ediyor; sol dizindeki kapalı İncil beyaz taşlarla, kırmızı ve yeşil camlarla bezeli.'),
     (.38, .3, .62, .75), (.53, .56), [U]),  # pp. 42–43
    ('scalloped-gold', III, ('The empty side', 'Boş bırakılan yan'),
     ('The side facing Metochites is left empty, its gold tesserae laid in a scalloped pattern.',
      'Metokhites’in karşısındaki yan boş bırakılmış; buradaki altın mozaik taşları pul pul dizilmiş.'),
     (.64, .4, .95, .92), (.82, .62), ['ousterhout-2002']),  # Ousterhout pp. 22–23
    ('kabbadion', III, ('The kabbadion', 'Kabbadion'),
     ('His kabbadion caftan is dark bluish green, patterned all over with two leaf forms.',
      'Kabbadion denen kaftanı koyu mavimsi yeşil; baştan aşağı iki ayrı yaprak motifiyle desenli.'),
     (.04, .6, .3, .98), (.13, .84), [U]),  # p. 42
]
GENEALOGY = [
    ('genealogy-medallion', IV, ('Christ in the crown', 'Tepedeki İsa'),
     ('The crown medallion, 1.24 m across, is labelled only IC XC; “Pantokrator” names the type, not an inscription.',
      'Tepedeki 1,24 m çapındaki madalyonda yalnızca IC XC yazıyor; “Pantokrator” bir yazıt değil, tasvir tipinin adı.'),
     (.4, .27, .57, .5), (.483, .385), [U]),  # pp. 49, 57
    ('adam-and-sons', IV, ('Adam below Christ', 'İsa’nın altında Âdem'),
     ('White-bearded Adam stands on Christ’s axis, between his sons Abel, at left, and Seth, at right.',
      'Ak sakallı Âdem, İsa’nın ekseninde, oğulları Habil (solda) ile Şit’in (sağda) arasında duruyor.'),
     (.44, .5, .61, .78), (.522, .6), [U, 'ousterhout-2002']),  # p. 52
    ('upper-ancestors', IV, ('Adam to Jacob', 'Âdem’den Yakup’a'),
     ('The upper ring holds 24 ancestors from Adam to Jacob; Abel and Japheth are added to Luke’s list.',
      'Üst sırada Âdem’den Yakup’a 24 ata var; Luka’nın listesine Habil ile Yafet eklenmiş.'),
     (.28, .08, .5, .42), (.36, .2), [U]),  # p. 37
    ('lower-ancestors', IV, ('Jacob’s sons', 'Yakup’un oğulları'),
     ('The lower ring has 15 figures: Jacob’s twelve sons with Perez, Zerah and Hezron.',
      'Alt sırada 15 figür var: Yakup’un on iki oğlu ile Peres, Zerah ve Hesron.'),
     (.3, .72, .7, .9), (.5, .82), [U]),  # pp. 49–50, 53
    ('lost-plaster', IV, ('Plaster for lost mosaic', 'Kayıp mozaiğin sıvası'),
     ('The flat grey-yellow patches are plaster laid by the restorers from 1952 where the mosaic was lost.',
      'Düz gri-sarı yüzeyler, mozaiğin kaybolduğu yerlere restoratörlerin 1952’den itibaren sürdüğü sıva.'),
     (.56, .38, .78, .62), (.65, .5), [U]),  # p. 57
    ('twenty-four-flutes', IV, ('24 flutes, nine windows', '24 dilim, dokuz pencere'),
     ('The dome has 24 flutes and nine windows; it is 3.74 m across, its crown 10.54 m above the floor.',
      'Kubbe 24 dilimli ve dokuz pencereli; çapı 3,74 m, tepesi yerden 10,54 m yükseklikte.'),
     (.15, .25, .45, .7), (.2, .47), [U]),  # pp. 51, 57; anchor on a window
]
ENROLLMENT = [
    ('governor-hat', V, ('Governor Cyrenius', 'Vali Kirinius'),
     ('Cyrenius, governor of Syria, wears a hat like Metochites’ skiadion that curves forward to a sharp point.',
      'Suriye valisi Kirinius’in başlığı Metokhites’in skiadionuna benziyor, ama öne doğru sivri bir uçla kıvrılıyor.'),
     (.27, .5, .44, .92), (.355, .58), [U, 'luke-2-1-5']),  # pp. 88–89
    ('not-a-scroll', V, ('Not a scroll', 'Tomar değil'),
     ('The white cylinder in his hand is not a scroll; Underwood reads it as a badge of authority.',
      'Elindeki beyaz silindir bir tomar değil; Underwood onu bir yetki nişanı olarak yorumluyor.'),
     (.29, .64, .41, .82), (.335, .735), [U]),  # p. 89
    ('enrollment-text', V, ('Luke 2:4–5', 'Luka 2:4–5'),
     ('The three lines above quote Luke 2:4–5: Joseph goes to be enrolled with Mary, “being great with child”.',
      'Üstteki üç satır Luka 2:4–5’ten: Yusuf, gebe olan nişanlısı Meryem’le birlikte yazılmaya gidiyor.'),
     (.31, .37, .53, .48), (.42, .42), [U, 'luke-2-1-5']),  # p. 88
    ('armed-guard', V, ('The guard', 'Muhafız'),
     ('Behind the governor a guard in gilded armour holds a spear and a round shield with blue ornament.',
      'Valinin arkasındaki muhafız yaldızlı zırh giymiş; elinde bir mızrak ve mavi süslü yuvarlak bir kalkan var.'),
     (.15, .55, .31, .92), (.27, .67), [U]),  # p. 89
    ('the-register', V, ('The register', 'Kayıt'),
     ('A scribe writes the names on an open scroll while an older soldier holds a sheathed sword upright.',
      'Bir kâtip adları açık bir tomara yazıyor; yaşlıca bir asker kınındaki kılıcını dik tutuyor.'),
     (.42, .55, .6, .92), (.52, .66), [U]),  # p. 89
    ('mary-enrolled', V, ('Mary, alone', 'Tek başına Meryem'),
     ('Mary stands alone and unusually tall, all in blue but for red shoes; ΜΗΡ ΘΥ names her Mother of God.',
      'Meryem tek başına ve alışılmadık derecede uzun duruyor, kırmızı ayakkabıları dışında baştan aşağı mavi; ΜΗΡ ΘΥ onu Tanrı’nın Annesi diye adlandırıyor.'),
     (.57, .5, .74, .97), (.645, .62), [U]),  # p. 89
    ('joseph-and-sons', V, ('Joseph and his sons', 'Yusuf ve oğulları'),
     ('Haloed Joseph leans towards Mary with open hands; his four sons stand behind him.',
      'Haleli Yusuf açık elleriyle Meryem’e doğru eğiliyor; dört oğlu arkasında duruyor.'),
     (.71, .54, .92, .96), (.745, .6), [U]),  # p. 89
    ('lost-vault', V, ('The lost vault', 'Kaybolan tonoz'),
     ('The bare plaster above marks lost mosaic: Underwood found the vault here largely destroyed.',
      'Üstteki çıplak sıva kaybolan mozaiği gösteriyor: Underwood bu tonozu büyük ölçüde yok olmuş bulmuştu.'),
     (.15, 0.0, .58, .38), (.35, .18), [U]),  # pp. 108–111
]


def interleave(*groups, last=None):
    """Deterministic: always take from the fullest group whose artwork is not
    the one just shown, so consecutive days change artwork."""
    queues, out = [list(g) for g in groups], []
    while any(queues):
        pick = max((q for q in queues if q and q[0][1] != last), key=len)
        out.append(pick.pop(0))
        last = out[-1][1]
    return out


DETAILS += interleave(ENROLLMENT, METOCHITES, GENEALOGY, last=DETAILS[-1][1])


def main():
    records = []
    for id, (milestone, artwork), (title_en, title_tr), (en, tr), window, anchor, sources in DETAILS:
        l, t, r, b = window
        records.append(dict(
            id='detail-' + id, milestone=milestone, artwork=artwork,
            title=dict(en=title_en, tr=title_tr), sentence=dict(en=en, tr=tr),
            window=dict(left=l, top=t, right=r, bottom=b), anchorX=anchor[0], anchorY=anchor[1],
            honesty='ORIGINAL', sources=sources))
    for path, kind, data in [('details/chora.json', 'details', records), ('sources/details.json', 'sources', SOURCES)]:
        (ROOT / 'assets/content' / path).write_text(json.dumps(
            dict(schemaVersion=1, kind=kind, records=data), ensure_ascii=False, indent=2) + '\n')
    print(f'{len(records)} details, {len(SOURCES)} sources')


if __name__ == '__main__':
    main()
