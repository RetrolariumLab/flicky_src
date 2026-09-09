import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

from validation import debug_symbols  # noqa: E402


class ListingParser(unittest.TestCase):
    def test_a_label_row_yields_its_address(self):
        row = "(1)  177/     3E4 :                     CheckSumError:"
        match = debug_symbols.LISTING_ROW_RE.match(row)
        self.assertIsNotNone(match)
        self.assertEqual(int(match.group(1), 16), 0x3E4)
        self.assertEqual(debug_symbols.DEFINITION_RE.match(match.group(3)).group(1),
                         "CheckSumError")

    def test_an_instruction_row_defines_no_label(self):
        row = "(1)  128/     34C : 6000 0096                           bra.w   CheckSumError"
        match = debug_symbols.LISTING_ROW_RE.match(row)
        self.assertIsNotNone(match)
        self.assertIsNone(debug_symbols.DEFINITION_RE.match(match.group(3)))

    def test_a_top_level_row_without_the_depth_prefix_parses(self):
        row = "     279/     3E4 :                     Something:"
        self.assertIsNotNone(debug_symbols.LISTING_ROW_RE.match(row))

    def test_a_page_header_is_not_a_row(self):
        self.assertIsNone(debug_symbols.LISTING_ROW_RE.match(
            " AS V1.42 Beta [Bld 212] - Source File main.s - Page 1"))


class Equates(unittest.TestCase):
    def test_ram_and_hardware_equates_are_read(self):
        ram = debug_symbols.equates([ROOT / "src" / "memory" / "ram.inc"])
        self.assertEqual(ram["Ram_ObjectSlots"], 0xFFC000)
        self.assertEqual(ram["Ram_PlayerObject"], 0xFFC440)

    def test_the_trampoline_block_resolves_where_it_was_computed(self):
        # Sys_LoadFuncTable writes one jmp every six bytes from $FFFA70, which
        # is why each entry's address is a multiple of six from the first.
        ram = debug_symbols.equates([ROOT / "src" / "memory" / "ram.inc"])
        self.assertEqual(ram["Ram_ExtIntTrampoline"], 0xFFFA70)
        self.assertEqual(ram["j_Nem_Decomp"], 0xFFFA70 + 6 * 3)
        self.assertEqual(ram["j_Sound_LoadZ80Driver"], 0xFFFA70 + 6 * 32)
        self.assertEqual(ram["j_Sound_QueueSFX"], 0xFFFA70 + 6 * 42)

    def test_hardware_ports_are_read(self):
        hardware = debug_symbols.equates([ROOT / "src" / "memory" / "hardware.inc"])
        self.assertEqual(hardware["VDP_DATA"], 0xC00000)
        self.assertEqual(hardware["VDP_CTRL"], 0xC00004)


class Configs(unittest.TestCase):
    def test_every_configured_breakpoint_names_a_defined_label(self):
        entries = debug_symbols.load_config(
            ROOT / "config" / "debugger" / "breakpoints.json", "breakpoints")
        self.assertTrue(entries)
        defined = set()
        for module in sorted((ROOT / "src").rglob("*.s")):
            for line in module.read_text(encoding="utf-8").split("\n"):
                match = debug_symbols.DEFINITION_RE.match(debug_symbols.code_of(line))
                if match:
                    defined.add(match.group(1))
        for entry in entries:
            self.assertIn(entry["symbol"], defined, entry["symbol"])

    def test_every_configured_watch_names_a_defined_address(self):
        entries = debug_symbols.load_config(
            ROOT / "config" / "debugger" / "watches.json", "watches")
        self.assertTrue(entries)
        known = debug_symbols.equates([
            ROOT / "src" / "memory" / "ram.inc",
            ROOT / "src" / "memory" / "hardware.inc",
        ])
        for entry in entries:
            self.assertIn(entry["symbol"], known, entry["symbol"])


if __name__ == "__main__":
    unittest.main()
