"""Usage: python3.11 tool/atlas/build_historic.py [--fetch]

Resolves the hand-authored historic layers of tool/atlas/historic_spec.py
into studio/atlas/historic/<layer>.geojson and sources.json, which
tool/atlas/build_atlas.py then compacts into assets/atlas/historic.json.

--fetch runs one SPARQL query against Wikidata (the numbered wall inventory
plus every item the spec names) and keeps the response, query and date in
studio/atlas/wikidata_historic.json; without it the build reads that file.
OSM ways come from the pinned Overpass walls query (fetch_osm.py walls).
Registry places come from assets/content/places/istanbul.json.
"""
import json
import re
import sys
import urllib.parse
import urllib.request
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import historic_spec as spec  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
RAW_WD = ROOT / 'studio/atlas/wikidata_historic.json'
RAW_WALLS = ROOT / 'studio/cache/atlas/raw/walls.json'
PLACES = ROOT / 'assets/content/places/istanbul.json'
OUT = ROOT / 'studio/atlas/historic'
ENDPOINT = 'https://query.wikidata.org/sparql'
USER_AGENT = 'milion-build/1.0 (private development)'
LAYERS = ['walls', 'coast', 'streets', 'hills', 'siege1453', 'below']
HAND_OK = {'approximate', 'conjectural'}


def refs(feature):
    for key in ('line', 'polygon'):
        yield from feature.get(key, [])
    if 'point' in feature:
        yield feature['point']


def query():
    qids = sorted({r[1] for f in spec.FEATURES for r in refs(f) if r[0] == 'wd'})
    labels = sorted({r[1] for f in spec.FEATURES for r in refs(f) if r[0] == 'label'})
    values = ' '.join(f'wd:{q}' for q in qids)
    label_values = ' '.join(f'"{l}"@en' for l in labels)
    return (
        'SELECT ?item ?tr ?en ?coord WHERE { {'
        ' SERVICE wikibase:around { ?item wdt:P625 ?coord .'
        ' bd:serviceParam wikibase:center "Point(28.955 41.020)"^^geo:wktLiteral .'
        ' bd:serviceParam wikibase:radius "7" . }'
        ' ?item rdfs:label ?tr . FILTER(LANG(?tr) = "tr")'
        ' FILTER(REGEX(?tr, "^(Kara Surları, Ana Sur, T[0-9]+|Haliç Surları, [0-9]+\\\\. Kule|'
        'Marmara Surları, [0-9]+\\\\. Kule)$")) }'
        f' UNION {{ VALUES ?item {{ {values} }} ?item wdt:P625 ?coord . }}'
        f' UNION {{ VALUES ?en {{ {label_values} }} ?item rdfs:label ?en ; wdt:P625 ?coord . }}'
        ' OPTIONAL { ?item rdfs:label ?tr . FILTER(LANG(?tr) = "tr") }'
        ' OPTIONAL { ?item rdfs:label ?en . FILTER(LANG(?en) = "en") } }')


def fetch():
    q = query()
    url = ENDPOINT + '?' + urllib.parse.urlencode({'query': q, 'format': 'json'})
    request = urllib.request.Request(url, headers={
        'User-Agent': USER_AGENT, 'Accept': 'application/sparql-results+json'})
    with urllib.request.urlopen(request, timeout=180) as response:
        result = json.loads(response.read())
    RAW_WD.write_text(json.dumps({'endpoint': ENDPOINT, 'query': q,
                                  'fetchedAt': date.today().isoformat(),
                                  'licence': 'CC0 1.0 (Wikidata)', 'result': result},
                                 ensure_ascii=False, indent=0) + '\n', encoding='utf-8')


def point_of(wkt):
    lng, lat = map(float, re.findall(r'-?[\d.]+', wkt))
    return round(lat, 7), round(lng, 7)


def load_wikidata():
    raw = json.loads(RAW_WD.read_text(encoding='utf-8'))
    items, by_label, towers = {}, {}, {k: {} for k in spec.WALL_INVENTORY}
    for b in raw['result']['results']['bindings']:
        qid = b['item']['value'].rsplit('/', 1)[1]
        p = point_of(b['coord']['value'])
        items.setdefault(qid, p)  # first P625 if an item has several
        if 'en' in b:
            by_label.setdefault(b['en']['value'], set()).add(qid)
        tr = b.get('tr', {}).get('value', '')
        for series, pattern in spec.WALL_INVENTORY.items():
            m = re.match(pattern, tr)
            if m:
                towers[series].setdefault(int(m.group(1)), (qid, p))
    return items, by_label, towers


