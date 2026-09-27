"""One-time catalogue migration: python3 tool/content/migrate_chora.py.

Uses the preserved P01 inputs in test/fixtures/content/legacy_chora.json.
The classifier's output order is intentionally absent from this migration.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
fixture = ROOT / 'test/fixtures/content/legacy_chora.json'
if not fixture.exists():
    fixture.parent.mkdir(parents=True, exist_ok=True)
    fixture.write_text(json.dumps({
        'map': json.loads((ROOT / 'assets/model/class_map.json').read_text()),
        'info': json.loads((ROOT / 'assets/data/scene_info.json').read_text()),
    }, ensure_ascii=False, indent=2) + '\n')
legacy = json.loads(fixture.read_text())


def loc(en, tr=None):
    return dict(en=en, tr=tr)


records = []
for row in sorted(legacy['map'], key=lambda r: r['scene_id']):
    info = legacy['info'][row['scene_id']]
    records.append(dict(
        id=row['scene_id'], place='chora', title=loc(row['title']),
        room=loc(row['room']), surface=loc(row['surface']),
        position=loc(info['position']), kind=info['artwork_type'],
        summary=loc(info['summary']), cues=[loc(c) for c in info['cues']],
        folder=row['scene_folder'], sources=['chora-guide'],
        media=({'F02': ['anastasis-original'], 'F05': ['judgment-original']}.get(row['scene_id'], [])),
    ))
out = ROOT / 'assets/content/artworks/chora.json'
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(dict(schemaVersion=1, kind='artworks', records=records), ensure_ascii=False, indent=2) + '\n')
milestones = []
for numeral, artwork, title, tr, codes, path in [
    ('I', 'F02', 'Anastasis', 'Anastasis', ['DP', 'GL', 'SB', 'WR'], 'anastasis'),
    ('II', 'F05', 'The Last Judgment', 'Son Yargı', ['DP', 'MM', 'GL', 'SB'], 'last_judgment'),
]:
    milestones.append(dict(id='milestone-' + numeral.lower(), numeral=numeral,
        title=loc(title, tr), places=['chora'], artworks=[artwork], techniques=codes,
        honesty=['ORIGINAL', 'DEPTH', 'RECONSTRUCTION', 'IMAGINED'], status='prototype',
        manifestPath=f'assets/{path}/relief_v5/manifest.json', packId='chora-starter', sources=['chora-guide']))
out = ROOT / 'assets/content/milestones/chora.json'
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(dict(schemaVersion=1, kind='milestones', records=milestones), ensure_ascii=False, indent=2) + '\n')
print(f'Migrated {len(records)} artworks; preserved all legacy IDs and English text.')
