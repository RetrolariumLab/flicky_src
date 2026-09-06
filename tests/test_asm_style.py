import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

import asm_style  # noqa: E402


class NormalizeLine(unittest.TestCase):
    def test_instruction_reaches_the_operand_column(self):
        self.assertEqual(
            asm_style.normalize_line("  move.w  #$B000,d2", 0),
            " " * 16 + "move.w  #$B000,d2",
        )

    def test_short_mnemonic_is_padded_to_column_eight(self):
        self.assertEqual(
            asm_style.normalize_line("                dc.w 3", 0),
            " " * 16 + "dc.w    3",
        )

    def test_label_with_code_keeps_the_label_at_column_zero(self):
        self.assertEqual(
            asm_style.normalize_line("Checksum: dc.w $B7E0", 0),
            "Checksum:".ljust(16) + "dc.w    $B7E0",
        )

    def test_a_label_as_long_as_the_column_still_gets_a_space(self):
        line = asm_style.normalize_line("Sys_VectorTable: dc.l Foo", 0)
        self.assertEqual(line, "Sys_VectorTable: dc.l    Foo")

    def test_equ_keeps_its_name_in_the_label_field(self):
        self.assertEqual(
            asm_style.normalize_line("IO_CT1_CTRL equ $A10008", 0),
            "IO_CT1_CTRL".ljust(16) + "equ     $A10008",
        )

    def test_macro_definition_keeps_its_name_in_the_label_field(self):
        self.assertEqual(
            asm_style.normalize_line("cnop macro offset,alignment", 0),
            "cnop".ljust(16) + "macro   offset,alignment",
        )

    def test_quoted_strings_are_never_reflowed(self):
        # Collapsing whitespace inside an operand once rewrote the ROM header
        # and moved 48,105 bytes. The operand must be copied verbatim.
        source = 'Name:   dc.b    "FLICKY     GM 00001022-00"'
        self.assertIn('"FLICKY     GM 00001022-00"', asm_style.normalize_line(source, 0))

    def test_inline_comment_gets_exactly_two_spaces(self):
        self.assertEqual(
            asm_style.normalize_line("                rts      ; done", 0),
            " " * 16 + "rts  ; done",
        )

    def test_tabs_become_spaces(self):
        self.assertNotIn("\t", asm_style.normalize_line("Art:\tbinclude\t\"a.bin\"", 0))


class NormalizeFile(unittest.TestCase):
    def test_blank_runs_collapse_and_file_ends_with_one_newline(self):
        result = asm_style.normalize_file("A:\n\n\n\nB:\n\n\n")
        self.assertEqual(result, "A:\n\nB:\n")

    def test_normalization_is_idempotent(self):
        once = asm_style.normalize_file("  move.w  #1,d0\nLabel:  rts\n")
        self.assertEqual(asm_style.normalize_file(once), once)


class Checks(unittest.TestCase):
    def test_tab_and_trailing_space_are_reported(self):
        issues: list = []
        asm_style.check_lines(Path("x.s"), ["\tmove.w  #1,d0   "], issues)
        kinds = {issue.kind for issue in issues}
        self.assertIn("tab", kinds)
        self.assertIn("trailing-space", kinds)

    def test_non_ascii_is_reported_rather_than_rewritten(self):
        issues: list = []
        asm_style.check_lines(Path("x.s"), ["                rts  ; \u043e\u043a"], issues)
        self.assertIn("charset", {issue.kind for issue in issues})


if __name__ == "__main__":
    unittest.main()
