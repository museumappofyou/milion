"""Usage: python3.11 tool/atlas/build_atlas.py

Builds the Atlas's offline map (P10) from the pinned Overpass responses in
studio/cache/atlas/raw/ (fetch them with tool/atlas/fetch_osm.py) and the
hand-authored historic layers in studio/atlas/historic/:

  assets/atlas/atlas.bin       OSM layers, projected and delta-encoded
  assets/atlas/historic.json   historic layers (walls, harbours, the Mese,
                               hills, 1453, Below), compacted, with sources
  assets/content/sources/atlas.json   the historic layers' sources
  studio/atlas/atlas_source.json      queries, osm_base, input/output hashes

Projection: metres east/north of the Milion, equirectangular about mile
zero, as lib/first_run and lib/atlas draw. Coordinates are rounded to whole
metres. Line and area layers are simplified (Ramer–Douglas–Peucker) twice,
"fine" and "coarse", and the app picks one by zoom. The sea is not stored:
land polygons are closed from the coastline (land on the left of OSM's
direction) along the edges of CLIP, and the app paints water underneath.

atlas.bin layout (little-endian; v = unsigned LEB128, z = zigzag LEB128):
  "MLAT" u8 version, v string count, strings (v length, UTF-8),
  v layer count, then per layer: u8 id, u8 lod, u8 geometry
  (0 points, 1 lines, 2 polygons), v feature count, and per feature:
  u8 class, v name (0 none, else string index + 1), z minX z minY z maxX
  z maxY, v ring count, per ring v point count and points as z deltas
  (the first from minX/minY).
Data © OpenStreetMap contributors, ODbL 1.0.
"""
import hashlib
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from osm_queries import ENDPOINT, QUERIES  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / 'studio/cache/atlas/raw'
HISTORIC = ROOT / 'studio/atlas/historic'
OUT_BIN = ROOT / 'assets/atlas/atlas.bin'
OUT_HISTORIC = ROOT / 'assets/atlas/historic.json'
OUT_SOURCES = ROOT / 'assets/content/sources/atlas.json'
EVIDENCE = ROOT / 'studio/atlas/atlas_source.json'

MILION = (41.008043, 28.978066)  # Wikidata Q1187329 P625, as lib/content/geography.dart
EARTH_M = 6371008.8
# Land is closed against this box (south, west, north, east): the province
# bounds of lib/content/geography.dart, rounded outwards.
CLIP = (40.73, 27.96, 41.68, 29.97)
BUDGET_BYTES = 12_000_000

VERSION = 1
POINTS, LINES, POLYGONS = 0, 1, 2
FINE, COARSE = 0, 1

# Layer ids are shared with lib/atlas/atlas_data.dart (AtlasLayer).
LAYER = {
    'land': 1, 'water': 2, 'districts': 3, 'province': 4, 'roads': 5,
    'rail': 6, 'ferry': 7, 'stops': 8, 'parks': 9, 'buildings': 10,
    'land_then': 12,  # 11: district labels
}
# Simplification tolerance in metres, fine and coarse.
TOLERANCE = {
    'land': (4, 40), 'land_then': (4, 40), 'water': (6, 40), 'districts': (8, 60), 'province': (8, 60),
    'roads': (4, 30), 'rail': (4, 30), 'ferry': (15, 60), 'parks': (4, 30),
    'buildings': (0.8, None),
}
ROAD_CLASS = {'motorway': 0, 'trunk': 1, 'primary': 2, 'secondary': 3, 'tertiary': 4}
RAIL_CLASS = {'rail': 0, 'subway': 1, 'light_rail': 2, 'tram': 3, 'funicular': 4,
              'monorail': 2, 'narrow_gauge': 0}
STOP_CLASS = {'station': 0, 'halt': 0, 'tram_stop': 1, 'ferry_terminal': 2}
MIN_PARK_M2 = 5_000
MIN_BUILDING_M2 = 12


# --- geometry -----------------------------------------------------------------

def project(lat, lon):
    x = math.radians(lon - MILION[1]) * math.cos(math.radians(MILION[0])) * EARTH_M
    y = math.radians(lat - MILION[0]) * EARTH_M
    return x, y


