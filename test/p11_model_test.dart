import 'package:flutter_test/flutter_test.dart';
import 'package:milion/content/guide.dart';
import 'package:milion/content/models.dart';
import 'package:milion/content/registry.dart';

import 'p11_fixture.dart';

void main() {
  test('a complete artwork counts; one missing piece does not', () {
    final data = p11Fixture();
    var report = validateContent(data);
    expect(report.errors, isEmpty);
    expect(report.completeArtworks, 1);
    final registry = ContentRegistry.fromJson(data);
    final a = registry.artworks.single;
    expect(a.lookFor, hasLength(3));
    expect(a.inscriptions.single.basis, InscriptionBasis.photograph);
    expect(registry.sourcesOf(a), isNotEmpty);

    final art = (data['artworks'] as List).single as Map<String, dynamic>;
    art['condition'] = {'en': 'Well preserved.'};
    report = validateContent(data);
    expect(report.errors, isEmpty);
    expect(report.completeArtworks, 0);
    (art['lookFor'] as List).removeLast();
    expect(
      validateContent(data).errors,
      contains('F02 needs exactly three things to look for'),
    );
  });

  test('inscriptions must be Greek, transliterated and sourced', () {
    final data = p11Fixture();
    final art = (data['artworks'] as List).single as Map<String, dynamic>;
    final ins = (art['inscriptions'] as List).single as Map<String, dynamic>;
    ins['greek'] = 'H ANASTASIS';
    ins['sources'] = ['nowhere'];
    final errors = validateContent(data).errors;
    expect(
      errors,
      contains('F02.inscriptions[0] has Latin letters in the Greek'),
    );
    expect(
      errors,
      contains('F02.inscriptions[0] references unknown sources id: nowhere'),
    );
  });

  test('guide anchors cover every artwork, inside their rooms', () {
    final data = p11Fixture();
    final registry = ContentRegistry.fromJson(data);
    final guide = registry.guideFor('chora')!;
    expect(guide.room('naos')!.contains(const PlanPoint(5, 10)), isTrue);
    expect(guide.room('naos')!.contains(const PlanPoint(5, 2)), isFalse);
    expect(guide.bounds.width, 10);

    final g = (data['guides'] as List).single as Map<String, dynamic>;
    ((g['anchors'] as Map)['F02'] as Map)['at'] = [5, 10];
    expect(
      validateContent(data).errors,
      contains('chora-plan anchor F02 lies outside parekklesion'),
    );
    (g['anchors'] as Map).clear();
    expect(
      validateContent(data).errors,
      contains('chora-plan has no plan anchor for F02'),
    );
  });

  test('cycles list real artworks; hunt items are sourced', () {
    final data = p11Fixture();
    final g = (data['guides'] as List).single as Map<String, dynamic>;
    g['cycles'] = [
      {
        'id': 'one',
        'title': {'en': 'One', 'tr': 'Bir'},
        'intro': {'en': 'One.', 'tr': 'Bir.'},
        'artworks': ['F02', 'X99'],
        'sources': g['sources'],
      },
    ];
    final hunt = (data['hunts'] as List).single as Map<String, dynamic>;
    ((hunt['items'] as List).single as Map)['sources'] = <String>[];
    final errors = validateContent(data).errors;
    expect(errors, contains('chora-plan.one lists unknown artwork X99'));
    expect(
      errors.where((e) => e.contains('.wrists requires sources')),
      isNotEmpty,
    );
  });

  test('documents written before P11 still load: guides are optional', () {
    final data = p11Fixture()..remove('guides');
    expect(validateContent(data).errors, isEmpty);
    expect(ContentRegistry.fromJson(data).guides, isEmpty);
  });
}
