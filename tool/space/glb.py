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

`write_glb(..., compress=True)` (the P09 kit) stores every buffer view as an
`EXT_meshopt_compression` stream: positions and AO through the EXPONENTIAL
filter on fixed grids (2^-10 m, 2^-8), so they decode exactly; triangles and
vertices reordered for the index codec, which may also rotate a triangle's
corners (never its winding).
"""
from pathlib import Path
import json
import struct

import numpy as np

import meshopt

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
    return _pack(path, document, blob)


POSITION_EXP, AO_EXP = -10, -8
EXT = 'EXT_meshopt_compression'


def write_compressed(path, parts, extras=None):
    blob = bytearray()
    fallback = 0
    views, accessors, meshes, nodes = [], [], [], []

    def view(encoded, count, stride, mode, target, filt=None):
        nonlocal fallback
        while len(blob) % 4:
            blob.append(0)
        ext = {'buffer': 0, 'byteOffset': len(blob), 'byteLength': len(encoded),
               'byteStride': stride, 'count': count, 'mode': mode}
        if filt:
            ext['filter'] = filt
        blob.extend(encoded)
        v = {'buffer': 1, 'byteOffset': fallback, 'byteLength': count * stride,
             'target': target, 'extensions': {EXT: ext}}
        if mode == 'ATTRIBUTES':
            v['byteStride'] = stride
        fallback += count * stride
        fallback += -fallback % 4
        views.append(v)
        return len(views) - 1

    def accessor(index, component, kind, count, bounds=None):
        a = {'bufferView': index, 'componentType': component, 'count': int(count), 'type': kind}
        if bounds is not None:
            a['min'], a['max'] = ([float(v) for v in b] for b in bounds)
        accessors.append(a)
        return len(accessors) - 1

    for part in parts:
        faces, order = meshopt.optimise(part['faces'])
        positions = meshopt.quantise(np.asarray(part['positions'], np.float64)[order], POSITION_EXP)
        if not np.array_equal(positions, np.asarray(part['positions'], np.float64)[order]):
            raise ValueError(f"{part['name']}: positions are not on the 2^-10 m grid")
        g = to_gltf(positions).astype(np.float64)
        n = len(g)
        words = meshopt.exponential(g.reshape(-1), POSITION_EXP)
        attributes = {'POSITION': accessor(
            view(meshopt.encode_vertex_buffer(words.tobytes(), n, 12), n, 12, 'ATTRIBUTES',
                 ARRAY_BUFFER, 'EXPONENTIAL'),
            FLOAT, 'VEC3', n, (g.min(axis=0), g.max(axis=0)))}
        if part.get('ao') is not None:
            ao = np.asarray(part['ao'], np.float64)
            if ao.shape != (len(part['positions']),):
                raise ValueError(f"{part['name']}: one AO value per vertex")
            ao = meshopt.quantise(np.clip(ao[order], 0, 1), AO_EXP)
            attributes['_AO'] = accessor(
                view(meshopt.encode_vertex_buffer(meshopt.exponential(ao, AO_EXP).tobytes(), n, 4),
                     n, 4, 'ATTRIBUTES', ARRAY_BUFFER, 'EXPONENTIAL'),
                FLOAT, 'SCALAR', n)
        flat = faces.reshape(-1)
        small = n <= 0xFFFF
        meshes.append({'name': part['name'], 'primitives': [{
            'attributes': attributes,
            'indices': accessor(view(meshopt.encode_index_buffer(flat), len(flat), 2 if small else 4,
                                     'TRIANGLES', ELEMENT_ARRAY_BUFFER),
                                USHORT if small else UINT, 'SCALAR', len(flat)),
            'mode': 4}]})
        node = {'name': part['name'], 'mesh': len(meshes) - 1}
        if part.get('extras'):
            node['extras'] = part['extras']
        nodes.append(node)

    while len(blob) % 4:
        blob.append(0)
    document = {
        'asset': {'version': '2.0', 'generator': 'milion tool/space kit'},
        'extensionsUsed': [EXT], 'extensionsRequired': [EXT],
        'scene': 0,
        'scenes': [{'nodes': list(range(len(nodes)))}],
        'nodes': nodes, 'meshes': meshes, 'accessors': accessors,
        'bufferViews': views,
        'buffers': [{'byteLength': len(blob)},
                    {'byteLength': fallback, 'extensions': {EXT: {'fallback': True}}}],
    }
    if extras:
        document['extras'] = extras
    return _pack(path, document, blob)


def _pack(path, document, blob):
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
        ext = v.get('extensions', {}).get(EXT)
        if ext is None:
            out = np.frombuffer(blob, dtype=dtype, count=a['count'] * width,
                                offset=v['byteOffset'])
        else:
            src = blob[ext['byteOffset']:ext['byteOffset'] + ext['byteLength']]
            if ext['mode'] == 'TRIANGLES':
                out = meshopt.decode_index_buffer(src, ext['count']).astype(dtype)
            else:
                raw = meshopt.decode_vertex_buffer(src, ext['count'], ext['byteStride'])
                words = np.frombuffer(raw, dtype=np.uint32)
                out = (meshopt.unexponential(words) if ext.get('filter') == 'EXPONENTIAL'
                       else words.view(np.float32)).astype(np.float32)
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