def rdp(points, tolerance):
    """Ramer–Douglas–Peucker, iterative; keeps the end points."""
    if tolerance is None or len(points) < 3:
        return list(points)
    keep = [False] * len(points)
    keep[0] = keep[-1] = True
    stack = [(0, len(points) - 1)]
    while stack:
        a, b = stack.pop()
        (ax, ay), (bx, by) = points[a], points[b]
        dx, dy = bx - ax, by - ay
        length = math.hypot(dx, dy)
        best, index = -1.0, -1
        for i in range(a + 1, b):
            px, py = points[i]
            d = (abs(dy * (px - ax) - dx * (py - ay)) / length
                 if length > 0 else math.hypot(px - ax, py - ay))
            if d > best:
                best, index = d, i
        if best > tolerance:
            keep[index] = True
            stack.append((a, index))
            stack.append((index, b))
    return [p for p, k in zip(points, keep) if k]


def quantise(points):
    out = []
    for x, y in points:
        q = (int(round(x)), int(round(y)))
        if not out or out[-1] != q:
            out.append(q)
    return out


def area(ring):
    s = 0.0
    for (x0, y0), (x1, y1) in zip(ring, ring[1:] + ring[:1]):
        s += x0 * y1 - x1 * y0
    return s / 2


def chain(ways):
    """Join ways (lists of (node id, point)) that share end nodes."""
    pieces = [list(w) for w in ways if len(w) >= 2]
    by_start = {}
    for i, p in enumerate(pieces):
        by_start.setdefault(p[0][0], []).append(i)
    used = [False] * len(pieces)
    out = []
    for i in range(len(pieces)):
        if used[i]:
            continue
        used[i] = True
        line = pieces[i][:]
        # extend forwards
        while line[-1][0] != line[0][0]:
            nxt = next((j for j in by_start.get(line[-1][0], []) if not used[j]), None)
            if nxt is None:
                break
            used[nxt] = True
            line += pieces[nxt][1:]
        out.append(line)
    # join chains whose end meets another chain's start (order-independent)
    merged = True
    while merged:
        merged = False
        for i in range(len(out)):
            if out[i][0][0] == out[i][-1][0]:
                continue
            for j in range(len(out)):
                if i != j and out[i][-1][0] == out[j][0][0] and out[j][0][0] != out[j][-1][0]:
                    out[i] = out[i] + out[j][1:]
                    del out[j]
                    merged = True
                    break
            if merged:
                break
    return out


def chain_undirected(ways):
    """Join ways into rings regardless of direction (relation members)."""
    pieces = [list(w) for w in ways if len(w) >= 2]
    rings = []
    while pieces:
        ring = pieces.pop(0)
        changed = True
        while changed and ring[0][0] != ring[-1][0]:
            changed = False
            for k, p in enumerate(pieces):
                if p[0][0] == ring[-1][0]:
                    ring += p[1:]
                elif p[-1][0] == ring[-1][0]:
                    ring += p[::-1][1:]
                elif p[-1][0] == ring[0][0]:
                    ring = p + ring[1:]
                elif p[0][0] == ring[0][0]:
                    ring = p[::-1] + ring[1:]
                else:
                    continue
                del pieces[k]
                changed = True
                break
        rings.append(ring)
    return rings


def clip_box():
    s, w, n, e = CLIP
    x0, y0 = project(s, w)
    x1, y1 = project(n, e)
    return x0, y0, x1, y1


def clip_line(line, box):
    """Split a projected polyline at the box (Liang–Barsky per segment)."""
    x0b, y0b, x1b, y1b = box
    out, current = [], []
    for (ax, ay), (bx, by) in zip(line, line[1:]):
        t0, t1, dx, dy = 0.0, 1.0, bx - ax, by - ay
        keep = True
        for p, q in ((-dx, ax - x0b), (dx, x1b - ax), (-dy, ay - y0b), (dy, y1b - ay)):
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
        a = (ax + t0 * dx, ay + t0 * dy)
        b = (ax + t1 * dx, ay + t1 * dy)
        if not current:
            current = [a]
        current.append(b)
        if t1 < 1:
            out.append(current)
            current = []
    if current:
        out.append(current)
    return out


