"""Words and sources of the P08 study "How a dome stands".

`write(root, built)` writes the SpacePlayer manifest
(assets/space/how-a-dome-stands/study.json) for the parts in `built`, and the
study's registry sources (assets/content/sources/space.json, listed in
assets/content/index.json). Every caption names something checkable in the
drawing or in a cited source.
"""
import json

ACCESSED = '2026-10-12'


def src(id, title, url, author, licence=None):
    return {'id': id, 'title': title, 'url': url, 'author': author,
            'accessedAt': ACCESSED, 'licence': licence}


PD = {'en': 'Public domain', 'tr': 'Kamu malı'}
SOURCES = [
    src('choisy-1883',
        {'en': "L'art de bâtir chez les Byzantins (Paris, 1883), scan",
         'tr': "L'art de bâtir chez les Byzantins (Paris, 1883), tarama"},
        'https://digit.biblio.polito.it/secure/5914/1/L%20art%20de%20batir%20chez%20les%20byzantines_comp.pdf',
        {'en': 'Auguste Choisy', 'tr': 'Auguste Choisy'}, PD),
    src('choisy-1899-2',
        {'en': "Histoire de l'architecture, vol. 2 (Paris, 1899)",
         'tr': "Histoire de l'architecture, 2. cilt (Paris, 1899)"},
        'https://gallica.bnf.fr/ark:/12148/bpt6k6584016q',
        {'en': 'Auguste Choisy', 'tr': 'Auguste Choisy'}, PD),
    src('procopius-buildings-1',
        {'en': 'Procopius, Buildings I.1 (Loeb, 1940), §42–46',
         'tr': 'Prokopios, Yapılar I.1 (Loeb, 1940), §42–46'},
        'https://penelope.uchicago.edu/Thayer/E/Roman/Texts/Procopius/Buildings/1A*.html',
        {'en': 'Procopius, translated by H. B. Dewing',
         'tr': 'Prokopios, çeviren H. B. Dewing'}),
    src('britannica-pendentive',
        {'en': 'Pendentive — Encyclopaedia Britannica',
         'tr': 'Pandantif — Encyclopaedia Britannica'},
        'https://www.britannica.com/technology/pendentive',
        {'en': 'Encyclopaedia Britannica editors', 'tr': 'Encyclopaedia Britannica editörleri'}),
    src('britannica-sinan',
        {'en': 'Sinan — Encyclopaedia Britannica', 'tr': 'Sinan — Encyclopaedia Britannica'},
        'https://www.britannica.com/biography/Sinan',
        {'en': 'Encyclopaedia Britannica editors', 'tr': 'Encyclopaedia Britannica editörleri'}),
    src('wp-hagia-sophia-1379544167',
        {'en': 'Hagia Sophia — Wikipedia (revision 1379544167)',
         'tr': 'Hagia Sophia — Wikipedia (1379544167 sürümü)'},
        'https://en.wikipedia.org/w/index.php?title=Hagia_Sophia&oldid=1379544167',
        {'en': 'Wikipedia contributors', 'tr': 'Wikipedia katkıda bulunanları'},
        {'en': 'CC BY-SA 4.0', 'tr': 'CC BY-SA 4.0'}),
    src('wp-sehzade-1367352917',
        {'en': 'Şehzade Mosque — Wikipedia (revision 1367352917)',
         'tr': 'Şehzade Mosque — Wikipedia (1367352917 sürümü)'},
        'https://en.wikipedia.org/w/index.php?title=%C5%9Eehzade_Mosque&oldid=1367352917',
        {'en': 'Wikipedia contributors', 'tr': 'Wikipedia katkıda bulunanları'},
        {'en': 'CC BY-SA 4.0', 'tr': 'CC BY-SA 4.0'}),
]

SHARED = {'britannica-hagia-sophia'}


def step(id, parts, seconds, epochs, sources, label, caption):
    return {'id': id, 'parts': parts, 'seconds': seconds, 'epochs': epochs,
            'sources': sources, 'label': label, 'caption': caption}


