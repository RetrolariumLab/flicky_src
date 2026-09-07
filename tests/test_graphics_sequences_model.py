import copy
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import graphics_sequences_model as model  # noqa: E402


class GraphicsSequencesDocument(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.document = model.export_document(ROOT)

    def test_inventory_covers_mappings_and_animations(self):
        self.assertEqual(len(self.document["mappings"]), 224)
        self.assertEqual(len(self.document["animations"]), 50)
        self.assertIn("Player_WalkFrame1", {item["id"] for item in self.document["mappings"]})
        self.assertIn("Player_AnimWalk", {item["id"] for item in self.document["animations"]})

    def test_exported_document_is_valid(self):
        model.validate_document(self.document, ROOT)

    def test_legacy_workspace_paths_are_migrated_in_memory(self):
        document = copy.deepcopy(self.document)
        record = next(
            item for item in document["animations"]
            if item["source"] == "game/actors/player.s"
        )
        record["source"] = "game/player.s"
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "sequences.json"
            path.write_text(json.dumps(document), encoding="utf-8")
            loaded = model.load_document(path)
        model.validate_document(loaded, ROOT)

    def test_piece_count_cannot_change(self):
        document = copy.deepcopy(self.document)
        document["mappings"][0]["pieces"].append(copy.deepcopy(document["mappings"][0]["pieces"][0]))
        with self.assertRaisesRegex(ValueError, "piece count differs"):
            model.validate_document(document, ROOT)

    def test_invalid_tile_index_is_rejected(self):
        document = copy.deepcopy(self.document)
        document["mappings"][0]["pieces"][0]["tile"] = 0x800
        with self.assertRaisesRegex(ValueError, "invalid sprite piece"):
            model.validate_document(document, ROOT)

    def test_mapping_and_animation_edits_patch_staged_source(self):
        document = copy.deepcopy(self.document)
        mapping = next(item for item in document["mappings"] if item["id"] == "Player_WalkFrame1")
        mapping["pieces"][0]["x"] += 1
        animation = next(item for item in document["animations"] if item["id"] == "Player_AnimWalk")
        animation["delay"] = 3
        with tempfile.TemporaryDirectory() as directory:
            staged = Path(directory) / "src"
            shutil.copytree(ROOT / "src", staged)
            model.apply_document(document, ROOT, staged)
            table = (staged / "data/tables.s").read_text(encoding="utf-8")
            player = (staged / "game/actors/player.s").read_text(encoding="utf-8")
            self.assertIn("Player_WalkFrame1:\tdc.b", table)
            self.assertIn("Player_AnimWalk:\tdc.b\t2, 3", player)

    def test_zero_edit_does_not_reformat_sources(self):
        with tempfile.TemporaryDirectory() as directory:
            staged = Path(directory) / "src"
            shutil.copytree(ROOT / "src", staged)
            before = {
                relative: (staged / relative).read_bytes()
                for relative in (model.MAPPING_SOURCE,) + model.ANIMATION_SOURCES
            }
            model.apply_document(self.document, ROOT, staged)
            for relative, expected in before.items():
                self.assertEqual((staged / relative).read_bytes(), expected)


if __name__ == "__main__":
    unittest.main()