def perimeter_position(point, box):
    """Distance along the box boundary, anticlockwise from the south-west."""
    x0, y0, x1, y1 = box
    x, y = point
    w, h = x1 - x0, y1 - y0
    eps = 1e-6
    if abs(y - y0) < eps:
        return x - x0
    if abs(x - x1) < eps:
        return w + (y - y0)
    if abs(y - y1) < eps:
        return w + h + (x1 - x)
    if abs(x - x0) < eps:
        return 2 * w + h + (y1 - y)
    raise ValueError(f'not on the box: {point}')


def corner_path(s_from, s_to, box):
    """Box corners passed going anticlockwise from s_from to s_to."""
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    total = 2 * (w + h)
    corners = [(w, (x1, y0)), (w + h, (x1, y1)), (2 * w + h, (x0, y1)), (total, (x0, y0))]
    span = (s_to - s_from) % total
    out = []
    for lap in (0, total):
        for s, c in corners:
            d = (s + lap - s_from)
            if 0 < d < span:
                out.append((d, c))
    return [c for _, c in sorted(out)]


def land_polygons(coast_chains, box):
    """Close coastline chains into land rings (land on the left)."""
    closed, open_ = [], []
    for line in coast_chains:
        pts = [p for _, p in line]
        if line[0][0] == line[-1][0]:
            closed.append(pts)
            continue
        for piece in clip_line(pts, box):
            if len(piece) >= 2:
                open_.append(piece)
    # closed rings: islands (anticlockwise, land on the left) or, if they
    # touch nothing, lakes drawn as coastline (clockwise) — keep islands.
    rings = [r for r in closed if area(r) > 0]
    pieces = []
    for piece in open_:
        try:
            s0 = perimeter_position(piece[0], box)
            s1 = perimeter_position(piece[-1], box)
        except ValueError:
            continue  # a chain that ends inside the box: an OSM gap
        pieces.append([piece, s0, s1])
    used = [False] * len(pieces)
    total = 2 * ((box[2] - box[0]) + (box[3] - box[1]))
    for i in range(len(pieces)):
        if used[i]:
            continue
        ring = []
        k = i
        while True:
            used[k] = True
            piece, s0, s1 = pieces[k]
            ring += piece
            # next chain start anticlockwise from this end
            best, best_d = None, None
            for j, (_, t0, _) in enumerate(pieces):
                if used[j] and j != i:
                    continue
                d = (t0 - s1) % total
                if best_d is None or d < best_d:
                    best, best_d = j, d
            if best is None:
                break
            ring += corner_path(s1, pieces[best][1], box)
            if best == i:
                break
            k = best
        rings.append(ring)
    return rings


FILL_REACH_M = 1400


def land_then(land):
    """Land before the 20th-century fills on the peninsula's Marmara shore.

    The Byzantine sea walls stood on the shore, so the land now seaward of
    their line (the coast road of the 1950s, the Yenikapı fill) is cut away:
    land minus a band reaching FILL_REACH_M out to sea from the traced wall
    (studio/atlas/historic/walls.geojson, marmara-sea-walls). Returns the
    indices of the land rings that changed and their rings then.
    """
    from shapely.geometry import LineString, Point, Polygon, box as rect
    walls = json.loads((HISTORIC / 'walls.geojson').read_text(encoding='utf-8'))
    wall = next(f for f in walls['features'] if f['properties']['id'] == 'marmara-sea-walls')
    # From Marmara tower 4: the first point is the Golden Horn's last tower.
    pts = [project(lat, lng) for lng, lat in wall['geometry']['coordinates']][1:]
    line = LineString(pts)
    sea = Point(project(40.998, 28.968))  # off Kumkapı
    band = line.buffer(FILL_REACH_M, single_sided=True)
    if not band.contains(sea):
        band = line.buffer(-FILL_REACH_M, single_sided=True)
    if not band.contains(sea):
        raise SystemExit('land_then: cannot tell the sea side of the wall')
    band = band.intersection(rect(-7000, -3500, 2500, 2500))  # the peninsula only
    changed, out = set(), []
    for i, ring in enumerate(land):
        poly = Polygon(ring)
        if not poly.is_valid:
            poly = poly.buffer(0)
        if not poly.intersects(band):
            continue
        changed.add(i)
        rest = poly.difference(band)
        for g in getattr(rest, 'geoms', [rest]):
            if g.area >= 1:
                out.append([(x, y) for x, y in g.exterior.coords[:-1]])
    return changed, out


