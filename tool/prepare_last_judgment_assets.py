"""Copy the selected user-supplied F05 references and record their provenance.

python3.11 tool/prepare_last_judgment_assets.py [source-folder]
No synthesized imagery, perspective warp, crop or color correction is applied.
The normal relief build uses the bundled copies and needs no external folder.
"""
import hashlib
import json
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DEFAULT = Path('/Users/memre/Desktop/chora-ar/captures/chora-scenes/5-PAREKKLESION/C__F05__The-Last-Judgment__vault__REF-9')
REFERENCES = [
    ('vault_reference.jpg', 'web-ke-02-Mahser.jpg', 'Complete Last Judgment vault'),
    ('deesis_reference.jpg', 'web-ke-04-Isa-Meryem-ve-Yahya.jpg', 'Christ, Mary and John'),
    ('heavens_reference.jpg', 'web-ke-01-Goklerin-Durulmesi.jpg', 'The rolling up of heaven'),
    ('throne_reference.jpg', 'web-ke-05-Tahtin-Hazirlanmasi-Sahnesi.jpg', 'The prepared throne'),
]


def main():
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT
    out = ROOT / 'assets/last_judgment'
    # Check all inputs before replacing any prepared assets.
    for _, name, _ in REFERENCES:
        if not (source / name).is_file():
            raise FileNotFoundError(source / name)
    out.mkdir(parents=True, exist_ok=True)
    records = []
    for target, name, title in REFERENCES:
        with Image.open(source / name) as original:
            image = original.convert('RGB')
            image.save(out / target, quality=96, subsampling=0)
            records.append(dict(file=f'assets/last_judgment/{target}', source=name,
                title=title, credit='Caner Cangül; supplied scene reference',
                sourceSize=list(image.size),
                sha256=hashlib.sha256((source / name).read_bytes()).hexdigest()))
    inventory = []
    for file in sorted(source.iterdir()):
        if file.suffix.lower() in {'.jpg', '.png', '.jpeg'}:
            with Image.open(file) as image:
                inventory.append(dict(source=file.name, size=list(image.size),
                    role='bundled reference' if file.name in {r[1] for r in REFERENCES}
                        else 'visual cross-reference; not registered into the master'))
    (out / 'sources.json').write_text(json.dumps(dict(sourceDirectory=str(source),
        images=records, reviewedInventory=inventory), indent=2))
    print(f'Prepared {len(records)} references; inventoried {len(inventory)} supplied images.')


if __name__ == '__main__':
    main()
