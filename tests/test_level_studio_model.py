import copy
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import level_studio_model as model  # noqa: E402


class LevelExport(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.document = model.export_document(ROOT)

    def test_exports_all_unique_layouts_and_round_slots(self):
        self.assertEqual(len(self.document["layouts"]), 36)
        self.assertEqual(len(self.document["round_layouts"]), 48)
        self.assertEqual(len(self.document["round_special_layouts"]), 48)

    def test_unedited_documents_preserve_every_source_byte(self):
        levels, specials = model.validate_document(self.document)
        for layout, encoded in zip(self.document["layouts"], levels):
            self.assertEqual(encoded, layout["baseline_bytes"])
        for layout, encoded in zip(self.document["layouts"], specials):
            self.assertEqual(encoded, layout["baseline_special_bytes"])

    def test_collision_encoder_round_trips_an_edit(self):
        document = copy.deepcopy(self.document)
        grid = document["layouts"][0]["collision"]
        grid[4][4] = 1 - grid[4][4]
        levels, _specials = model.validate_document(document)
        terminator = levels[0].index(0)
        self.assertEqual(model.decode_collision(levels[0][:terminator + 1]), grid)

    def test_object_coordinate_outside_grid_is_rejected(self):
        document = copy.deepcopy(self.document)
        document["layouts"][0]["player"] = [32, 0]
        with self.assertRaisesRegex(ValueError, "player contains an invalid coordinate"):
            model.validate_document(document)

    def test_capacity_is_enforced(self):
        document = copy.deepcopy(self.document)
        document["capacities"]["level_data_bytes"] = 1
        with self.assertRaisesRegex(ValueError, "capacity is 1"):
            model.validate_document(document)

    def test_generated_sections_replace_only_declared_ranges(self):
        with tempfile.TemporaryDirectory() as directory:
            staged = Path(directory)
            (staged / "data").mkdir()
            for name in ("tables.s", "level_layout.s"):
                (staged / "data" / name).write_text(
                    (ROOT / "src" / "data" / name).read_text(encoding="utf-8"),
                    encoding="utf-8",
                )
            model.apply_document(self.document, staged)
            self.assertIn(
                "Level_Data35:",
                (staged / "data" / "tables.s").read_text(encoding="utf-8"),
            )
            self.assertIn(
                "Lizard_JumpArcTable:",
                (staged / "data" / "level_layout.s").read_text(encoding="utf-8"),
            )


if __name__ == "__main__":
    unittest.main()
