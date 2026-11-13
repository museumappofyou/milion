"""Usage: python3.11 tool/content/rebuild.py — regenerate P02–P11 authored content.

Run the seed, register, daily-detail and dig builders in dependency order, then
the P07 plate pipeline for every studio/plates/*/plate.yaml (without previews;
`tool/plate/build.py <yaml>` renders those). The plate step must follow the
register, because each plate owns its Milestone's path, status and honesty.
The P08 study "How a dome stands" follows (model, manifest and its sources),
then the P09 kit's buildings from studio/space/*.yaml (models, manifests,
their sources and the study index), then the P10 Atlas: place years from the
kept Wikidata response, the historic layers from tool/atlas/historic_spec.py,
and atlas.bin from the pinned OSM responses (fetched into the gitignored
studio/cache/atlas/raw/ by tool/atlas/fetch_osm.py; skipped with a note when
they are absent, since they are tens of MB).
The migrated Chora catalogue and source photographs are kept untouched.
Validate afterwards with `dart run tool/content/validate.dart`.
"""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]


def main():
    for name in ['build_seed.py', 'build_register.py', 'build_details.py', 'build_dig.py']:
        subprocess.run([sys.executable, str(ROOT / 'tool/content' / name)],
                       cwd=ROOT, check=True)
    subprocess.run([sys.executable, str(ROOT / 'tool/plate/build.py'), '--all', '--no-preview'],
                   cwd=ROOT, check=True)
    subprocess.run([sys.executable, str(ROOT / 'tool/space/how_a_dome_stands.py')],
                   cwd=ROOT, check=True)
    subprocess.run([sys.executable, str(ROOT / 'tool/space/build_kit.py')],
                   cwd=ROOT, check=True)
    # P11: Chora's artworks, plan, cycles, hunt, review and Milestone VI (after the kit).
    subprocess.run([sys.executable, str(ROOT / 'tool/content/build_chora.py')], cwd=ROOT, check=True)
    for name in ['place_years.py', 'build_historic.py']:
        subprocess.run([sys.executable, str(ROOT / 'tool/atlas' / name)], cwd=ROOT, check=True)
    if (ROOT / 'studio/cache/atlas/raw/coastline.json').exists():
        subprocess.run([sys.executable, str(ROOT / 'tool/atlas/build_atlas.py')],
                       cwd=ROOT, check=True)
    else:
        print('atlas.bin not rebuilt: fetch the OSM inputs with tool/atlas/fetch_osm.py')


if __name__ == '__main__':
    main()
