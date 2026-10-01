"""Usage: python3 tool/first_run/build_peninsula.py [--fetch] — OSM lines → lib/first_run/peninsula_data.dart.

Inputs are Overpass `out geom` responses kept in studio/first_run/ (re-download
with --fetch): osm_coastline.json (natural=coastline ways in BBOX) and
osm_street_{a,b}.json (STREET_QUERIES: the T1 tram, Divanyolu and its side
streets, Hagia Sophia and Sultanahmet footprints and the buildings beside the
Milion). Coastline ways are chained by shared node ids, clipped to BBOX and
simplified with Ramer–Douglas–Peucker at TOLERANCE_M; street ways are kept
whole. Everything is projected to metres east/north of the Milion
(equirectangular about mile zero, the projection lib/first_run draws with).
Output: generated Dart consts plus studio/first_run/peninsula_source.json with
queries, OSM base timestamps, input/output SHA-256 and counts.
Data © OpenStreetMap contributors, ODbL 1.0.
"""
import hashlib
import json
import math
import sys
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / 'studio/first_run/osm_coastline.json'
OUT = ROOT / 'lib/first_run/peninsula_data.dart'
EVIDENCE = ROOT / 'studio/first_run/peninsula_source.json'
BBOX = (40.975, 28.90, 41.065, 29.07)  # south, west, north, east
QUERY = '[out:json][timeout:90];way["natural"="coastline"](%s,%s,%s,%s);out geom;' % BBOX
MILION = (41.008043, 28.978066)  # Wikidata Q1187329 P625, as lib/content/geography.dart
EARTH_M = 6371008.8
TOLERANCE_M = 12.0
STREET_QUERIES = {
    'osm_street_a.json': '[out:json][timeout:60];(way["railway"="tram"](41.0035,28.9680,41.0125,28.9885);'
    'way["highway"]["name"~"Divan Yolu|Yerebatan|Alemdar|Babıhümayun"](41.0035,28.9680,41.0125,28.9885);'
    'way["wikidata"~"^(Q12506|Q216511|Q80541|Q1187329)$"](41.0,28.96,41.015,28.99);'
    'relation["wikidata"~"^(Q12506|Q216511|Q80541)$"](41.0,28.96,41.015,28.99););out geom;',
    'osm_street_b.json': '[out:json][timeout:60];(way["highway"]["name"~"Divanyolu|Divan Yolu"](41.0035,28.9680,41.0125,28.9885);'
    'way(around:45,41.0084795,28.9783826)["building"];way(around:25,41.008043,28.978066)["building"];);out geom;',
}


def fetch():
    for path, query in [(RAW, QUERY)] + [(RAW.parent / name, q) for name, q in STREET_QUERIES.items()]:
        body = urllib.parse.urlencode({'data': query}).encode()
        request = urllib.request.Request(
            'https://overpass-api.de/api/interpreter', body,
            headers={'User-Agent': 'milion-build/1.0 (private development)'})
        with urllib.request.urlopen(request, timeout=120) as response:
            path.write_bytes(response.read())


def street_kind(tags):
    if tags.get('railway') == 'tram':
        return 0  # tram rails
    if 'highway' in tags:
        return 1  # street edges and footways
    if tags.get('wikidata') in ('Q12506', 'Q80541'):
        return 3  # Hagia Sophia, Sultan Ahmed: named landmarks
    return 2  # other buildings


def project(lat, lng):
    x = math.radians(lng - MILION[1]) * math.cos(math.radians(MILION[0])) * EARTH_M
    y = math.radians(lat - MILION[0]) * EARTH_M
    return x, y


def chains(ways):
    """Join coastline ways that share end nodes, preserving OSM direction."""
    pieces = [(w['nodes'], w['geometry']) for w in ways]
    merged = True
    while merged:
        merged = False
        for i in range(len(pieces)):
            for j in range(len(pieces)):
                if i != j and pieces[i][0][-1] == pieces[j][0][0]:
                    a, b = pieces[i], pieces[j]
                    pieces[i] = (a[0] + b[0][1:], a[1] + b[1][1:])
                    del pieces[j]
                    merged = True
                    break
            if merged:
                break
    return [[(g['lat'], g['lon']) for g in geometry] for _, geometry in pieces]


