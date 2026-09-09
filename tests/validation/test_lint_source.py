import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

from validation import lint_source  # noqa: E402


class AddressDerivedNames(unittest.TestCase):
    def test_disassembler_names_are_recognised(self):
        for name in ("loc_11F2A", "locret_DF8", "sub_1407E", "word_1A8F8",
                     "byte_466", "dword_FFFFCA", "off_154AE", "unk_FFC800",
                     "nullsub_1"):
            self.assertTrue(lint_source.ADDRESS_DERIVED_RE.match(name), name)

    def test_semantic_names_are_not_flagged(self):
        for name in ("Player_CheckGround", "Ram_ChicksRemaining", "Level_Palette0",
                     "Cat_WalkFrame3", "j_Sound_QueueSFX", "VDP_CTRL",
                     "Sound_QueueSFX_TrySlot2"):
            self.assertIsNone(lint_source.ADDRESS_DERIVED_RE.match(name), name)

    def test_a_name_that_merely_ends_in_digits_is_allowed(self):
        # Level_Palette11 keeps a number because it is an index, not an address.
        self.assertIsNone(lint_source.ADDRESS_DERIVED_RE.match("Level_Palette11"))


class RawHardwareAddresses(unittest.TestCase):
    def test_a_port_literal_is_caught(self):
        self.assertTrue(lint_source.RAW_HARDWARE_RE.search("move.w d0,($C00004).l"))
        self.assertTrue(lint_source.RAW_HARDWARE_RE.search("move.b d0,($A11100).l"))

    def test_a_vdp_command_word_is_not_a_port(self):
        # $C0000000 is a CRAM write command, not the $C00000 data port. Five
        # apparent violations in the source turned out to be exactly this.
        self.assertIsNone(lint_source.RAW_HARDWARE_RE.search("move.l #$C0000000,(VDP_CTRL).l"))
        self.assertIsNone(lint_source.RAW_HARDWARE_RE.search("move.l #$40000010,(VDP_CTRL).l"))


class CallDetection(unittest.TestCase):
    def test_branch_to_subroutine_is_a_call(self):
        match = lint_source.CALL_RE.match("                bsr.w   Player_CheckGround")
        self.assertEqual(match.group(1), "Player_CheckGround")

    def test_jump_to_subroutine_through_a_symbol_is_a_call(self):
        match = lint_source.CALL_RE.match("                jsr     (j_Sound_QueueSFX)")
        self.assertEqual(match.group(1), "j_Sound_QueueSFX")

    def test_a_plain_branch_is_not_a_call(self):
        self.assertIsNone(lint_source.CALL_RE.match("                bra.s   Loop"))


class CommentHandling(unittest.TestCase):
    def test_a_semicolon_inside_a_string_does_not_start_a_comment(self):
        line = '                dc.b    "; 250 PTS.",0'
        self.assertEqual(lint_source.split_comment(line), line)

    def test_a_real_comment_is_removed(self):
        self.assertEqual(
            lint_source.split_comment("                rts  ; done").rstrip(),
            "                rts",
        )


class SourceIsClean(unittest.TestCase):
    def test_the_repository_passes_its_own_strict_check(self):
        import subprocess
        result = subprocess.run(
            [
                sys.executable,
                str(ROOT / "scripts" / "run.py"),
                "validation.lint_source",
                "--strict-naming",
            ],
            cwd=ROOT, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
