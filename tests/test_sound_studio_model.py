import copy
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import sound_studio_model as model  # noqa: E402


class SoundDocument(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.baseline = ROOT / model.SOURCE
        cls.document = model.export_document(cls.baseline)

    def test_inventory_covers_all_resident_sound_content(self):
        self.assertEqual(len(self.document["headers"]), 14)
        self.assertEqual(len(self.document["sequences"]), 52)
        self.assertEqual(sum(len(bank["voices"]) for bank in self.document["voice_banks"]), 34)
        self.assertEqual(len(self.document["priority_envelopes"]), 63)

    def test_exported_document_is_valid(self):
        model.validate_document(self.document, self.baseline)

    def test_event_decoder_names_coordination_commands(self):
        events = model.describe_sequence([0xEF, 0, 0xC0, 6, 0xF2])
        self.assertEqual([event["name"] for event in events], ["set_voice", "note_3F", "duration", "stop_track"])

    def test_sequence_capacity_cannot_change(self):
        document = copy.deepcopy(self.document)
        document["sequences"][0]["bytes"].append(0xF2)
        with self.assertRaisesRegex(ValueError, "sequence capacity differs"):
            model.validate_document(document, self.baseline)

    def test_edits_round_trip_through_assembly_source(self):
        document = copy.deepcopy(self.document)
        header = next(item for item in document["headers"] if item["id"] == "zMusic81Header")
        header["tracks"][0]["volume"] = 1
        sequence = next(item for item in document["sequences"] if item["id"] == "zSFX90Sequence")
        sequence["bytes"][1] = 1
        bank = next(item for item in document["voice_banks"] if item["id"] == "zSFX90Voices")
        bank["voices"][0][24] ^= 1
        document["priority_envelopes"][0] = 0x70
        with tempfile.TemporaryDirectory() as directory:
            workspace = Path(directory) / "z80_sound_data.asm"
            shutil.copyfile(self.baseline, workspace)
            model.apply_document(document, self.baseline, workspace)
            self.assertEqual(model.export_document(workspace), document)

    def test_zero_edit_does_not_reformat_source(self):
        with tempfile.TemporaryDirectory() as directory:
            workspace = Path(directory) / "z80_sound_data.asm"
            shutil.copyfile(self.baseline, workspace)
            before = workspace.read_bytes()
            model.apply_document(self.document, self.baseline, workspace)
            self.assertEqual(workspace.read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