def clip(line):
    """Split a polyline at the bounding box; Liang–Barsky per segment."""
    s, w, n, e = BBOX
    out, current = [], []
    for (y0, x0), (y1, x1) in zip(line, line[1:]):
        t0, t1, dx, dy = 0.0, 1.0, x1 - x0, y1 - y0
        keep = True
        for p, q in ((-dx, x0 - w), (dx, e - x0), (-dy, y0 - s), (dy, n - y0)):
            if p == 0:
                if q < 0:
                    keep = False
                    break
            else:
                r = q / p
                if p < 0:
                    t0 = max(t0, r)
                else:
                    t1 = min(t1, r)
        if not keep or t0 > t1:
            if current:
                out.append(current)
                current = []
            continue
        a = (y0 + t0 * dy, x0 + t0 * dx)
        b = (y0 + t1 * dy, x0 + t1 * dx)
        if not current:
            current = [a]
        current.append(b)
        if t1 < 1:
            out.append(current)
            current = []
    if current:
        out.append(current)
    return out


def simplify(points):
    if len(points) < 3:
        return points
    (ax, ay), (bx, by) = points[0], points[-1]
    length = math.hypot(bx - ax, by - ay)
    best, index = -1.0, 0
    for i, (px, py) in enumerate(points[1:-1], 1):
        d = (abs((bx - ax) * (ay - py) - (ax - px) * (by - ay)) / length
             if length else math.hypot(px - ax, py - ay))
        if d > best:
            best, index = d, i
    if best <= TOLERANCE_M:
        return [points[0], points[-1]]
    return simplify(points[:index + 1])[:-1] + simplify(points[index:])


def main():
    if '--fetch' in sys.argv:
        fetch()
    raw = RAW.read_bytes()
    data = json.loads(raw)
    lines = []
    for chain in chains([e for e in data['elements'] if e['type'] == 'way']):
        for part in clip(chain):
            projected = simplify([project(lat, lng) for lat, lng in part])
            if len(projected) >= 2 and math.dist(projected[0], projected[-1]) + len(projected) > 60:
                lines.append([(round(x), round(y)) for x, y in projected])
    lines.sort(key=len, reverse=True)
    street, seen, street_raw = [], set(), {}
    for name in STREET_QUERIES:
        street_raw[name] = (RAW.parent / name).read_bytes()
        for e in json.loads(street_raw[name])['elements']:
            geometries = ([e['geometry']] if e['type'] == 'way'
                          else [m['geometry'] for m in e.get('members', []) if 'geometry' in m])
            for geometry in geometries:
                key = (e['type'], e['id'], len(geometry), geometry[0]['lat'])
                if key in seen:
                    continue
                seen.add(key)
                points = [project(g['lat'], g['lon']) for g in geometry]
                street.append([street_kind(e.get('tags', {}))] +
                              [v for x, y in points for v in (round(x, 1), round(y, 1))])
    street.sort(key=lambda line: (line[0], len(line)))
    body = ',\n'.join(
        '  [' + ', '.join(f'{x}, {y}' for x, y in line) + ']' for line in lines)
    street_body = ',\n'.join('  [' + ', '.join(str(v) for v in line) + ']' for line in street)
    dart = (
        '// GENERATED by tool/first_run/build_peninsula.py; do not edit.\n'
        '// dart format off\n'
        '// © OpenStreetMap contributors, ODbL 1.0. natural=coastline, '
        f'base {data["osm3s"]["timestamp_osm_base"]}.\n'
        '// Each list is x0, y0, x1, y1… in metres east/north of the Milion.\n'
        f'const peninsulaCoast = <List<int>>[\n{body},\n];\n\n'
        '// Street scale around the Milion: [kind, x0, y0, x1, y1…]; kind 0 tram,\n'
        '// 1 street, 2 building, 3 named landmark (Hagia Sophia, Sultan Ahmed).\n'
        f'const milionStreet = <List<double>>[\n{street_body},\n];\n')
    OUT.write_text(dart)
    EVIDENCE.write_text(json.dumps({
        'query': QUERY,
        'endpoint': 'https://overpass-api.de/api/interpreter',
        'osmBase': data['osm3s']['timestamp_osm_base'],
        'licence': 'ODbL 1.0, © OpenStreetMap contributors',
        'rawSha256': hashlib.sha256(raw).hexdigest(),
        'ways': sum(1 for e in data['elements'] if e['type'] == 'way'),
        'rawNodes': sum(len(e.get('geometry', [])) for e in data['elements']),
        'toleranceMetres': TOLERANCE_M,
        'polylines': len(lines),
        'points': sum(len(line) for line in lines),
        'streetQueries': STREET_QUERIES,
        'streetOsmBase': {n: json.loads(b)['osm3s']['timestamp_osm_base'] for n, b in street_raw.items()},
        'streetRawSha256': {n: hashlib.sha256(b).hexdigest() for n, b in street_raw.items()},
        'streetLines': len(street),
        'outputSha256': hashlib.sha256(dart.encode()).hexdigest(),
    }, indent=2, ensure_ascii=False) + '\n')
    print(f'{len(lines)} polylines, {sum(len(l) for l in lines)} points → {OUT.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
