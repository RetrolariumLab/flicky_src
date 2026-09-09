import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class RepositoryLayoutTests(unittest.TestCase):
    def test_config_contracts_have_one_semantic_owner(self):
        expected = {
            "authoring/content_studios.json",
            "authoring/data_formats.json",
            "debugger/breakpoints.json",
            "debugger/watches.json",
            "linker/rom_layout.json",
            "reconstruction/source_structure.json",
            "runtime/gens_sound_trace.cfg",
        }
        config = ROOT / "config"

        for relative in expected:
            self.assertTrue((config / relative).is_file(), relative)

        obsolete = {
            "content_studios.json",
            "data_formats.json",
            "debugger_breakpoints.json",
            "debugger_watches.json",
            "gens_sound_trace.cfg",
            "rom_layout.json",
            "source_structure.json",
        }
        self.assertTrue(obsolete.isdisjoint(path.name for path in config.iterdir()))


if __name__ == "__main__":
    unittest.main()
