import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]

from runtime import level_playtest  # noqa: E402


class LevelPlaytestTests(unittest.TestCase):
    def test_round_word_combines_bcd_display_and_plain_index(self) -> None:
        self.assertEqual(level_playtest.round_word(1), 0x0101)
        self.assertEqual(level_playtest.round_word(26), 0x261A)
        self.assertEqual(level_playtest.round_word(48), 0x4830)

    def test_round_number_is_bounded(self) -> None:
        for value in (0, 49):
            with self.assertRaisesRegex(ValueError, "1 through 48"):
                level_playtest.validate_round_number(value)

    def test_environment_selects_round_and_result(self) -> None:
        with mock.patch.dict(
            os.environ,
            {
                "FLICKY_PLAYTEST_RESULT": "stale.txt",
                "FLICKY_PLAYTEST_EXIT": "stale",
            },
            clear=True,
        ):
            interactive = level_playtest.playtest_environment(17)
            automated = level_playtest.playtest_environment(
                17, ROOT / "build/playtest.txt", exit_when_ready=True
            )
        self.assertEqual(interactive["FLICKY_PLAYTEST_ROUND"], "17")
        self.assertNotIn("FLICKY_PLAYTEST_RESULT", interactive)
        self.assertNotIn("FLICKY_PLAYTEST_EXIT", interactive)
        self.assertTrue(automated["FLICKY_PLAYTEST_RESULT"].endswith("playtest.txt"))
        self.assertEqual(automated["FLICKY_PLAYTEST_EXIT"], "1")

    def test_command_loads_rom_and_lua_script(self) -> None:
        command = level_playtest.playtest_command(Path("Gens.exe"), Path("game.bin"))
        self.assertEqual(command[1], "-rom")
        self.assertIn("-lua", command)
        self.assertNotIn("-max-frames", command)
        automated = level_playtest.playtest_command(
            Path("Gens.exe"), Path("game.bin"), automated=True
        )
        self.assertIn("-max-frames", automated)
        self.assertIn("-nosound", automated)

    def test_result_requires_selected_round_in_gameplay(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "result.txt"
            path.write_text(
                "status=ready round=26 round_word=261A mode=24 "
                "game_state=0000 lives=3 frame=120\n",
                encoding="utf-8",
            )
            fields = level_playtest.parse_result(path, 26)
            self.assertEqual(fields["game_state"], "0000")
            with self.assertRaisesRegex(RuntimeError, "playtest failed"):
                level_playtest.parse_result(path, 25)


if __name__ == "__main__":
    unittest.main()