# --- reading Overpass ---------------------------------------------------------

PARTIAL = '--partial' in sys.argv  # development only: missing inputs build empty


def load(name):
    path = RAW / f'{name}.json'
    if PARTIAL and not path.exists():
        print(f'warning: {name} not fetched; building it empty', file=sys.stderr)
        return {'elements': []}, b''
    data = path.read_bytes()
    return json.loads(data), data


def way_points(element):
    return [(n, project(g['lat'], g['lon'])) for n, g in zip(element['nodes'], element['geometry'])]


def relation_rings(element, role='outer'):
    ways = []
    for m in element.get('members', []):
        if m.get('type') == 'way' and m.get('role', 'outer') in (role, '') and m.get('geometry'):
            ways.append([((round(g['lat'], 7), round(g['lon'], 7)), project(g['lat'], g['lon']))
                         for g in m['geometry']])
    rings = []
    for ring in chain_undirected(ways):
        pts = [p for _, p in ring]
        if len(pts) >= 4 and ring[0][0] == ring[-1][0]:
            rings.append(pts[:-1])
    return rings


def bbox(rings):
    xs = [x for r in rings for x, _ in r]
    ys = [y for r in rings for _, y in r]
    return min(xs), min(ys), max(xs), max(ys)


class Strings:
    def __init__(self):
        self.items, self.index = [], {}

    def ref(self, s):
        if not s:
            return 0
        if s not in self.index:
            self.index[s] = len(self.items)
            self.items.append(s)
        return self.index[s] + 1


def feature(cls, rings, name=0, closed=False, point=False):
    rings = [r for r in rings if len(r) >= (1 if point else 3 if closed else 2)]
    if not rings:
        return None
    return {'class': cls, 'name': name, 'rings': rings}


def simplify_all(features, tolerance, closed):
    out = []
    for f in features:
        rings = []
        for r in f['rings']:
            if closed:
                ring = quantise(rdp(r + r[:1], tolerance))[:-1] if len(r) > 3 else quantise(r)
                if len(ring) >= 3 and abs(area(ring)) >= 1:
                    rings.append(ring)
            else:
                line = quantise(rdp(r, tolerance))
                if len(line) >= 2:
                    rings.append(line)
        if rings:
            out.append({**f, 'rings': rings})
    return out


# --- layers -------------------------------------------------------------------