def load_osm():
    raw = json.loads(RAW_WALLS.read_text(encoding='utf-8'))
    return {e['id']: [(round(n['lat'], 7), round(n['lon'], 7)) for n in e['geometry']]
            for e in raw['elements'] if e['type'] == 'way'}, raw['osm3s']['timestamp_osm_base']


def resolve(feature, wd, labels, towers, osm, places):
    def one(ref):
        kind = ref[0]
        if kind == 'wd':
            if ref[1] not in wd:
                raise SystemExit(f'{feature["id"]}: {ref[1]} has no P625 in the response')
            return [wd[ref[1]]]
        if kind == 'label':
            qids = labels.get(ref[1], set()) & set(wd)
            if len(qids) != 1:
                raise SystemExit(f'{feature["id"]}: label {ref[1]!r} matched {sorted(qids)}')
            return [wd[qids.pop()]]
        if kind == 'place':
            return [places[ref[1]]]
        if kind == 'towers':
            series, a, b = ref[1], ref[2], ref[3]
            step = 1 if b >= a else -1
            pts = [towers[series][n][1] for n in range(a, b + step, step) if n in towers[series]]
            if not pts or a not in towers[series] or b not in towers[series]:
                raise SystemExit(f'{feature["id"]}: {series} towers {a}–{b} missing an end')
            return pts
        if kind == 'osm':
            pts = osm[ref[1]]
            return pts[::-1] if ref[2] else pts
        if kind == 'at':
            if feature['certainty'] not in HAND_OK:
                raise SystemExit(f'{feature["id"]}: hand-placed point in a '
                                 f'{feature["certainty"]} feature')
            return [(ref[1], ref[2])]
        raise SystemExit(f'{feature["id"]}: unknown reference {ref}')

    def chain(rs):
        out = []
        for r in rs:
            for p in one(r):
                if not out or out[-1] != p:
                    out.append(p)
        return [[lng, lat] for lat, lng in out]

    if 'point' in feature:
        lat, lng = one(feature['point'])[0]
        return {'type': 'Point', 'coordinates': [lng, lat]}
    if 'line' in feature:
        return {'type': 'LineString', 'coordinates': chain(feature['line'])}
    ring = chain(feature['polygon'])
    return {'type': 'Polygon', 'coordinates': [ring + [ring[0]]]}


def build():
    wd, labels, towers = load_wikidata()
    osm, osm_base = load_osm()
    places = {r['id']: (r['coordinates']['lat'], r['coordinates']['lng'])
              for r in json.loads(PLACES.read_text(encoding='utf-8'))['records']}
    source_ids = {s['id'] for s in spec.SOURCES}
    by_layer = {l: [] for l in LAYERS}
    seen = set()
    for f in spec.FEATURES:
        if f['id'] in seen:
            raise SystemExit(f'duplicate id {f["id"]}')
        seen.add(f['id'])
        missing = set(f['sources']) - source_ids
        if missing:
            raise SystemExit(f'{f["id"]}: unknown sources {missing}')
        if f['end'] is not None and f['end'] < f['start']:
            raise SystemExit(f'{f["id"]}: ends before it starts')
        by_layer[f['layer']].append({
            'type': 'Feature',
            'properties': {
                'id': f['id'], 'layer': f['layer'], 'kind': f['kind'], 'names': f['names'],
                'from': f['start'], 'to': f['end'], 'certainty': f['certainty'],
                'sources': f['sources'], 'note': f['note'],
            },
            'geometry': resolve(f, wd, labels, towers, osm, places),
        })
    OUT.mkdir(parents=True, exist_ok=True)
    for layer, features in by_layer.items():
        (OUT / f'{layer}.geojson').write_text(json.dumps(
            {'type': 'FeatureCollection', 'features': features}, ensure_ascii=False,
            indent=1) + '\n', encoding='utf-8')
    (OUT / 'sources.json').write_text(json.dumps(
        {'records': spec.SOURCES, 'osmBase': osm_base}, ensure_ascii=False, indent=1) + '\n',
        encoding='utf-8')
    counts = {k: len(v) for k, v in towers.items()}
    print(f'{len(seen)} historic features; wall towers {counts}; OSM walls {osm_base}')


if __name__ == '__main__':
    if '--fetch' in sys.argv:
        fetch()
    build()