def corners(name):
    return [f'{name}-{c}' for c in ('ne', 'nw', 'sw', 'se')]


STEPS = [
    step('bay', corners('pier'), 4.5, [], ['wp-hagia-sophia-1379544167'],
         {'en': 'Four piers on a square', 'tr': 'Kare üzerinde dört ayak'},
         {'en': 'A square bay 31 m wide, about the span of Hagia Sophia’s dome '
                '(30.86–31.24 m), with a pier at each corner.',
          'tr': '31 m genişliğinde kare bir açıklık, aşağı yukarı Ayasofya kubbesinin '
                'çapı kadar (30,86–31,24 m); her köşesinde bir ayak.'}),
    step('arches', ['arch-n', 'arch-w', 'arch-s', 'arch-e'], 4.5, [], ['choisy-1883'],
         {'en': 'Four arches', 'tr': 'Dört kemer'},
         {'en': 'Four semicircular arches span the sides. Their crowns are the only '
                'points of the square that already lie on the dome’s circle.',
          'tr': 'Dört yarım daire kemer kenarları aşar. Karenin kubbe dairesine '
                'değen tek noktaları bu kemerlerin tepeleridir.'}),
    step('pendentives', corners('pendentive'), 4.5, [],
         ['britannica-pendentive', 'choisy-1883'],
         {'en': 'Four pendentives', 'tr': 'Dört pandantif'},
         {'en': 'Pendentives fill the corners: four triangles cut from one sphere turn '
                'the square into a circle. Hagia Sophia (537) is among their earliest '
                'and largest uses.',
          'tr': 'Köşeleri pandantifler doldurur: aynı küreden kesilmiş dört üçgen kareyi '
                'daireye çevirir. Ayasofya (537) bunların en erken ve en büyük '
                'örneklerindendir.'}),
    step('ring', ['ring'], 4.5, [], ['choisy-1883'],
         {'en': 'The ring', 'tr': 'Bilezik'},
         {'en': 'A cornice ring closes the circle; the dome’s weight comes down through '
                'it onto the four arches and pendentives.',
          'tr': 'Bir silme bileziği daireyi kapatır; kubbenin ağırlığı buradan dört '
                'kemere ve pandantiflere iner.'}),
    step('dome', ['windows', 'dome'], 4.5, [],
         ['wp-hagia-sophia-1379544167', 'procopius-buildings-1'],
         {'en': 'A dome on 40 windows', 'tr': '40 pencere üzerinde kubbe'},
         {'en': 'The dome stands on a ring of 40 windows, as Hagia Sophia’s does. '
                'Procopius wrote that it seemed not to rest on masonry but to hang '
                'from heaven.',
          'tr': 'Kubbe, Ayasofya’daki gibi 40 pencerelik bir halkanın üstünde durur. '
                'Prokopios, kubbenin taşa dayanmıyor da gökten asılıymış gibi '
                'göründüğünü yazmıştı.'}),
    step('semidomes', ['semidome-e', 'exedra-e', 'semidome-w', 'exedra-w'], 4, [],
         ['britannica-hagia-sophia', 'wp-hagia-sophia-1379544167'],
         {'en': 'Two semi-domes', 'tr': 'İki yarım kubbe'},
         {'en': 'The arches still push outward, so semi-domes of the same radius lean '
                'on them. Hagia Sophia (537) has two, east and west.',
          'tr': 'Kemerler hâlâ dışa doğru iter; bu yüzden aynı yarıçaplı yarım kubbeler '
                'onlara yaslanır. Ayasofya’da (537) iki tane vardır: doğuda ve batıda.'}),
    step('tympana', ['tympanum-n', 'tympanum-s'], 3.5, [537],
         ['wp-hagia-sophia-1379544167'],
         {'en': 'Two walled arches', 'tr': 'Örülmüş iki kemer'},
         {'en': '537: to the north and south, Hagia Sophia fills its arches with walls, '
                'the tympana.',
          'tr': '537: Ayasofya kuzey ve güney kemerlerini duvarla, yani timpanlarla '
                'doldurur.'}),
    step('four-semidomes', ['semidome-n', 'exedra-n', 'semidome-s', 'exedra-s'], 5, [1548],
         ['wp-sehzade-1367352917', 'britannica-sinan'],
         {'en': 'Four semi-domes', 'tr': 'Dört yarım kubbe'},
         {'en': '1548: Sinan’s Şehzade Mosque puts a semi-dome on all four sides of a '
                '19 m dome, symmetrical in every direction.',
          'tr': '1548: Mimar Sinan, Şehzade Camii’nde 19 m’lik kubbenin dört yanına da '
                'yarım kubbe koyar; plan her yönde simetriktir.'}),
]