def build_layers(strings):
    box = clip_box()
    layers = {}
    inputs = {}

    coast, raw = load('coastline')
    inputs['coastline'] = (coast, raw)
    ways = [way_points(e) for e in coast['elements'] if e['type'] == 'way']
    land = land_polygons(chain(ways), box)
    changed, then = land_then(land)
    # class 1: land whose shore changed since 1900; the Byzantine and Ottoman
    # manners draw its land_then version instead (the coastline morphs).
    layers['land'] = (POLYGONS, [feature(1 if i in changed else 0, [r], closed=True)
                                 for i, r in enumerate(land)])
    layers['land_then'] = (POLYGONS, [feature(1, [r], closed=True) for r in then])

    water, raw = load('water')
    inputs['water'] = (water, raw)
    feats = []
    for e in water['elements']:
        rings = ([[p for _, p in way_points(e)][:-1]] if e['type'] == 'way' and e['nodes'][0] == e['nodes'][-1]
                 else relation_rings(e) if e['type'] == 'relation' else [])
        tags = e.get('tags', {})
        name = strings.ref(tags.get('name'))
        rings = [r for r in rings if abs(area(r)) >= 20_000]
        # class 1: dammed reservoirs and basins (modern); 0 lakes, lagoons
        f = feature(1 if tags.get('water') in ('reservoir', 'basin') else 0, rings, name, closed=True)
        if f:
            feats.append(f)
    layers['water'] = (POLYGONS, feats)

    districts, raw = load('districts')
    inputs['districts'] = (districts, raw)
    seen, lines, labels, province = set(), [], [], []
    for e in districts['elements']:
        if e['type'] != 'relation':
            continue
        tags = e.get('tags', {})
        is_province = tags.get('ISO3166-2') == 'TR-34'
        for m in e.get('members', []):
            if m.get('type') != 'way' or not m.get('geometry'):
                continue
            key = (is_province, m['ref'])
            if key in seen:
                continue
            seen.add(key)
            pts = [project(g['lat'], g['lon']) for g in m['geometry']]
            for piece in clip_line(pts, box):
                (province if is_province else lines).append(piece)
        if not is_province:
            rings = relation_rings(e)
            if rings:
                big = max(rings, key=lambda r: abs(area(r)))
                cx, cy = centroid(big)
                labels.append((tags.get('name', ''), (cx, cy), rings))
    layers['districts'] = (LINES, [feature(0, [l]) for l in lines])
    layers['province'] = (LINES, [feature(0, [l]) for l in province])
    layers['district_labels'] = labels

    roads, raw = load('roads')
    inputs['roads'] = (roads, raw)
    feats = []
    for e in roads['elements']:
        if e['type'] != 'way':
            continue
        tags = e.get('tags', {})
        cls = ROAD_CLASS.get(tags.get('highway', '').replace('_link', ''))
        if cls is None:
            continue
        pts = [p for _, p in way_points(e)]
        for piece in clip_line(pts, box):
            f = feature(cls, [piece])
            if f:
                feats.append(f)
    layers['roads'] = (LINES, feats)

    transit, raw = load('transit')
    inputs['transit'] = (transit, raw)
    rail, ferry = [], []
    for e in transit['elements']:
        if e['type'] != 'way':
            continue
        tags = e.get('tags', {})
        pts = [p for _, p in way_points(e)]
        if tags.get('route') == 'ferry':
            for piece in clip_line(pts, box):
                f = feature(0, [piece])
                if f:
                    ferry.append(f)
            continue
        kind = tags.get('railway')
        if kind not in RAIL_CLASS or tags.get('service') in ('yard', 'siding', 'spur', 'crossover'):
            continue
        if tags.get('usage') in ('industrial', 'military'):
            continue
        cls = RAIL_CLASS[kind]
        # bit 3: below ground (tunnel or a subway without a bridge)
        underground = tags.get('tunnel') in ('yes', 'building_passage') or (
            kind == 'subway' and tags.get('bridge') != 'yes' and tags.get('layer', '-1').lstrip('-').isdigit()
            and int(tags.get('layer', '-1')) < 0)
        if underground:
            cls |= 8
        for piece in clip_line(pts, box):
            f = feature(cls, [piece])
            if f:
                rail.append(f)
    layers['rail'] = (LINES, rail)
    layers['ferry'] = (LINES, ferry)

    stops, raw = load('stops')
    inputs['stops'] = (stops, raw)
    feats = []
    for e in sorted(stops['elements'], key=lambda e: e['id']):
        if e['type'] != 'node':
            continue
        tags = e.get('tags', {})
        kind = 'ferry_terminal' if tags.get('amenity') == 'ferry_terminal' else tags.get('railway')
        cls = STOP_CLASS.get(kind)
        if cls is None:
            continue
        if kind in ('station', 'halt') and tags.get('station') in ('subway',):
            cls = 0
        p = project(e['lat'], e['lon'])
        feats.append(feature(cls, [[p]], strings.ref(tags.get('name')), point=True))
    layers['stops'] = (POINTS, [f for f in feats if f])

    parks, raw = load('parks')
    inputs['parks'] = (parks, raw)
    feats = []
    for e in parks['elements']:
        if e['type'] == 'way' and e['nodes'][0] == e['nodes'][-1]:
            rings = [[p for _, p in way_points(e)][:-1]]
        elif e['type'] == 'relation':
            rings = relation_rings(e)
        else:
            continue
        rings = [r for r in rings if abs(area(r)) >= MIN_PARK_M2]
        f = feature(0, rings, closed=True)
        if f:
            feats.append(f)
    layers['parks'] = (POLYGONS, feats)

    elements, seen_ids = [], set()
    for name in [n for n in QUERIES if n.startswith('buildings-')]:
        data, raw = load(name)
        inputs[name] = (data, raw)
        for e in data['elements']:  # the quarters overlap on their edges
            if (e['type'], e['id']) not in seen_ids:
                seen_ids.add((e['type'], e['id']))
                elements.append(e)
    feats = []
    for e in elements:
        tags = e.get('tags', {})
        if e['type'] == 'way' and e['nodes'][0] == e['nodes'][-1]:
            rings = [[p for _, p in way_points(e)][:-1]]
        elif e['type'] == 'relation':
            rings = relation_rings(e)
        else:
            continue
        rings = [r for r in rings if abs(area(r)) >= MIN_BUILDING_M2]
        # class 1: mosques and churches, drawn darker; 0 others
        religious = tags.get('building') in ('mosque', 'church', 'cathedral', 'chapel') or tags.get('amenity') == 'place_of_worship'
        f = feature(1 if religious else 0, rings, closed=True)
        if f:
            feats.append(f)
    layers['buildings'] = (POLYGONS, feats)
    return layers, inputs


