"""Content-addressed cache for model outputs (studio/cache is git-ignored)."""
import hashlib
import json

import numpy as np

from .spec import ROOT

CACHE = ROOT / 'studio/cache/plates'


def key(*parts):
    return hashlib.sha256(json.dumps(parts, sort_keys=True, default=str).encode()).hexdigest()[:24]


def cached(name, k, compute):
    """compute() -> (array, meta); meta (e.g. runtime) is kept beside it."""
    path = CACHE / f'{name}-{k}.npy'
    meta = path.with_suffix('.json')
    if path.exists():
        return np.load(path), (json.loads(meta.read_text()) if meta.exists() else {})
    value, info = compute()
    path.parent.mkdir(parents=True, exist_ok=True)
    np.save(path, value)
    meta.write_text(json.dumps(info))
    return value, info