STUDY = {
    'schemaVersion': 1,
    'kind': 'space',
    'id': 'how-a-dome-stands',
    'title': {'en': 'How a dome stands', 'tr': 'Kubbe nasıl ayakta durur'},
    'description': {
        'en': 'A drawing of a square bay 31 m wide assembling, seen from below: four '
              'piers, four arches, four pendentives, a ring and a dome on 40 windows. '
              'The time scrubber braces the same bay two ways: Hagia Sophia’s two '
              'semi-domes (537) and the Şehzade Mosque’s four (1548). A diagram, not a '
              'survey of either building.',
        'tr': '31 m genişliğinde kare bir açıklığın aşağıdan görülen çizimi kendini '
              'kurar: dört ayak, dört kemer, dört pandantif, bir bilezik ve 40 pencere '
              'üstünde bir kubbe. Zaman çubuğu aynı açıklığı iki yolla destekler: '
              'Ayasofya’nın iki yarım kubbesi (537) ve Şehzade Camii’nin dördü (1548). '
              'Bu bir şemadır, iki yapının da rölövesi değildir.'},
    'model': 'assets/space/how-a-dome-stands/model.glb',
    'honesty': 'RECONSTRUCTION',
    'epochs': [
        {'year': 537, 'label': {'en': 'Hagia Sophia, 537', 'tr': 'Ayasofya, 537'}},
        {'year': 1548, 'label': {'en': 'Şehzade Mosque, 1548', 'tr': 'Şehzade Camii, 1548'}},
    ],
    'steps': STEPS,
    'reveal': {
        'through': 'dome', 'seconds': 8, 'turnDegrees': 30,
        'caption': {
            'en': 'Four piers, four arches, four pendentives, a ring and a dome on 40 '
                  'windows: how a 31 m dome stands on a square.',
            'tr': 'Dört ayak, dört kemer, dört pandantif, bir bilezik ve 40 pencere '
                  'üstünde bir kubbe: 31 m’lik bir kubbe kare bir planın üstünde böyle '
                  'durur.'}},
    'choisy': {'sectionHeight': 3.0},
    'sources': ['choisy-1883', 'choisy-1899-2'],
}


def dump(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def write(root, built):
    names = {p['name'] for p in built}
    used = [p for s in STEPS for p in s['parts']]
    missing = set(used) - names
    if missing or len(names) != len(set(used)):
        raise SystemExit(f'study parts and model parts differ: {sorted(missing or names - set(used))}')
    # Sources the registry already holds are cited, not declared twice.
    dig = json.loads((root / 'assets/content/sources/dig.json').read_text(encoding='utf-8'))
    shared = [r for r in dig['records'] if r['id'] in SHARED]
    study = dict(STUDY, triangles=sum(len(p['faces']) for p in built),
                 citations=SOURCES + shared)
    dump(root / 'assets/space/how-a-dome-stands/study.json', study)
    dump(root / 'assets/content/sources/space.json',
         {'schemaVersion': 1, 'kind': 'sources', 'records': SOURCES})
    index_path = root / 'assets/content/index.json'
    index = json.loads(index_path.read_text(encoding='utf-8'))
    rel = 'assets/content/sources/space.json'
    if rel not in index['files']['sources']:
        index['files']['sources'].append(rel)
        dump(index_path, index)
