"""Usage: python3 tool/content/build_details.py — writes the Detail-of-the-day pool.

Offline and deterministic. Writes assets/content/details/chora.json and
assets/content/sources/details.json. Windows and anchors are normalised to the
Milestone's explorer master photograph (I: assets/anastasis/conch_reference.jpg,
2048×1091; II: assets/last_judgment/vault_reference.jpg, 1600×1067); the photo
is shown untouched, so every detail is ORIGINAL. Each sentence was checked
against the cited restoration reports and guides on 2026-10-01; order
alternates I and II so consecutive days change artwork.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATE = '2026-10-01'


def src(id, en, url, author, tr=None, licence=None):
    return dict(id=id, title=dict(en=en, tr=tr or en), url=url,
                author=dict(en=author, tr=author), accessedAt=DATE,
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
