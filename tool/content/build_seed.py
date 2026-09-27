"""Build draft assets from reviewed selections: python3 tool/content/build_seed.py.

Offline and deterministic. Wikidata exports, OSM overrides and human selection
are pinned in evidence/; this script never chooses a search result for you.
"""
import csv
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'tool/content'
OUT = ROOT / 'assets/content'
DATE = '2026-09-27'


def loc(en, tr):
    return dict(en=en, tr=tr)


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')


def document(kind, records):
    return dict(schemaVersion=1, kind=kind, records=records)


def source(id, en, tr, url, author='Wikidata contributors', author_tr='Wikidata katkıda bulunanları', licence='CC0'):
    return dict(id=id, title=loc(en, tr), url=url, author=loc(author, author_tr),
                accessedAt=DATE, licence=None if licence is None else loc(licence, licence))


def values(entity, prop):
    claims = [c for c in entity.get('claims', {}).get(prop, []) if c.get('rank') != 'deprecated' and 'datavalue' in c['mainsnak']]
    preferred = [c for c in claims if c.get('rank') == 'preferred']
    return [c['mainsnak']['datavalue']['value'] for c in preferred or claims]


def build():
    selected = json.loads((BASE / 'seed_selection.json').read_text())
    overrides_path = BASE / 'seed_overrides.json'
    overrides = json.loads(overrides_path.read_text()) if overrides_path.exists() else {}
    rows = list(csv.DictReader((BASE / 'seed_places.tsv').open(), delimiter='\t'))
    sources, places, evidence = [], [], []
    district_names = dict(re.findall(r"(\w+)\('([^']+)'\)", (ROOT / 'lib/content/models.dart').read_text()))
    errors = []
    for row in rows:
        id = row['id']
        if id not in selected:
            errors.append(f'{id}: no reviewed QID')
            continue
        qid = selected[id]
        path = BASE / 'evidence' / (qid + '.json')
        if not path.exists():
            errors.append(f'{id}: entity export missing')
            continue
        entity = json.loads(path.read_text())
        if entity.get('id') != qid:
            errors.append(f'{id}: resolve redirected QID {qid} to {entity.get("id")}')
            continue
        override = overrides.get(id, {})
        coordinates = values(entity, 'P625')
        coordinates.sort(key=lambda c: c.get('precision') or 1)
        point = override.get('coordinates')
        if not point and coordinates:
            point = dict(lat=coordinates[0]['latitude'], lng=coordinates[0]['longitude'])
        if not point:
            errors.append(f'{id}: no verified coordinate')
            continue
        english = override.get('en', entity.get('labels', {}).get('en', {}).get('value', row['query']))
        district = override.get('district', row['district'])
        district = None if district == '-' else district
        phase = row['phase']
        wave = 'abroad' if phase == 'P31' else 'city' if phase == 'P32' else 'museums' if int(phase[1:]) >= 28 else 'mosques' if int(phase[1:]) >= 24 else 'byzantine'
        names = loc(english, row['tr'])
        dates = values(entity, 'P571')
        date = next((d for d in dates if d.get('precision', 0) >= 9), None)
        if date:
            year = int(date['time'].split('-')[0].lstrip('+')) if date['time'].startswith('+') else -int(date['time'][1:].split('-')[0])
            date_en = f'{abs(year)} BCE' if year < 0 else str(year)
            date_tr = f'MÖ {abs(year)}' if year < 0 else str(year)
            hook = loc(f'{english}: an origin dated to {date_en}.', f'{row["tr"]}: kuruluşu {date_tr} yılına tarihleniyor.')
        elif district:
            d = district_names[district]
            hook = loc(f'{english} places this chapter in {d}.', f'{row["tr"]}, bu bölümün {d} durağı.')
        else:
            hook = loc(f'{english}: a stop beyond Istanbul for the city’s wider story.', f'{row["tr"]}: İstanbul’un şehir dışına uzanan öyküsünde bir durak.')
        hook = override.get('hook', hook)
        source_id = 'wd-' + qid.lower()
        sources.append(source(source_id, english + ' — Wikidata', row['tr'] + ' — Wikidata',
            f'https://www.wikidata.org/w/index.php?title={qid}&oldid={entity["lastrevid"]}'))
        refs = [source_id]
        district_evidence = BASE / 'evidence' / (id + '-district.json')
        if district_evidence.exists() and id != 'fatih-mosque':
            osm = json.loads(district_evidence.read_text())
            if osm.get('osm_type') == 'relation':
                sid = 'district-' + id
                refs.append(sid)
                sources.append(source(sid, english + ' — district boundary', row['tr'] + ' — ilçe sınırı',
                    f'https://www.openstreetmap.org/{osm["osm_type"]}/{osm["osm_id"]}',
                    'OpenStreetMap contributors', 'OpenStreetMap katkıda bulunanları', 'ODbL 1.0'))
        if 'coordinateSource' in override:
            sid = 'geo-' + id
            refs.append(sid)
            sources.append(source(sid, english + ' — location', row['tr'] + ' — konum', override['coordinateSource'],
                'OpenStreetMap contributors', 'OpenStreetMap katkıda bulunanları', 'ODbL 1.0'))
        historical = override.get('historicalNames', [])
        places.append(dict(id=id, names=names, historicalNames=historical,
            categories=row['categories'].split(','), eras=override.get('eras', [row['era']]), district=district, coordinates=point,
            entrance=None, currentFunction=loc('Not yet field-checked', 'Yerinde henüz doğrulanmadı'),
            status=dict(value='unknown', checkedAt=None), qid=qid,
            tags=['seed', 'entrance-unverified'] + override.get('tags', []), hook=hook, review='draft', wave=wave,
            reviewPhase=phase, outsideProvince=district is None, strata=[], sources=refs))
        evidence.append(dict(id=id, qid=qid, revision=entity['lastrevid'], accessedAt=DATE,
            sha256=hashlib.sha256(path.read_bytes()).hexdigest(), coordinates=point,
            coordinateSource=override.get('coordinateSource', f'https://www.wikidata.org/wiki/{qid}#P625'),
            district=district, administrativeClaims=values(entity, 'P131'), typeClaims=values(entity, 'P31'),
            note=override.get('note', 'Wikidata identity/type/P625 checked; district uses the site point, not every extent of a linear or area feature. Entrance unverified.')))
    if errors:
        raise SystemExit('\n'.join(errors))
    sources.extend([
        source('roman-mile', 'Miglio (1934)', 'Roma mili (1934)', 'https://www.treccani.it/enciclopedia/miglio_(Enciclopedia-Italiana)/', 'Aristide Calderini', 'Aristide Calderini', None),
        source('province-bounds', 'Istanbul province boundary — OSM 223474', 'İstanbul il sınırı — OSM 223474',
               'https://www.openstreetmap.org/relation/223474', 'OpenStreetMap contributors', 'OpenStreetMap katkıda bulunanları', 'ODbL 1.0'),
        source('chora-guide', 'Guide to the Kariye Mosaics', 'Kariye Mozaikleri Rehberi',
               'https://kulturenvanteri.com/en/kariye-mozaikleri-rehberi/', 'Caner Cangül, Engin Mutlu, Kader Ali Çayır', 'Caner Cangül, Engin Mutlu, Kader Ali Çayır', None),
        source('anastasis-photo', 'Anastasis reference photograph', 'Anastasis referans fotoğrafı',
               'https://cdn.kulturenvanteri.com/wp-content/uploads/2019/11/CAN09421.jpg', 'Caner Cangül', 'Caner Cangül', None),
        source('judgment-photo', 'Last Judgment reference photograph', 'Son Yargı referans fotoğrafı',
               'https://cdn.kulturenvanteri.com/wp-content/uploads/2024/05/Mahser.jpg', 'Caner Cangül', 'Caner Cangül', None),
    ])
    media = [dict(id=id, path=path, kind='image', credit=loc('Caner Cangül / Kültür Envanteri', 'Caner Cangül / Kültür Envanteri'),
                  source=src, era='modern', historicalPhoto=False) for id, path, src in [
        ('anastasis-original', 'assets/anastasis/flat_reference.jpg', 'anastasis-photo'),
        ('judgment-original', 'assets/last_judgment/vault_reference.jpg', 'judgment-photo')]]
    write(OUT / 'places/istanbul.json', document('places', places))
    write(OUT / 'sources.json', document('sources', sources))
    write(OUT / 'media.json', document('media', media))
    write(OUT / 'routes.json', document('routes', []))
    write(OUT / 'hunts.json', document('hunts', []))
    write(OUT / 'index.json', dict(schemaVersion=1, files={
        'places': ['assets/content/places/istanbul.json'], 'artworks': ['assets/content/artworks/chora.json'],
        'milestones': ['assets/content/milestones/chora.json'],
        **{k: [f'assets/content/{k}.json'] for k in ['sources', 'media', 'routes', 'hunts']}}))
    write(BASE / 'verification.json', dict(checkedAt=DATE, places=evidence))
    print(f'{len(places)} draft places, {len(sources)} sources; none promoted to reviewed.')


if __name__ == '__main__':
    build()
