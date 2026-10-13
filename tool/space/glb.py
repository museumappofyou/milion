"""Minimal, deterministic glTF 2.0 binary (.glb) writer for Milion spaces.

Input: parts, each a dict with
  name       node and mesh name (the SpacePlayer's part id)
  positions  float32 [n, 3], metres, Z-up (east, north, up)
  faces      int [m, 3], counter-clockwise seen from outside
  ao         float32 [n] baked ambient occlusion in 0..1 (written as `_AO`)
  extras     dict stored on the node (material, ...)
Output: one .glb whose nodes keep that order. glTF is Y-up, so (x, y, z)
is written as (x, z, -y); `lib/space/model.dart` converts back. No normals are
written: glTF clients then shade flat, which is what the drawing style wants.
The bytes depend only on the input (sorted JSON keys, fixed padding).
"""
from pathlib import Path
import json
import struct

import numpy as np

FLOAT, USHORT, UINT = 5126, 5123, 5125
ARRAY_BUFFER, ELEMENT_ARRAY_BUFFER = 34962, 34963


def to_gltf(positions):
    p = np.asarray(positions, dtype=np.float64)
    return np.stack([p[:, 0], p[:, 2], -p[:, 1]], axis=1).astype(np.float32)


def write_glb(path, parts, extras=None):
    blob = bytearray()
    views, accessors, meshes, nodes = [], [], [], []

    def view(data, target):
        while len(blob) % 4:
            blob.append(0)
        views.append({'buffer': 0, 'byteOffset': len(blob),
                      'byteLength': len(data), 'target': target})
        blob.extend(data)
        return len(views) - 1

    def accessor(array, component, kind, target, bounds=False):
        a = {'bufferView': view(array.tobytes(), target),
             'componentType': component, 'count': int(len(array)), 'type': kind}
        if bounds:
            a['min'] = [float(v) for v in array.min(axis=0)]
            a['max'] = [float(v) for v in array.max(axis=0)]
        accessors.append(a)
        return len(accessors) - 1

    for part in parts:
        positions = to_gltf(part['positions'])
        faces = np.asarray(part['faces'], dtype=np.int64).reshape(-1)
        if faces.size == 0 or faces.min() < 0 or faces.max() >= len(positions):
            raise ValueError(f"{part['name']}: bad indices")
        small = len(positions) <= 0xFFFF
        indices = faces.astype(np.uint16 if small else np.uint32)
        attributes = {'POSITION': accessor(positions, FLOAT, 'VEC3', ARRAY_BUFFER, True)}
        if part.get('ao') is not None:
            ao = np.asarray(part['ao'], dtype=np.float32)
            if ao.shape != (len(positions),):
                raise ValueError(f"{part['name']}: one AO value per vertex")
            attributes['_AO'] = accessor(ao, FLOAT, 'SCALAR', ARRAY_BUFFER)
        meshes.append({'name': part['name'], 'primitives': [{
            'attributes': attributes,
            'indices': accessor(indices, USHORT if small else UINT, 'SCALAR',
                                ELEMENT_ARRAY_BUFFER),
            'mode': 4}]})
        node = {'name': part['name'], 'mesh': len(meshes) - 1}
        if part.get('extras'):
            node['extras'] = part['extras']
        nodes.append(node)

    while len(blob) % 4:
        blob.append(0)
    document = {
        'asset': {'version': '2.0', 'generator': 'milion tool/space'},
        'scene': 0,
        'scenes': [{'nodes': list(range(len(nodes)))}],
        'nodes': nodes, 'meshes': meshes, 'accessors': accessors,
        'bufferViews': views, 'buffers': [{'byteLength': len(blob)}],
    }
    if extras:
        document['extras'] = extras
    text = json.dumps(document, sort_keys=True, separators=(',', ':'),
                      ensure_ascii=False).encode('utf-8')
    text += b' ' * (-len(text) % 4)
    total = 12 + 8 + len(text) + 8 + len(blob)
    out = struct.pack('<4sII', b'glTF', 2, total)
    out += struct.pack('<I4s', len(text), b'JSON') + text
    out += struct.pack('<I4s', len(blob), b'BIN\x00') + bytes(blob)
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_bytes(out)
    return len(out)


def read_glb(path):
    """Parse a .glb written above back into (document, parts) for tests."""
    data = Path(path).read_bytes()
    magic, version, total = struct.unpack_from('<4sII', data, 0)
    if magic != b'glTF' or version != 2 or total != len(data):
        raise ValueError('not a glTF 2.0 binary')
    n, _ = struct.unpack_from('<I4s', data, 12)
    document = json.loads(data[20:20 + n])
    m, _ = struct.unpack_from('<I4s', data, 20 + n)
    blob = data[28 + n:28 + n + m]

    def read(i):
        a = document['accessors'][i]
        v = document['bufferViews'][a['bufferView']]
        dtype = {FLOAT: np.float32, USHORT: np.uint16, UINT: np.uint32}[a['componentType']]
        width = {'SCALAR': 1, 'VEC3': 3}[a['type']]
        out = np.frombuffer(blob, dtype=dtype, count=a['count'] * width,
                            offset=v['byteOffset'])
        return out.reshape(-1, width) if width > 1 else out

    parts = []
    for node in document['nodes']:
        primitive = document['meshes'][node['mesh']]['primitives'][0]
        g = read(primitive['attributes']['POSITION']).astype(np.float64)
        parts.append({
            'name': node['name'],
            'positions': np.stack([g[:, 0], -g[:, 2], g[:, 1]], axis=1),
            'faces': read(primitive['indices']).astype(np.int64).reshape(-1, 3),
            'ao': read(primitive['attributes']['_AO']) if '_AO' in primitive['attributes'] else None,
            'extras': node.get('extras', {}),
        })
    return document, parts
