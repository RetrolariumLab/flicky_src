import copy
import json
import shutil
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

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
        self.assertEqual(self.document["schema_version"], 2)
        model.validate_document(self.document, ROOT)

    def test_genesis_sprite_size_bits_are_not_transposed(self):
        chick = next(
            item for item in self.document["mappings"]
            if item["id"] == "Throwable_ThrownAnim0Data0"
        )
        self.assertEqual(
            (chick["pieces"][0]["width"], chick["pieces"][0]["height"]),
            (2, 1),
        )
        self.assertEqual(
            model._mapping_bytes(chick),
            bytes.fromhex("00 04 F8 04 64 56 F8 F8"),
        )

    def test_schema_one_dimensions_are_migrated_in_memory(self):
        document = copy.deepcopy(self.document)
        document["schema_version"] = 1
        for mapping in document["mappings"]:
            for piece in mapping["pieces"]:
                piece["width"], piece["height"] = piece["height"], piece["width"]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "sequences.json"
            path.write_text(json.dumps(document), encoding="utf-8")
            loaded = model.load_document(path)
        self.assertEqual(loaded, self.document)
        model.validate_document(loaded, ROOT)

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

    def test_old_object_names_are_migrated_without_losing_sprite_edits(self):
        document = copy.deepcopy(self.document)
        old_prefixes = (
            ("Throwable_Thrown", "Chick_Thrown"),
            ("Chirp_", "Cat_"),
            ("Tiger_", "Lizard_"),
            ("Iggy_", "Snake_"),
            ("BonusSeesaw_Frame", "BonusCat_OuterFrame"),
            ("BonusTiger_Frame", "BonusCat_InnerFrame"),
            ("BonusSeesaw_Anim", "BonusCat_AnimOuter"),
            ("BonusTiger_Anim", "BonusCat_AnimInner"),
            ("WindowGirl_Frame", "ExitDoor_OpenFrame"),
            ("WindowGirl_AnimIdle", "ExitDoor_AnimOpen"),
        )

        def old_name(name):
            for current, previous in old_prefixes:
                if name.startswith(current):
                    return previous + name[len(current):]
            return name

        mapping = next(item for item in document["mappings"] if item["id"] == "Chirp_WalkFrame0")
        mapping["pieces"][0]["x"] += 1
        for item in document["mappings"]:
            item["id"] = old_name(item["id"])
        for item in document["animations"]:
            item["id"] = old_name(item["id"])
            item["frames"] = [old_name(frame) for frame in item["frames"]]
            for previous, current in model.LEGACY_SOURCE_PATHS.items():
                if previous.startswith(("game/actors/", "game/enemies/")) and item["source"] == current:
                    item["source"] = previous
                    break
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "sequences.json"
            path.write_text(json.dumps(document), encoding="utf-8")
            loaded = model.load_document(path)
        self.assertEqual(loaded["mappings"], [
            {**item, "id": model.current_object_name(item["id"])} for item in document["mappings"]
        ])
        model.validate_document(loaded, ROOT)

    def test_old_countdown_names_are_migrated_without_losing_edits(self):
        document = copy.deepcopy(self.document)
        names = {
            "UI_RoundStartCountdownAnim": "UI_CatCountdownAnim",
            "UI_RoundEndCountdownAnim": "UI_CatCountReverseAnim",
            "UI_CountdownFrame3": "UI_CatCountReverseData3",
        }
        for animation in document["animations"]:
            animation["id"] = names.get(animation["id"], animation["id"])
            animation["frames"] = [names.get(frame, frame) for frame in animation["frames"]]
        round_start = next(
            item for item in document["animations"]
            if item["id"] == "UI_CatCountdownAnim"
        )
        round_start["delay"] += 1
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "sequences.json"
            path.write_text(json.dumps(document), encoding="utf-8")
            loaded = model.load_document(path)
        model.validate_document(loaded, ROOT)
        migrated = next(
            item for item in loaded["animations"]
            if item["id"] == "UI_RoundStartCountdownAnim"
        )
        self.assertEqual(migrated["delay"], round_start["delay"])

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
