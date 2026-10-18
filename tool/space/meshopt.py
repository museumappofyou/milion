"""EXT_meshopt_compression encoders for Milion spaces.

Writes meshoptimizer's vertex codec version 0 (header 0xa0) and triangle index
codec version 1 (header 0xe1), the two streams `EXT_meshopt_compression`
defines for `ATTRIBUTES` and `TRIANGLES`, plus the EXPONENTIAL filter. The
format follows meshoptimizer's reference decoder
(`meshopt_decoder_reference.js`, meshoptimizer 1.2.0); `lib/space/meshopt.dart`
is the app's decoder. The encoder is plain Python and deterministic: the same
input always gives the same bytes.

Inputs: raw little-endian vertex bytes (count × stride, stride a multiple of 4
and at most 256) and triangle indices. Outputs: the compressed bytes.
"""
import numpy as np

VERTEX_HEADER = 0xa0          # vertex codec, version 0
INDEX_HEADER = 0xe1           # triangle codec, version 1
TAIL = 32                     # the vertex stream ends in at least 32 bytes
GROUP = 16                    # bytes per byte group
# meshoptimizer's table of the 14 commonest (feb, fec) pairs; it travels at
# the end of every index stream, so any table is valid, this one is short.
CODEAUX = bytes([0x00, 0x76, 0x87, 0x56, 0x67, 0x78, 0xa9, 0x86,
                 0x65, 0x89, 0x68, 0x98, 0x01, 0x69, 0x00, 0x00])


