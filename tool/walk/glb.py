"""Deterministic glTF 2.0 binary writer for walk prototypes (P14).

Unlike tool/space/glb.py (the drawing-style kit: positions and baked AO only,
z-up, meshopt-compressed), a walk model is read by flutter_scene's runtime
importer, so it is plain glTF: y-up, POSITION, NORMAL, COLOR_0 (the baked
light, linear RGB) and TEXCOORD_0, one node per prototype mesh, no
materials (the app builds its own unlit ones). The bytes depend only on the
input (sorted JSON keys, fixed padding).
"""
import json
import struct

import numpy as np

FLOAT, USHORT, UINT = 5126, 5123, 5125
ARRAY_BUFFER, ELEMENT_ARRAY_BUFFER = 34962, 34963


def write_glb(path, meshes, extras=None):
    """meshes: [(name, Mesh)] in node order."""
    blob = bytearray()
    views, accessors, gl_meshes, nodes = [], [], [], []

    def view(data, target):
        while len(blob) % 4:
            blob.append(0)
        offset = len(blob)
        blob.extend(data)
        views.append(dict(buffer=0, byteOffset=offset, byteLength=len(data), target=target))
        return len(views) - 1

    def accessor(array, component, kind, target, bounds=False):
        index = view(array.tobytes(), target)
        a = dict(bufferView=index, componentType=component, count=int(array.shape[0]), type=kind)
        if bounds:
            a['min'] = [float(v) for v in array.min(axis=0)]
            a['max'] = [float(v) for v in array.max(axis=0)]
        accessors.append(a)
        return len(accessors) - 1

    for name, mesh in meshes:
        pos = np.asarray(mesh.positions, dtype=np.float32).reshape(-1, 3)
        nor = np.asarray(mesh.normals, dtype=np.float32).reshape(-1, 3)
        col = np.asarray(mesh.colours, dtype=np.float32).reshape(-1, 3)
        uv = np.asarray(mesh.uvs, dtype=np.float32).reshape(-1, 2)
        faces = np.asarray(mesh.faces, dtype=np.uint32).reshape(-1)
        index_type = USHORT if pos.shape[0] < 65536 else UINT
        idx = faces.astype(np.uint16 if index_type == USHORT else np.uint32)
        attributes = dict(
            POSITION=accessor(pos, FLOAT, 'VEC3', ARRAY_BUFFER, bounds=True),
            NORMAL=accessor(nor, FLOAT, 'VEC3', ARRAY_BUFFER),
            COLOR_0=accessor(col, FLOAT, 'VEC3', ARRAY_BUFFER),
            TEXCOORD_0=accessor(uv, FLOAT, 'VEC2', ARRAY_BUFFER),
        )
        indices = accessor(idx.reshape(-1, 1), index_type, 'SCALAR', ELEMENT_ARRAY_BUFFER)
        gl_meshes.append(dict(name=name, primitives=[dict(attributes=attributes, indices=indices, mode=4)]))
        nodes.append(dict(name=name, mesh=len(gl_meshes) - 1))

    while len(blob) % 4:
        blob.append(0)
    document = dict(
        asset=dict(version='2.0', generator='milion tool/walk/glb.py'),
        scene=0,
        scenes=[dict(nodes=list(range(len(nodes))))],
        nodes=nodes,
        meshes=gl_meshes,
        accessors=accessors,
        bufferViews=views,
        buffers=[dict(byteLength=len(blob))],
    )
    if extras:
        document['extras'] = extras
    text = json.dumps(document, sort_keys=True, separators=(',', ':')).encode('utf-8')
    while len(text) % 4:
        text += b' '
    total = 12 + 8 + len(text) + 8 + len(blob)
    with open(path, 'wb') as f:
        f.write(struct.pack('<4sII', b'glTF', 2, total))
        f.write(struct.pack('<I4s', len(text), b'JSON'))
        f.write(text)
        f.write(struct.pack('<I4s', len(blob), b'BIN\x00'))
        f.write(bytes(blob))