def centroid(ring):
    a = cx = cy = 0.0
    for (x0, y0), (x1, y1) in zip(ring, ring[1:] + ring[:1]):
        c = x0 * y1 - x1 * y0
        a += c
        cx += (x0 + x1) * c
        cy += (y0 + y1) * c
    if abs(a) < 1e-9:
        xs, ys = zip(*ring)
        return sum(xs) / len(xs), sum(ys) / len(ys)
    return cx / (3 * a), cy / (3 * a)


# --- encoding -----------------------------------------------------------------

def uvar(n, out):
    if n < 0:
        raise ValueError(n)
    while True:
        b = n & 0x7F
        n >>= 7
        if n:
            out.append(b | 0x80)
        else:
            out.append(b)
            return


def zvar(n, out):
    uvar((n << 1) ^ (n >> 63) if n < 0 else n << 1, out)


def encode_layer(layer_id, lod, geometry, features, out):
    out += bytes([layer_id, lod, geometry])
    # deterministic order: by bbox, then class
    keyed = []
    for f in features:
        x0, y0, x1, y1 = bbox(f['rings'])
        keyed.append(((y0, x0, y1, x1, f['class'], f['name'], len(f['rings'])), f, (x0, y0, x1, y1)))
    keyed.sort(key=lambda k: k[0])
    uvar(len(keyed), out)
    for _, f, (x0, y0, x1, y1) in keyed:
        out.append(f['class'])
        uvar(f['name'], out)
        for v in (x0, y0, x1, y1):
            zvar(int(v), out)
        uvar(len(f['rings']), out)
        for ring in f['rings']:
            uvar(len(ring), out)
            px, py = int(x0), int(y0)
            for x, y in ring:
                zvar(x - px, out)
                zvar(y - py, out)
                px, py = x, y


