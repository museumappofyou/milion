import 'dart:convert';
import 'dart:io';

/// The valid fixture plus one complete artwork, a two-room guide and a hunt
/// with items: the P11 additions in isolation.
Map<String, dynamic> p11Fixture() {
  final data = jsonDecode(
    File('test/fixtures/content/valid.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final art = (data['artworks'] as List).single as Map<String, dynamic>;
  Map<String, String> both(String en, String tr) => {'en': en, 'tr': tr};
  art
    ..['surface'] = both('apse', 'apsis')
    ..['position'] = both('East apse.', 'Doğu apsisi.')
    ..['summary'] = both('Christ pulls Adam up.', 'İsa Âdem’i yukarı çeker.')
    ..['cues'] = [both('gates', 'kapılar')]
    ..['lookFor'] = [
      both('The broken gates.', 'Kırık kapılar.'),
      both('Adam’s wrist.', 'Âdem’in bileği.'),
      both('Eve’s wrist.', 'Havva’nın bileği.'),
    ]
    ..['story'] = both('Christ descends.', 'İsa iner.')
    ..['inscriptions'] = [
      {
        'greek': 'Η ΑΝΑϹΤΑϹΙϹ',
        'transliteration': 'Hē anastasis',
        'translation': both('The Resurrection', 'Diriliş'),
        'basis': 'photograph',
        'sources': [(art['sources'] as List).first],
      },
    ]
    ..['condition'] = both('Well preserved.', 'İyi korunmuş.');
  final source = (art['sources'] as List).first as String;
  data['guides'] = [
    {
      'id': 'chora-plan',
      'place': 'chora',
      'axisDeg': 90,
      'rooms': [
        {
          'id': 'parekklesion',
          'name': both('Parekklesion', 'Parekklesion'),
          'outline': [
            [0, 0],
            [10, 0],
            [10, 4],
            [0, 4],
          ],
          'label': [5, 2],
        },
        {
          'id': 'naos',
          'name': both('Naos', 'Naos'),
          'outline': [
            [0, 5],
            [10, 5],
            [10, 15],
            [0, 15],
          ],
          'label': [5, 10],
        },
      ],
      'vaults': [
        {
          'room': 'naos',
          'kind': 'dome',
          'center': [5, 10],
          'radius': 3.5,
          'ribs': 0,
        },
      ],
      'anchors': {
        'F02': {
          'room': 'parekklesion',
          'at': [9, 2],
        },
      },
      'cycles': <Object>[],
      'sources': [source],
    },
  ];
  final hunt = (data['hunts'] as List).single as Map<String, dynamic>;
  hunt['items'] = [
    {
      'id': 'wrists',
      'room': 'Parekklesion',
      'title': both('Wrists', 'Bilekler'),
      'clue': both('Look at the hands.', 'Ellere bakın.'),
      'answer': both('Wrists, not hands.', 'Elleri değil, bilekleri.'),
      'artworks': ['F02'],
      'sources': [source],
    },
  ];
  return data;
}

