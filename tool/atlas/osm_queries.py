"""Pinned Overpass queries for the Atlas (P10), fetched by build_atlas.py --fetch.

Each query is kept here verbatim; its response's osm_base timestamp and
SHA-256 are written to studio/atlas/atlas_source.json, so a build can be
traced to the exact OSM state it used. Raw responses are large (the Fatih
buildings alone are tens of MB), so they live in the gitignored
studio/cache/atlas/raw/; the built assets are committed.
Data © OpenStreetMap contributors, ODbL 1.0.
"""

ENDPOINT = 'https://overpass-api.de/api/interpreter'
# Tried in order when the main instance times out; the one used is recorded.
ENDPOINTS = [ENDPOINT, 'https://overpass.kumi.systems/api/interpreter']
USER_AGENT = 'milion-build/1.0 (private development)'

# Istanbul province by its ISO code, so the query does not depend on a name.
PROVINCE = 'area["ISO3166-2"="TR-34"]->.p;'
# Wider than build_atlas.CLIP on every side, so every coastline chain runs
# out of the clip box instead of ending inside it.
PROVINCE_BBOX = '(40.68,27.88,41.74,30.05)'
# The historic core and its facing shores, for streets below primary.
CORE_BBOX = '(40.975,28.90,41.095,29.10)'
# The walled city in four quarters (south, west, north, east), for buildings.
PENINSULA_QUARTERS = ['(40.985,28.905,41.015,28.9475)', '(41.015,28.905,41.045,28.9475)',
                      '(40.985,28.9475,41.015,28.990)', '(41.015,28.9475,41.045,28.990)']
# The walled city and Galata, for the surviving walls (historic layers).
WALLS_BBOX = '(40.985,28.905,41.045,28.995)'

QUERIES = {
    'coastline': '[out:json][timeout:240];way["natural"="coastline"]%s;out geom;' % PROVINCE_BBOX,
    'water': '[out:json][timeout:240];' + PROVINCE +
    '(way["natural"="water"]["water"~"^(lake|reservoir|lagoon|basin)$"](area.p);'
    'relation["natural"="water"]["water"~"^(lake|reservoir|lagoon)$"](area.p););out geom;',
    'districts': '[out:json][timeout:240];' + PROVINCE +
    '(relation["boundary"="administrative"]["admin_level"="6"](area.p);'
    'relation["boundary"="administrative"]["ISO3166-2"="TR-34"];);out geom;',
    'roads': '[out:json][timeout:240];' + PROVINCE +
    '(way["highway"~"^(motorway|trunk|primary)$"](area.p);'
    'way["highway"~"^(secondary|tertiary)$"]%s;);out geom;' % CORE_BBOX,
    'transit': '[out:json][timeout:240];' + PROVINCE +
    '(way["railway"~"^(rail|light_rail|subway|tram|monorail|funicular|narrow_gauge)$"](area.p);'
    'way["route"="ferry"](area.p););out geom;',
    'stops': '[out:json][timeout:240];' + PROVINCE +
    '(node["railway"~"^(station|halt|tram_stop)$"](area.p);'
    'node["amenity"="ferry_terminal"](area.p););out;',
    'parks': '[out:json][timeout:240];' + PROVINCE +
    '(way["leisure"="park"](area.p);relation["leisure"="park"](area.p););out geom;',
    # Building footprints of the walled city (the historic peninsula), in four
    # quarters: one query for all of it times out at the public gateway.
    **{f'buildings-{i}': '[out:json][timeout:300];'
       '(way["building"]%s;relation["building"]%s;);out geom;' % (b, b)
       for i, b in enumerate(PENINSULA_QUARTERS, 1)},
    # Surviving wall lines as surveyed in OSM; tool/atlas/historic_from_osm.py
    # turns them into the historic walls layer with their dates and sources.
    'walls': '[out:json][timeout:180];'
    '(way["historic"="citywalls"]%s;way["barrier"="city_wall"]%s;'
    'way["historic"="city_gate"]%s;node["historic"="city_gate"]%s;'
    'node["barrier"="city_gate"]%s;);out geom;' % ((WALLS_BBOX,) * 5),
}