def build():
    strings = Strings()
    layers, inputs = build_layers(strings)
    labels = layers.pop('district_labels')
    district_points = [feature(0, [[(int(round(x)), int(round(y)))]], strings.ref(name), point=True)
                       for name, (x, y), _ in sorted(labels)]
    body = bytearray()
    encoded = []
    counts = {}
    for name in ['land', 'land_then', 'water', 'parks', 'districts', 'province', 'roads', 'rail',
                 'ferry', 'buildings']:
        geometry, feats = layers[name]
        feats = [f for f in feats if f]  # feature() drops degenerate rings
        closed = geometry == POLYGONS
        fine_t, coarse_t = TOLERANCE[name]
        fine = simplify_all(feats, fine_t, closed)
        encoded.append((LAYER[name], FINE, geometry, fine))
        counts[name] = {'features': len(fine), 'points': sum(len(r) for f in fine for r in f['rings'])}
        if coarse_t is not None:
            coarse = simplify_all(feats, coarse_t, closed)
            encoded.append((LAYER[name], COARSE, geometry, coarse))
            counts[name]['coarsePoints'] = sum(len(r) for f in coarse for r in f['rings'])
    stops = [{**f, 'rings': [quantise(r) for r in f['rings']]} for f in layers['stops'][1]]
    encoded.append((LAYER['stops'], FINE, POINTS, stops))
    counts['stops'] = {'features': len(stops)}
    encoded.append((11, FINE, POINTS, district_points))  # district labels
    counts['districtLabels'] = {'features': len(district_points)}

    out = bytearray(b'MLAT')
    out.append(VERSION)
    uvar(len(strings.items), out)
    for s in strings.items:
        b = s.encode('utf-8')
        uvar(len(b), out)
        out += b
    uvar(len(encoded), out)
    for layer_id, lod, geometry, feats in encoded:
        encode_layer(layer_id, lod, geometry, feats, out)
    if len(out) > BUDGET_BYTES:
        raise SystemExit(f'atlas.bin is {len(out):,} bytes, over the {BUDGET_BYTES:,} budget')
    OUT_BIN.parent.mkdir(parents=True, exist_ok=True)
    OUT_BIN.write_bytes(bytes(out))

    historic = build_historic()
    evidence = {
        'endpoint': ENDPOINT,
        'licence': 'ODbL 1.0, © OpenStreetMap contributors',
        'projection': 'metres east/north of the Milion (41.008043, 28.978066), equirectangular',
        'clip': CLIP,
        'queries': {name: {'query': QUERIES[name],
                           'osmBase': data.get('osm3s', {}).get('timestamp_osm_base'),
                           'rawSha256': hashlib.sha256(raw).hexdigest(),
                           'elements': len(data.get('elements', []))}
                    for name, (data, raw) in sorted(inputs.items())},
        'tolerancesMetres': TOLERANCE,
        'counts': counts,
        'strings': len(strings.items),
        'partial': PARTIAL,
        'atlasBinBytes': len(out),
        'atlasBinSha256': hashlib.sha256(out).hexdigest(),
        'historic': historic,
    }
    EVIDENCE.parent.mkdir(parents=True, exist_ok=True)
    EVIDENCE.write_text(json.dumps(evidence, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    print(json.dumps({'atlasBinBytes': len(out), **{k: v for k, v in counts.items()}}, ensure_ascii=False))


# --- historic -----------------------------------------------------------------

HISTORIC_FILES = ['walls', 'coast', 'streets', 'hills', 'siege1453', 'below']
KEYS = {'id', 'layer', 'kind', 'names', 'from', 'to', 'certainty', 'sources', 'note'}


def build_historic():
    """Copies the hand-authored layers into one compact asset, checked."""
    if not HISTORIC.exists():
        return None
    features, ids = [], set()
    for name in HISTORIC_FILES:
        path = HISTORIC / f'{name}.geojson'
        if not path.exists():
            continue
        data = json.loads(path.read_text(encoding='utf-8'))
        for f in data['features']:
            p = f['properties']
            missing = KEYS - set(p)
            if missing:
                raise SystemExit(f'{name}: {p.get("id")}: missing {sorted(missing)}')
            if p['id'] in ids:
                raise SystemExit(f'duplicate historic id {p["id"]}')
            ids.add(p['id'])
            g = f['geometry']
            features.append({
                'id': p['id'], 'layer': p['layer'], 'kind': p['kind'],
                'names': p['names'], 'from': p['from'], 'to': p['to'],
                'certainty': p['certainty'], 'sources': p['sources'], 'note': p['note'],
                'type': g['type'], 'coordinates': round_coords(g['coordinates']),
            })
    features.sort(key=lambda f: (HISTORIC_FILES.index(f['layer']), f['id']))
    doc = {'schemaVersion': 1, 'kind': 'atlas-historic', 'features': features}
    text = json.dumps(doc, ensure_ascii=False, separators=(',', ':')) + '\n'
    OUT_HISTORIC.write_text(text, encoding='utf-8')
    # The historic layers' sources and the place-year overrides' sources.
    records = []
    sources = HISTORIC / 'sources.json'
    if sources.exists():
        records += json.loads(sources.read_text(encoding='utf-8'))['records']
    overrides = ROOT / 'studio/atlas/place_years_overrides.json'
    if overrides.exists():
        records += json.loads(overrides.read_text(encoding='utf-8'))['sources']
    ids = [r['id'] for r in records]
    if len(ids) != len(set(ids)):
        raise SystemExit('duplicate atlas source ids')
    records.sort(key=lambda r: r['id'])
    OUT_SOURCES.write_text(json.dumps({'schemaVersion': 1, 'kind': 'sources', 'records': records},
                                      ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return {'features': len(features), 'bytes': len(text.encode('utf-8')),
            'sha256': hashlib.sha256(text.encode('utf-8')).hexdigest()}


def round_coords(c):
    if isinstance(c, (int, float)):
        return round(float(c), 6)
    return [round_coords(x) for x in c]


if __name__ == '__main__':
    build()
