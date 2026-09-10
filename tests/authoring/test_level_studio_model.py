import copy
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

from authoring import level_studio_model as model  # noqa: E402
from authoring.level_studio import LevelStudio  # noqa: E402


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

    def test_editor_markers_are_clipped_to_the_visible_32_by_28_map(self):
        self.assertTrue(LevelStudio.marker_is_visible([31, 27]))
        self.assertFalse(LevelStudio.marker_is_visible([22, 30]))

    def test_level_capacity_is_enforced_from_project_configuration(self):
        document = copy.deepcopy(self.document)
        for layout in document["layouts"]:
            for field in (
                "background_group_3",
                "background_group_4",
                "background_group_5",
            ):
                layout[field] = [[0, 0]] * 255
        with self.assertRaisesRegex(ValueError, "capacity is 21101"):
            model.validate_document(document)

    def test_special_tile_capacity_is_enforced_from_project_configuration(self):
        document = copy.deepcopy(self.document)
        for layout in document["layouts"]:
            for field in ("flag_7", "flag_7_6", "flag_5"):
                layout[field] = [[0, 0]] * 255
        with self.assertRaisesRegex(ValueError, "capacity is 1676"):
            model.validate_document(document)

    def test_editable_capacity_metadata_cannot_raise_either_limit(self):
        for field in ("level_data_bytes", "special_tiles_bytes"):
            with self.subTest(field=field):
                document = copy.deepcopy(self.document)
                document["capacities"][field] = 1_000_000
                with self.assertRaisesRegex(
                    ValueError,
                    "capacities differ from the authoring manifest",
                ):
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
            model.apply_document(self.document, staged, ROOT)
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
