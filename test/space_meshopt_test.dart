import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:milion/space/meshopt.dart';

/// Vectors written by meshoptimizer's own encoder (npm meshoptimizer 1.2.0)
/// and decoded by its reference decoder; see the fixture's `generator`.
List<Map<String, dynamic>> referenceCases() =>
    ((jsonDecode(
              File('test/fixtures/space/meshopt_reference.json')
                  .readAsStringSync(),
            ) as Map<String, dynamic>)['cases']
            as List)
        .cast<Map<String, dynamic>>();

Uint8List bytes(Object? b64) => base64Decode(b64! as String);

void main() {
  test('decodes meshoptimizer vertex streams byte for byte', () {
    final cases = referenceCases().where((c) => c['mode'] == 'ATTRIBUTES');
    expect(cases, hasLength(2));
    for (final c in cases) {
      final out = Meshopt.decodeVertexBuffer(
        bytes(c['encoded']),
        c['count'] as int,
        c['stride'] as int,
      );
      if (c['filter'] == 'EXPONENTIAL') Meshopt.exponential(out);
      expect(out, bytes(c['expected']), reason: c['name'] as String);
    }
  });

  test('decodes meshoptimizer triangle streams in the same order', () {
    final cases = referenceCases().where((c) => c['mode'] == 'TRIANGLES');
    expect(cases, hasLength(2));
    for (final c in cases) {
      final stride = c['stride'] as int;
      final indices = Meshopt.decodeIndexBuffer(
        bytes(c['encoded']),
        c['count'] as int,
      );
      final expected = ByteData.sublistView(bytes(c['expected']));
      for (var i = 0; i < indices.length; i++) {
        expect(
          indices[i],
          stride == 2
              ? expected.getUint16(i * 2, Endian.little)
              : expected.getUint32(i * 4, Endian.little),
          reason: '${c['name']} index $i',
        );
      }
      // The codec may rotate a triangle but keeps it and its winding.
      final input = ByteData.sublistView(bytes(c['input']));
      int at(int i) => stride == 2
          ? input.getUint16(i * 2, Endian.little)
          : input.getUint32(i * 4, Endian.little);
      for (var t = 0; t < indices.length; t += 3) {
        final want = [at(t), at(t + 1), at(t + 2)];
        final got = indices.sublist(t, t + 3);
        final rotations = [
          for (var r = 0; r < 3; r++)
            [for (var k = 0; k < 3; k++) want[(r + k) % 3]],
        ];
        expect(
          rotations.map((r) => r.join(',')),
          contains(got.join(',')),
          reason: '${c['name']} triangle $t',
        );
      }
    }
  });

  test('malformed streams are refused, not over-read', () {
    final c = referenceCases().first;
    final good = bytes(c['encoded']);
    final count = c['count'] as int, stride = c['stride'] as int;
    expect(
      () => Meshopt.decodeVertexBuffer(
        good.sublist(0, good.length - 40),
        count,
        stride,
      ),
      throwsFormatException,
    );
    expect(
      () => Meshopt.decodeVertexBuffer(
        Uint8List.fromList([0xa1, ...good.skip(1)]),
        count,
        stride,
      ),
      throwsFormatException,
    );
    final tri = referenceCases().last;
    final index = bytes(tri['encoded']);
    expect(
      () => Meshopt.decodeIndexBuffer(
        index.sublist(0, index.length - 1),
        tri['count'] as int,
      ),
      throwsFormatException,
    );
    expect(() => Meshopt.decodeIndexBuffer(index, 7), throwsFormatException);
  });
}
