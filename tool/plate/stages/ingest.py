"""Stage (a) ingest: one master photograph in, a clean runtime master out.

Input: the source file (`source.corpus` under $MILION_CAPTURES or
`source.repo`) and its pinned SHA-256. Output: an sRGB master no larger than
4096 px on its long edge, with EXIF/XMP/IPTC/comments stripped, plus the
decoded RGB array and a provenance record (source and output hashes).

When the source is already a baseline sRGB JPEG within the size limit, only
metadata segments are removed, so the decoded pixels stay bit-identical to
the source (the ORIGINAL label stays true). Otherwise the image is converted
to sRGB / resized once and re-encoded at quality 95; the record says so.
A repo master that is already clean is kept in place (P06's I and II).
"""
import hashlib
import io
from pathlib import Path

import numpy as np
from PIL import Image, ImageCms

MAX_EDGE = 4096
# APP1 (Exif/XMP), APP12–APP14 (Ducky/IPTC/Adobe), COM; keep APP0 (JFIF), APP2 (ICC).
STRIP = {0xE1, 0xEC, 0xED, 0xEE, 0xFE}


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def strip_jpeg(data):
    """Drop metadata segments before the scan; the entropy-coded data is untouched."""
    if data[:2] != b'\xff\xd8':
        raise ValueError('not a JPEG')
    out, i = bytearray(b'\xff\xd8'), 2
    while i < len(data):
        if data[i] != 0xFF:
            raise ValueError('corrupt JPEG marker stream')
        marker = data[i + 1]
        if marker == 0xDA:  # start of scan: the rest is image data
            out += data[i:]
            return bytes(out)
        length = int.from_bytes(data[i + 2:i + 4], 'big')
        if marker not in STRIP:
            out += data[i:i + 2 + length]
        i += 2 + length
    raise ValueError('no scan in JPEG')


def _is_srgb(image):
    icc = image.info.get('icc_profile')
    if not icc:
        return True
    name = ImageCms.getProfileName(ImageCms.ImageCmsProfile(io.BytesIO(icc)))
    return 'srgb' in name.lower()


def ingest(spec):
    src = spec.source_path
    if not src.exists():
        raise SystemExit(f'Missing source {src}; set MILION_CAPTURES')
    data = src.read_bytes()
    if sha256(data) != spec.source['sha256']:
        raise SystemExit(f'{src}: hash differs from the pinned sha256')
    image = Image.open(io.BytesIO(data))
    record = dict(source=str(spec.source.get('corpus') or spec.source['repo']),
                  sourceSha256=sha256(data), sourceSize=list(image.size),
                  sourceUrl=spec.source.get('url'))
    keep = 'repo' in spec.source
    if keep:
        target = Path(spec.source['repo'])
        out = data
        record['method'] = 'kept in place'
    else:
        target = Path(spec.asset('original.jpg'))
        simple = (image.format == 'JPEG' and image.mode == 'RGB' and _is_srgb(image)
                  and max(image.size) <= MAX_EDGE and not image.info.get('progressive'))
        if simple:
            out = strip_jpeg(data)
            record['method'] = 'metadata stripped; pixels bit-identical'
        else:
            rgb = image.convert('RGB')
            icc = image.info.get('icc_profile')
            if icc and not _is_srgb(image):
                rgb = ImageCms.profileToProfile(
                    rgb, ImageCms.ImageCmsProfile(io.BytesIO(icc)),
                    ImageCms.createProfile('sRGB'), outputMode='RGB')
            rgb.thumbnail((MAX_EDGE, MAX_EDGE), Image.Resampling.LANCZOS)
            buf = io.BytesIO()
            rgb.save(buf, 'JPEG', quality=95, subsampling=0, optimize=True)
            out = buf.getvalue()
            record['method'] = 'converted to sRGB / resized; re-encoded q95'
    master = np.asarray(Image.open(io.BytesIO(out)).convert('RGB'))
    if record['method'].startswith('metadata'):
        assert np.array_equal(master, np.asarray(image.convert('RGB'))), 'strip changed pixels'
    exif = Image.open(io.BytesIO(out)).getexif()
    if len(exif) and not keep:
        raise SystemExit(f'{target}: EXIF survived ingest')
    record.update(master=str(target), masterSha256=sha256(out),
                  size=[master.shape[1], master.shape[0]])
    return master, out, record
