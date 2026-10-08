"""Usage: python3 -m unittest tool.content.test_build_seed — rebuild regressions."""
import copy
import unittest

from tool.content.build_seed import merge_seed_index


class SeedIndexTest(unittest.TestCase):
    def test_later_phase_content_survives_reseeding(self):
        existing = dict(schemaVersion=1, files={
            'milestones': ['assets/content/milestones/chora.json',
                           'assets/content/milestones/register.json'],
            'details': ['assets/content/details/chora.json'],
            'sources': ['assets/content/sources.json',
                        'assets/content/sources/register.json',
                        'assets/content/sources/details.json',
                        'assets/content/sources/dig.json'],
        })
        before = copy.deepcopy(existing)
        rebuilt = merge_seed_index(existing)
        for kind in ['milestones', 'details', 'sources']:
            self.assertEqual(rebuilt['files'][kind], existing['files'][kind])
        self.assertEqual(existing, before, 'the input index must not be mutated')
        self.assertEqual(merge_seed_index(rebuilt), rebuilt)

    def test_a_new_registry_still_gets_the_base_documents(self):
        rebuilt = merge_seed_index({})
        self.assertEqual(rebuilt['schemaVersion'], 1)
        self.assertEqual(len(rebuilt['files']), 7)
        self.assertEqual(rebuilt['files']['places'], ['assets/content/places/istanbul.json'])

    def test_an_unknown_schema_is_never_overwritten(self):
        with self.assertRaises(ValueError):
            merge_seed_index(dict(schemaVersion=99, files={}))


if __name__ == '__main__':
    unittest.main()
