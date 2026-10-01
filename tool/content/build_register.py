"""Usage: python3 tool/content/build_register.py — writes the planned §3 register.

Offline and deterministic. Writes assets/content/milestones/register.json (0 and
III–XLVII, all `planned`) and assets/content/sources/register.json (pinned
Wikidata concept items for the pieces without a single place). I and II stay in
milestones/chora.json because their phases own their status. Planned honesty
sets are the labels each technique will need under §3: camera, light, sound
playback and flow over the same pixels are DEPTH; wipes, assembly, sections,
time models, turntables, pop-ups, stroke reveals, walk-throughs and acoustic
models are RECONSTRUCTION; animal motion and legends add IMAGINED. Every record
starts from ORIGINAL. Phases revise these when they author the manifest.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATE = '2026-10-01'

# numeral, EN title, TR title, places, artworks, techniques, flagship, pack, imagined
REGISTER = [
    ('0', 'The Milion', 'Milyon Taşı', ['milion'], [], 'CA TM', True, 'milion', False),
    ('III', 'Metochites offers Chora', 'Metokhites Kariye’yi sunuyor', ['chora'], ['M11'], 'GL SB', False, 'chora', False),
    ('IV', 'The Genealogy dome', 'Soy kütüğü kubbesi', ['chora'], ['M13'], 'LU GL', False, 'chora', False),
    ('V', 'The Enrollment for Taxation', 'Vergi yazımı', ['chora'], ['M35'], 'SB', False, 'chora', False),
    ('VI', 'Chora through time', 'Zaman içinde Kariye', ['chora'], [], 'CA', False, 'chora', False),
    ('VII', 'The Deesis', 'Deesis', ['hagia-sophia'], [], 'GL WR SB', True, 'hagia-sophia', False),
    ('VIII', 'Zoe’s changing emperor', 'Zoe’nin değişen imparatoru', ['hagia-sophia'], [], 'SB WR', False, 'hagia-sophia', False),
    ('IX', 'The dome that fell', 'Çöken kubbe', ['hagia-sophia'], [], 'CA CS', True, 'hagia-sophia', False),
    ('X', 'Halvdan was here', 'Halvdan buradaydı', ['hagia-sophia'], [], 'RL', False, 'hagia-sophia', False),
    ('XI', 'Sing in Hagia Sophia', 'Ayasofya’da şarkı söyle', ['hagia-sophia'], [], 'VO', False, 'hagia-sophia', False),
    ('XII', 'The Hippodrome through time', 'Zaman içinde Hipodrom', ['hippodrome'], [], 'TM', False, 'hippodrome', False),
    ('XIII', 'The Obelisk base', 'Dikilitaş’ın kaidesi', ['obelisk-of-theodosius'], [], 'RL', False, 'hippodrome', False),
    ('XIV', 'The Serpent Column', 'Yılanlı Sütun', ['serpent-column', 'archaeology-museums'], [], 'TT WR', False, 'hippodrome', False),
    ('XV', 'Great Palace animals', 'Büyük Saray’ın hayvanları', ['great-palace-mosaic-museum'], [], 'MM DP', False, 'hippodrome', True),
    ('XVI', 'The Basilica Cistern', 'Yerebatan Sarnıcı', ['basilica-cistern'], [], 'WK', True, 'underground', False),
    ('XVII', 'The harbour under the metro', 'Metronun altındaki liman', ['yenikapi'], [], 'PU SB', False, 'underground', False),
    ('XVIII', 'The Land Walls', 'Kara surları', ['land-walls'], [], 'PU SB', True, 'walls', False),
    ('XIX', '1453 in 53 days', '53 günde 1453', ['land-walls', 'golden-horn'], [], 'TM SB', False, 'walls', False),
    ('XX', 'Küçük Ayasofya', 'Küçük Ayasofya', ['little-hagia-sophia'], [], 'CA SR', False, 'byzantine-city', False),
    ('XXI', 'The Pammakaristos chapel', 'Pammakaristos şapeli', ['fethiye'], [], 'GL', False, 'byzantine-city', False),
    ('XXII', 'Valens Aqueduct', 'Bozdoğan Kemeri', ['valens-aqueduct'], [], 'CA TM', False, 'byzantine-city', False),
    ('XXIII', 'The Süleymaniye külliye', 'Süleymaniye Külliyesi', ['suleymaniye'], [], 'CA CS', True, 'suleymaniye', False),
    ('XXIV', 'Light at this hour', 'Bu saatteki ışık', ['suleymaniye'], [], 'SK CS', False, 'suleymaniye', False),
    ('XXV', 'The soot room', 'İs odası', ['suleymaniye'], [], 'PU SB', False, 'suleymaniye', False),
    ('XXVI', 'Rüstem Paşa’s tile garden', 'Rüstem Paşa’nın çini bahçesi', ['rustem-pasha'], [], 'GL SR', False, 'sinan', False),
    ('XXVII', 'Mihrimah’s equinox', 'Mihrimah’ın ekinoksu', ['mihrimah-edirnekapi', 'mihrimah-uskudar'], [], 'SK', False, 'sinan', True),
    ('XXVIII', 'Şehzade’s symmetry', 'Şehzade’nin simetrisi', ['sehzade'], [], 'CA', False, 'sinan', False),
    ('XXIX', 'Muqarnas', 'Mukarnas', [], [], 'CA', False, 'craft-kit', False),
    ('XXX', 'Girih', 'Girih', [], [], 'SR', False, 'craft-kit', False),
    ('XXXI', 'Making an İznik tile', 'Bir İznik çinisinin yapımı', [], [], 'PU GL', False, 'craft-kit', False),
    ('XXXII', '20,000 tiles', '20.000 çini', ['sultanahmet-mosque'], [], 'SB', False, 'mosques', False),
    ('XXXIII', 'Evolution of the dome', 'Kubbenin evrimi', [], [], 'CA TM', True, 'mosques', False),
    ('XXXIV', 'Mahya', 'Mahya', [], [], 'SR', False, 'mosques', False),
    ('XXXV', 'Calligraphy, stroke by stroke', 'Harf harf hat', ['hagia-sophia', 'suleymaniye'], [], 'SR', False, 'craft-kit', False),
    ('XXXVI', 'Alexander Sarcophagus in colour', 'Renkleriyle İskender Lahdi', ['archaeology-museums'], [], 'RL WR', True, 'archaeology-museums', False),
    ('XXXVII', 'The Kadesh treaty', 'Kadeş Antlaşması', ['archaeology-museums'], [], 'SR', False, 'archaeology-museums', False),
    ('XXXVIII', 'The Topkapı dagger', 'Topkapı Hançeri', ['topkapi'], [], 'TT', False, 'palaces', False),
    ('XXXIX', 'The Harem maze', 'Harem’in dehlizleri', ['topkapi'], [], 'CA CS', False, 'palaces', False),
    ('XL', 'The carpet weaves itself', 'Kendini dokuyan halı', ['turkish-islamic-arts'], [], 'SR', False, 'collections', False),
    ('XLI', 'The Tortoise Trainer', 'Kaplumbağa Terbiyecisi', ['pera-museum'], [], 'MM', False, 'collections', True),
    ('XLII', 'Panorama 1453', 'Panorama 1453', ['panorama-1453'], [], 'LU', False, 'palaces', False),
    ('XLIII', 'The sultan’s caique', 'Saltanat kayığı', ['naval-museum'], [], 'TT MM', False, 'collections', False),
    ('XLIV', 'Mehter', 'Mehter', ['military-museum'], [], 'VO MM', False, 'collections', False),
    ('XLV', 'The Golden Horn chain', 'Haliç zinciri', ['military-museum'], [], 'TT TM', False, 'collections', False),
    ('XLVI', 'The Horses of San Marco', 'San Marco atları', ['san-marco', 'hippodrome'], [], 'TT TM', False, 'abroad', False),
    ('XLVII', 'The Tetrarchs’ foot', 'Tetrarkların ayağı', ['san-marco', 'archaeology-museums'], [], 'WR TM', False, 'abroad', False),
]
DEPTH = set('DP GL RL MM SB LU SK'.split())
RECONSTRUCTION = set('WR CA CS TM TT PU SR WK VO'.split())
# Concept items for the pieces that belong to no single place (craft kit, cross-city).
CONCEPTS = {
    'XXIX': ('Q1356021', 2551448891, 'Muqarnas', 'Mukarnas'),
    'XXX': ('Q17050256', 2487151914, 'Girih', 'Girih'),
    'XXXI': ('Q2696793', 2512855627, 'İznik pottery', 'İznik çinisi'),
    'XXXIII': ('Q12493', 2534319427, 'Dome', 'Kubbe'),
    'XXXIV': ('Q1885072', 2430547866, 'Mahya', 'Mahya'),
}


def main():
    places = {p['id']: p for p in json.loads(
        (ROOT / 'assets/content/places/istanbul.json').read_text())['records']}
    records, sources = [], []
    for numeral, en, tr, place_ids, artworks, codes, flagship, pack, imagined in REGISTER:
        techniques = codes.split()
        honesty = ['ORIGINAL']
        if DEPTH & set(techniques):
            honesty.append('DEPTH')
        if RECONSTRUCTION & set(techniques):
            honesty.append('RECONSTRUCTION')
        if imagined:
            honesty.append('IMAGINED')
        if numeral in CONCEPTS:
            qid, revision, label_en, label_tr = CONCEPTS[numeral]
            source_ids = ['wd-' + qid.lower()]
            sources.append(dict(
                id=source_ids[0],
                title=dict(en=f'{label_en} — Wikidata', tr=f'{label_tr} — Wikidata'),
                url=f'https://www.wikidata.org/w/index.php?title={qid}&oldid={revision}',
                author=dict(en='Wikidata contributors', tr='Wikidata katkıda bulunanları'),
                accessedAt=DATE, licence=dict(en='CC0', tr='CC0')))
        else:
            # Identity of the place(s) the piece will be built at.
            source_ids = [f'wd-{places[p]["qid"].lower()}' for p in place_ids]
        record = dict(
            id='milestone-' + numeral.lower(), numeral=numeral, title=dict(en=en, tr=tr),
            places=place_ids, artworks=artworks, techniques=techniques, honesty=honesty,
            status='planned', manifestPath=None, packId=pack, sources=source_ids)
        if flagship:
            record['flagship'] = True
        records.append(record)
    for path, kind, data in [
        ('milestones/register.json', 'milestones', records),
        ('sources/register.json', 'sources', sources),
    ]:
        out = ROOT / 'assets/content' / path
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(dict(schemaVersion=1, kind=kind, records=data),
                                  ensure_ascii=False, indent=2) + '\n')
    print(f'{len(records)} planned Milestones, {len(sources)} concept sources')


if __name__ == '__main__':
    main()
