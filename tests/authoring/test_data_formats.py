import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

from authoring import data_formats  # noqa: E402
from formats import nemesis_dec, nemesis_enc  # noqa: E402


class PaletteCompact(unittest.TestCase):
    def test_the_sega_palette_round_trips(self):
        data = bytes.fromhex("1eee2ec03ea04e805e606e407e208e009c00aa01")
        entries = data_formats.decode_palette_compact(data)
        self.assertEqual(data_formats.encode_palette_compact(entries), data)

    def test_the_last_entry_is_flagged_by_bit_zero(self):
        entries = data_formats.decode_palette_compact(bytes.fromhex("1eee aa01".replace(" ", "")))
        self.assertFalse(entries[0]["last"])
        self.assertTrue(entries[-1]["last"])

    def test_decoding_stops_at_the_terminator(self):
        data = bytes.fromhex("aa01" "1eee")
        self.assertEqual(len(data_formats.decode_palette_compact(data)), 1)

    def test_the_colour_keeps_only_the_even_bits(self):
        entry = data_formats.decode_palette_compact(bytes.fromhex("1eee"))[0]
        self.assertEqual(entry["colour"], 0xEEE)


class SimpleFormats(unittest.TestCase):
    def test_demo_input_round_trips(self):
        data = bytes([0x00, 0x12, 0x08, 0x01, 0x0A, 0x15])
        pairs = data_formats.decode_demo_input(data)
        self.assertEqual(pairs[0], {"buttons": 0x00, "frames": 0x12})
        self.assertEqual(data_formats.encode_demo_input(pairs), data)

    def test_velocity_pairs_are_signed_and_round_trip(self):
        data = bytes.fromhex("00014000" "fffe0000")
        pairs = data_formats.decode_velocity_pairs(data)
        self.assertEqual(pairs[0]["x"], 0x14000)
        self.assertLess(pairs[0]["y"], 0)
        self.assertEqual(data_formats.encode_velocity_pairs(pairs), data)

    def test_font_1bpp_round_trips(self):
        data = bytes([0b10110001, 0x00, 0xFF])
        rows = data_formats.decode_font_1bpp(data)
        self.assertEqual(rows[0], [1, 0, 1, 1, 0, 0, 0, 1])
        self.assertEqual(data_formats.encode_font_1bpp(rows), data)

    def test_tilemap_words_round_trip(self):
        data = bytes.fromhex("22001234")
        words = data_formats.decode_tilemap_words(data)
        self.assertEqual(words, [0x2200, 0x1234])
        self.assertEqual(data_formats.encode_tilemap_words(words), data)


class NemesisCodec(unittest.TestCase):
    """The Nemesis claim is semantic, and the tests say exactly that."""

    def setUp(self):
        self.segment = ROOT / "data" / "artnem" / "data_ExitTiles.bin"
        if not self.segment.is_file():
            self.skipTest("extracted data not present; run 'make split'")

    def test_re_encoding_decodes_back_to_the_same_pixels(self):
        original = self.segment.read_bytes()
        plain = nemesis_dec.decompress(original)
        again = nemesis_enc.compress(plain, original)
        self.assertEqual(nemesis_dec.decompress(again), plain)

    def test_the_header_is_carried_over_verbatim(self):
        original = self.segment.read_bytes()
        _, _, _, header_size = nemesis_enc.parse_header(original)
        again = nemesis_enc.compress(nemesis_dec.decompress(original), original)
        self.assertEqual(again[:header_size], original[:header_size])


class Manifest(unittest.TestCase):
    def test_every_declared_claim_is_one_the_checker_knows(self):
        manifest = json.loads(
            (ROOT / "config" / "authoring" / "data_formats.json").read_text(
                encoding="utf-8"
            )
        )
        allowed = {"exact", "semantic", "decode_only", "none"}
        for artifact in manifest["artifacts"]:
            self.assertIn(artifact["round_trip"], allowed, artifact["segment"])

    def test_every_exact_claim_names_a_codec_that_can_encode(self):
        manifest = json.loads(
            (ROOT / "config" / "authoring" / "data_formats.json").read_text(
                encoding="utf-8"
            )
        )
        for artifact in manifest["artifacts"]:
            if artifact["round_trip"] == "exact":
                self.assertIn(artifact["codec"], data_formats.CODECS, artifact["segment"])


if __name__ == "__main__":
    unittest.main()
