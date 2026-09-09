import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

from validation import verify_layout  # noqa: E402

LAYOUT = json.loads(
    (ROOT / "config" / "linker" / "rom_layout.json").read_text(encoding="utf-8")
)


class Declaration(unittest.TestCase):
    def test_modules_are_contiguous_and_ordered(self):
        # The include order is the ROM layout, so a gap or an overlap between
        # two modules would mean the declaration cannot be describing a build.
        previous_end = None
        for module in LAYOUT["modules"]:
            start = verify_layout.parse_number(module["start"])
            end = verify_layout.parse_number(module["end"])
            self.assertLessEqual(start, end, module["file"])
            if previous_end is not None:
                self.assertEqual(start, previous_end + 1, module["file"])
            previous_end = end

    def test_the_modules_span_the_whole_image(self):
        first = verify_layout.parse_number(LAYOUT["modules"][0]["start"])
        last = verify_layout.parse_number(LAYOUT["modules"][-1]["end"])
        self.assertEqual(first, 0)
        self.assertEqual(last, LAYOUT["rom_image"]["size"] - 1)

    def test_every_declared_module_exists(self):
        for module in LAYOUT["modules"]:
            self.assertTrue((ROOT / module["file"]).is_file(), module["file"])

    def test_shared_definitions_emit_no_bytes(self):
        for entry in LAYOUT["shared_definitions"]:
            self.assertFalse(entry["emits_bytes"], entry["file"])
            self.assertTrue((ROOT / entry["file"]).is_file(), entry["file"])

    def test_landmarks_are_inside_the_image(self):
        for landmark in LAYOUT["rom_image"]["landmarks"]:
            address = verify_layout.parse_number(landmark["address"])
            self.assertLess(address, LAYOUT["rom_image"]["size"], landmark["symbol"])
            self.assertTrue(landmark["role"], landmark["symbol"])

    def test_the_padding_gap_is_not_the_tail_of_the_image(self):
        # RomEndData emits the last byte, so p2bin fills a gap in the middle.
        # A default padding byte of $00 would corrupt it rather than truncate.
        gap = LAYOUT["rom_image"]["gaps"][0]
        end = verify_layout.parse_number(gap["end"])
        self.assertLess(end, LAYOUT["rom_image"]["size"] - 1)
        self.assertEqual(
            verify_layout.parse_number(gap["end"]) - verify_layout.parse_number(gap["start"]) + 1,
            gap["size"],
        )


class Checks(unittest.TestCase):
    def listing(self, rows):
        return "\n".join(f"      {n}/{address:>8X} :                     include \"{path}\""
                         for n, (address, path) in enumerate(rows, 1))

    def test_a_moved_module_is_reported_by_name(self):
        layout = {
            "target": {"entrypoint": "src/main.s"},
            "rom_image": {"size": 0x100, "landmarks": []},
            "shared_definitions": [],
            "modules": [
                {"file": "src/a.s", "start": "0x000000", "end": "0x00007F"},
                {"file": "src/b.s", "start": "0x000080", "end": "0x0000FF"},
            ],
        }
        with_tempfile = Path(__file__).with_name("_layout_listing.tmp")
        with_tempfile.write_text(self.listing([(0, "a.s"), (0x90, "b.s")]),
                                 encoding="latin-1")
        try:
            errors: list[str] = []
            verify_layout.check_modules(layout, with_tempfile, errors)
        finally:
            with_tempfile.unlink()
        self.assertTrue(any("src/b.s starts at 0x000090" in e for e in errors), errors)

    def test_a_count_mismatch_stops_before_comparing(self):
        layout = {
            "target": {"entrypoint": "src/main.s"},
            "rom_image": {"size": 0x100, "landmarks": []},
            "shared_definitions": [],
            "modules": [{"file": "src/a.s", "start": "0x000000", "end": "0x0000FF"}],
        }
        listing = Path(__file__).with_name("_layout_listing2.tmp")
        listing.write_text(self.listing([(0, "a.s"), (0x80, "b.s")]), encoding="latin-1")
        try:
            errors: list[str] = []
            verify_layout.check_modules(layout, listing, errors)
        finally:
            listing.unlink()
        self.assertEqual(len(errors), 1)
        self.assertIn("2 modules", errors[0])

    def test_numbers_parse_as_hex_and_decimal(self):
        self.assertEqual(verify_layout.parse_number("0x1FFFF"), 0x1FFFF)
        self.assertEqual(verify_layout.parse_number("131072"), 131072)


if __name__ == "__main__":
    unittest.main()
