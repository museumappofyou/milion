"""Independent oracle: python3 tool/content/geography_references.py.

Requires geographiclib==2.1, used only to generate committed test evidence.
Compares GeographicLib's inverse solver on a sphere to 3D vector geometry.
Neither imports or reimplements the production haversine calculation.
"""
import json
import math
from pathlib import Path
from geographiclib.geodesic import Geodesic

R = 6371008.8
ORIGIN = (41.008043, 28.978066)
TARGETS = [('chora', 41.031111, 28.939167), ('rumeli-hisari', 41.084722222222, 29.056111111111)]


def dot(a, b):
    return sum(x*y for x, y in zip(a, b))


def vector(p):
    lat, lon = map(math.radians, p)
    return (math.cos(lat)*math.cos(lon), math.cos(lat)*math.sin(lon), math.sin(lat))


def reference(target):
    a, b = vector(ORIGIN), vector(target)
    cross = (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
    angle = math.atan2(math.sqrt(dot(cross, cross)), dot(a, b))
    lat, lon = map(math.radians, ORIGIN)
    east = (-math.sin(lon), math.cos(lon), 0)
    north = (-math.sin(lat)*math.cos(lon), -math.sin(lat)*math.sin(lon), math.cos(lat))
    return dict(km=R*angle/1000, bearing=math.degrees(math.atan2(dot(b, east), dot(b, north))) % 360)


records = []
for id, lat, lng in TARGETS:
    inverse = Geodesic(R, 0).Inverse(*ORIGIN, lat, lng)
    geo = dict(km=inverse['s12']/1000, bearing=inverse['azi1'] % 360)
    vec = reference((lat, lng))
    assert abs(geo['km']-vec['km']) < 1e-8
    assert abs(geo['bearing']-vec['bearing']) < 1e-8
    records.append(dict(id=id, lat=lat, lng=lng, geographicLib=geo, vector=vec))
path = Path(__file__).resolve().parents[2] / 'test/fixtures/content/geography.json'
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(dict(method='GeographicLib 2.1 Geodesic(R, 0).Inverse + independent ECEF cross/dot/tangent-plane bearing',
    earthRadiusM=R, origin=ORIGIN, records=records), indent=2)+'\n')
print(path)
