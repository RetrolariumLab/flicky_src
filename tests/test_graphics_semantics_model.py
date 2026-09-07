import copy
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import graphics_semantics_model as model  # noqa: E402


class GraphicsSemanticsDocument(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.document = model.export_document(ROOT)

    def test_inventory_covers_text_and_game_palettes(self):
        self.assertEqual(len(self.document["texts"]), 52)
        self.assertEqual(len(self.document["palettes"]), 28)
        self.assertIn("Ending_CongratulationsText", {item["id"] for item in self.document["texts"]})
        self.assertIn("Level_Palette11", {item["id"] for item in self.document["palettes"]})

    def test_exported_document_is_valid(self):
        model.validate_document(self.document, ROOT)

    def test_legacy_workspace_paths_are_migrated_in_memory(self):
        document = copy.deepcopy(self.document)
        record = next(item for item in document["texts"] if item["source"] == "game/bonus/mode.s")
        record["source"] = "game/bonus.s"
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "semantics.json"
            path.write_text(json.dumps(document), encoding="utf-8")
            loaded = model.load_document(path)
        model.validate_document(loaded, ROOT)

    def test_text_cannot_exceed_its_original_slot(self):
        document = copy.deepcopy(self.document)
        document["texts"][0]["value"] += "!"
        with self.assertRaisesRegex(ValueError, "printable ASCII within its capacity"):
            model.validate_document(document, ROOT)

    def test_invalid_palette_channel_is_rejected(self):
        document = copy.deepcopy(self.document)
        document["palettes"][0]["colours"][0] = 1
        with self.assertRaisesRegex(ValueError, r"even \$0EEE channels"):
            model.validate_document(document, ROOT)

    def test_edits_are_applied_only_to_staged_sources(self):
        document = copy.deepcopy(self.document)
        text = next(item for item in document["texts"] if item["id"] == "Bonus_BonusText")
        text["value"] = "POINT"
        palette = next(item for item in document["palettes"] if item["id"] == "Title_LogoPalette")
        palette["colours"][2] = 0xEEE
        with tempfile.TemporaryDirectory() as directory:
            staged = Path(directory)
            for relative in set(model.TEXT_SOURCES + model.PALETTE_SOURCES):
                target = staged / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / "src" / relative, target)
            model.apply_document(document, ROOT, staged)
            bonus = (staged / "game/bonus/mode.s").read_text(encoding="utf-8")
            title = (staged / "game/screens/front_end.s").read_text(encoding="utf-8")
            self.assertIn('Bonus_BonusText:    dc.b    "POINT",0', bonus)
            self.assertIn("Title_LogoPalette:      dc.w    0, $EEE, $EEE", title)
        self.assertIn('Bonus_BonusText:    dc.b    "BONUS",0', (ROOT / "src/game/bonus/mode.s").read_text())


if __name__ == "__main__":
    unittest.main()
