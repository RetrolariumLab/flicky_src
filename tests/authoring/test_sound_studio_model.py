import copy
import shutil
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

from authoring import sound_studio_model as model  # noqa: E402
from authoring.sound_studio import SoundStudio  # noqa: E402


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

    def test_preview_lists_have_independent_default_song_and_sfx(self):
        studio = SoundStudio.__new__(SoundStudio)
        studio.document = self.document
        studio._index()
        self.assertEqual(studio.music_header_ids[0], "zMusic81Header")
        self.assertEqual(studio.sfx_header_ids[0], "zSFX90Header")
        self.assertTrue(all(studio.headers[item]["kind"] == "music"
                            for item in studio.music_header_ids))
        self.assertTrue(all(studio.headers[item]["kind"] == "sfx"
                            for item in studio.sfx_header_ids))

    def test_exported_document_is_valid(self):
        model.validate_document(self.document, self.baseline)

    def test_event_decoder_names_coordination_commands(self):
        events = model.describe_sequence([0xEF, 0, 0xC0, 6, 0xF2])
        self.assertEqual([event["name"] for event in events], ["set_voice", "note_3F", "duration", "stop_track"])

    def test_semantic_fm_voices_round_trip_without_losing_reserved_bits(self):
        for bank in self.document["voice_banks"]:
            for voice in bank["voices"]:
                parameters = model.decode_fm_voice(voice)
                self.assertEqual(model.encode_fm_voice(parameters, voice), voice)

    def test_semantic_fm_voice_edit_updates_expected_fields(self):
        voice = list(self.document["voice_banks"][0]["voices"][0])
        parameters = model.decode_fm_voice(voice)
        parameters["algorithm"] = 7
        parameters["feedback"] = 6
        parameters["operators"][2]["attack"] = 19
        parameters["operators"][2]["total_level"] = 42
        edited = model.encode_fm_voice(parameters, voice)
        decoded = model.decode_fm_voice(edited)
        self.assertEqual(decoded["algorithm"], 7)
        self.assertEqual(decoded["feedback"], 6)
        self.assertEqual(decoded["operators"][2]["attack"], 19)
        self.assertEqual(decoded["operators"][2]["total_level"], 42)

    def test_piano_roll_preserves_commands_and_tracks_inherited_duration(self):
        data = [0xEF, 2, 0xC0, 6, 0xC2, 0x80, 3, 0xF2]
        notes = model.piano_roll_notes(data)
        self.assertEqual([note["note"] for note in notes], [0x3F, 0x41, None])
        self.assertEqual([note["duration"] for note in notes], [6, 6, 3])
        self.assertEqual([note["duration_offset"] for note in notes], [3, 3, 6])
        self.assertTrue(notes[1]["duration_is_shared"])

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