def block_size(stride):
    return min((8192 // stride) & ~(GROUP - 1), 256)


def _group(values):
    """Smallest encoding of 16 zigzagged byte deltas: (mode, bytes)."""
    best = (3, bytes(values))                      # 8 bits: verbatim
    if not any(values):
        return 0, b''
    for mode, bits in ((1, 2), (2, 4)):
        sentinel = (1 << bits) - 1
        per = 8 // bits
        packed = bytearray()
        for i in range(0, GROUP, per):
            byte = 0
            for v in values[i:i + per]:
                byte = (byte << bits) | min(v, sentinel)
            packed.append(byte)
        packed += bytes(v for v in values if v >= sentinel)
        if len(packed) < len(best[1]):
            best = (mode, bytes(packed))
    return best


def _bytes(deltas):
    """One byte lane of a block: header (2 bits per group), then groups."""
    groups = len(deltas) // GROUP
    header = bytearray((groups + 3) // 4)
    body = bytearray()
    for g in range(groups):
        mode, data = _group(deltas[g * GROUP:(g + 1) * GROUP])
        header[g // 4] |= mode << ((g % 4) * 2)
        body += data
    return bytes(header) + bytes(body)


def encode_vertex_buffer(data, count, stride):
    if stride % 4 or not 0 < stride <= 256:
        raise ValueError('stride must be a multiple of 4, at most 256')
    v = np.frombuffer(bytes(data), dtype=np.uint8).reshape(count, stride)
    out = bytearray([VERTEX_HEADER])
    first = v[0].copy() if count else np.zeros(stride, np.uint8)
    last = first.astype(np.int16)
    size = block_size(stride)
    for start in range(0, count, size):
        block = v[start:start + size].astype(np.int16)
        previous = np.vstack([last[None], block[:-1]])
        d = ((block - previous) & 0xff).astype(np.uint8).astype(np.int8).astype(np.int16)
        zig = (((d << 1) ^ (d >> 7)) & 0xff).astype(np.uint8)
        aligned = (len(block) + GROUP - 1) & ~(GROUP - 1)
        padded = np.zeros((aligned, stride), np.uint8)
        padded[:len(block)] = zig
        for k in range(stride):
            out += _bytes(padded[:, k].tolist())
        last = block[-1]
    if stride < TAIL:
        out += bytes(TAIL - stride)
    out += first.tobytes()
    return bytes(out)


def _vbyte(out, value):
    while True:
        out.append((value & 127) | (128 if value > 127 else 0))
        value >>= 7
        if not value:
            return


def _index(out, index, last):
    d = index - last
    _vbyte(out, (d << 1) if d >= 0 else ((-d) << 1) - 1)


def encode_index_buffer(indices):
    """Triangle list → codec version 1 bytes (meshoptimizer's encoder logic:
    an edge FIFO, a vertex FIFO, `next` for fresh vertices and delta-coded
    free indices)."""
    idx = [int(i) for i in np.asarray(indices).reshape(-1)]
    if len(idx) % 3:
        raise ValueError('a triangle list')
    edges = [(-1, -1)] * 16
    verts = [-1] * 16
    eo = vo = 0
    nxt = last = 0
    code = bytearray()
    data = bytearray()

    def edge_fifo(a, b, c):
        for i in range(16):
            e0, e1 = edges[(eo - 1 - i) & 15]
            if (e0, e1) == (a, b):
                return i << 2
            if (e0, e1) == (b, c):
                return (i << 2) | 1
            if (e0, e1) == (c, a):
                return (i << 2) | 2
        return -1

    def vertex_fifo(v):
        for i in range(16):
            if verts[(vo - 1 - i) & 15] == v:
                return i
        return -1

    def push_edge(a, b):
        nonlocal eo
        edges[eo] = (a, b)
        eo = (eo + 1) & 15

    def push_vertex(v):
        nonlocal vo
        verts[vo] = v
        vo = (vo + 1) & 15

    order = ((0, 1, 2), (1, 2, 0), (2, 0, 1))
    for t in range(0, len(idx), 3):
        tri = idx[t:t + 3]
        fer = edge_fifo(*tri)
        if fer >= 0 and (fer >> 2) < 15:
            a, b, c = (tri[k] for k in order[fer & 3])
            fe = fer >> 2
            fc = vertex_fifo(c)
            if 1 <= fc < 13:
                fec = fc
            elif c == nxt:
                fec, nxt = 0, nxt + 1
            else:
                fec = 15
                if c + 1 == last:
                    fec, last = 13, c
                elif c == last + 1:
                    fec, last = 14, c
            code.append((fe << 4) | fec)
            if fec == 15:
                _index(data, c, last)
                last = c
            if fec == 0 or fec >= 13:
                push_vertex(c)
            push_edge(c, b)
            push_edge(a, c)
            continue
        rotation = 1 if tri[1] == nxt else 2 if tri[2] == nxt else 0
        a, b, c = (tri[k] for k in order[rotation])
        reset = False
        if (a, b, c) == (0, 1, 2) and nxt > 0:
            reset, nxt = True, 0
            verts = [-1] * 16
        fb, fc = vertex_fifo(b), vertex_fifo(c)
        if a == nxt:
            fea, nxt = 0, nxt + 1
        else:
            fea = 15
        if 0 <= fb < 14:
            feb = fb + 1
        elif b == nxt:
            feb, nxt = 0, nxt + 1
        else:
            feb = 15
        if 0 <= fc < 14:
            fec = fc + 1
        elif c == nxt:
            fec, nxt = 0, nxt + 1
        else:
            fec = 15
        aux = (feb << 4) | fec
        slot = CODEAUX.find(bytes([aux]))
        if fea == 0 and 0 <= slot < 14 and not reset:
            code.append(0xf0 | slot)
        else:
            code.append(0xf0 | 14 | fea)
            data.append(aux)
        for value, fe in ((a, fea), (b, feb), (c, fec)):
            if fe == 15:
                _index(data, value, last)
                last = value
        for value, fe in ((a, fea), (b, feb), (c, fec)):
            if fe in (0, 15):
                push_vertex(value)
        push_edge(b, a)
        push_edge(c, b)
        push_edge(a, c)
    return bytes([INDEX_HEADER]) + bytes(code) + bytes(data) + CODEAUX


def exponential(values, exponent):
    """EXPONENTIAL filter: each float becomes a 24-bit mantissa m and an 8-bit
    exponent e (value = m · 2^e), one shared `exponent` for the whole stream so
    decoding is exact. Values must already lie on the 2^exponent grid."""
    v = np.asarray(values, dtype=np.float64)
    m = np.rint(np.ldexp(v, -exponent)).astype(np.int64)
    if not np.array_equal(np.ldexp(m.astype(np.float64), exponent), v):
        raise ValueError('values are not on the quantisation grid')
    if np.abs(m).max(initial=0) >= 1 << 23:
        raise ValueError('mantissa overflow')
    word = ((exponent & 0xff) << 24) | (m & 0xffffff)
    return word.astype(np.uint32)


def quantise(values, exponent):
    """Round to the 2^exponent grid that `exponential` stores exactly."""
    return np.ldexp(np.rint(np.ldexp(np.asarray(values, dtype=np.float64), -exponent)), exponent)


def optimise(faces):
    """Triangles ordered by their first vertex and vertices renumbered by first
    use, so the index codec meets fresh vertices in order and shared edges in
    its FIFO. Returns (new faces, old index of each new vertex)."""
    F = np.asarray(faces, dtype=np.int64).reshape(-1, 3)
    order = np.argsort(F.min(axis=1), kind='stable')
    F = F[order]
    flat = F.reshape(-1)
    _, first = np.unique(flat, return_index=True)
    used = flat[np.sort(first)]
    remap = np.full(flat.max() + 1 if len(flat) else 0, -1, dtype=np.int64)
    remap[used] = np.arange(len(used))
    return remap[F], used


def _dezig(v):
    return (v >> 1) ^ -(v & 1)


def decode_vertex_buffer(source, count, stride):
    """Version 0 stream → count × stride bytes (for tests and read_glb)."""
    src = bytes(source)
    if src[0] != VERTEX_HEADER:
        raise ValueError('not a version 0 vertex stream')
    last = bytearray(src[len(src) - stride:])
    out = bytearray(count * stride)
    size = block_size(stride)
    pos = 1
    for base in range(0, count, size):
        n = min(count - base, size)
        groups = (n + GROUP - 1) // GROUP
        lanes = []
        for _ in range(stride):
            header, pos = src[pos:pos + (groups + 3) // 4], pos + (groups + 3) // 4
            lane = []
            for g in range(groups):
                mode = (header[g // 4] >> ((g % 4) * 2)) & 3
                if mode == 0:
                    lane += [0] * GROUP
                elif mode == 3:
                    lane += src[pos:pos + GROUP]
                    pos += GROUP
                else:
                    bits = 2 if mode == 1 else 4
                    per, sentinel = 8 // bits, (1 << bits) - 1
                    packed, pos = src[pos:pos + GROUP // per], pos + GROUP // per
                    for m in range(GROUP):
                        v = (packed[m // per] >> (8 - bits - (m % per) * bits)) & sentinel
                        if v == sentinel:
                            v, pos = src[pos], pos + 1
                        lane.append(v)
            lanes.append(lane)
        for i in range(n):
            for k in range(stride):
                last[k] = (last[k] + _dezig(lanes[k][i])) & 0xff
            out[(base + i) * stride:(base + i + 1) * stride] = last
    if len(src) - pos != max(TAIL, stride):
        raise ValueError('vertex stream has trailing bytes')
    return bytes(out)


def decode_index_buffer(source, count):
    """Version 1 triangle stream → indices (triangles may come back rotated,
    with their winding kept)."""
    src = bytes(source)
    if src[0] != INDEX_HEADER or count % 3:
        raise ValueError('not a version 1 triangle stream')
    code, data, table = 1, 1 + count // 3, len(src) - 16
    edges, verts = [0] * 32, [0] * 16
    state = {'eo': 0, 'vo': 0, 'next': 0, 'last': 0, 'data': data}

    def push(fifo, key, v):
        fifo[state[key]] = v
        state[key] = (state[key] + 1) & (len(fifo) - 1)

    def read(fifo, key, n):
        return fifo[(state[key] - 1 - n) & (len(fifo) - 1)]

    def leb():
        n = shift = 0
        while True:
            b = src[state['data']]
            state['data'] += 1
            n |= (b & 127) << shift
            shift += 7
            if b < 128:
                return n

    def fresh():
        state['next'] += 1
        return state['next'] - 1

    def free():
        state['last'] += _dezig(leb())
        return state['last']

    out = []
    for _ in range(count // 3):
        c0 = src[code]
        code += 1
        hi, lo = c0 >> 4, c0 & 15
        if hi < 15:
            a, b = read(edges, 'eo', hi * 2), read(edges, 'eo', hi * 2 + 1)
            if lo == 0:
                c = fresh()
            elif lo < 13:
                c = read(verts, 'vo', lo)
            elif lo < 15:
                state['last'] += -1 if lo == 13 else 1
                c = state['last']
            else:
                c = free()
            if lo == 0 or lo >= 13:
                push(verts, 'vo', c)
            for v in (b, c, c, a):
                push(edges, 'eo', v)
        else:
            if lo < 14:
                e = src[table + lo]
                a = fresh()
            else:
                e = src[state['data']]
                state['data'] += 1
                if e == 0:
                    state['next'] = 0
                a = fresh() if lo == 14 else free()
            z, w = e >> 4, e & 15
            b = fresh() if z == 0 else free() if z == 15 else read(verts, 'vo', z - 1)
            c = fresh() if w == 0 else free() if w == 15 else read(verts, 'vo', w - 1)
            push(verts, 'vo', a)
            if z in (0, 15):
                push(verts, 'vo', b)
            if w in (0, 15):
                push(verts, 'vo', c)
            for v in (a, b, b, c, c, a):
                push(edges, 'eo', v)
        out += [a, b, c]
    if state['data'] != table:
        raise ValueError('index stream has trailing bytes')
    return np.asarray(out, dtype=np.int64)


def unexponential(words):
    w = np.asarray(words, dtype=np.uint32).astype(np.int64)
    e = ((w >> 24) ^ 0x80) - 0x80
    m = ((w & 0xffffff) ^ 0x800000) - 0x800000
    return np.ldexp(m.astype(np.float64), e.astype(np.int32))
