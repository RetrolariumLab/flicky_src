import tempfile
import unittest
from pathlib import Path

from scripts.build.relocate import ROM_SIZE, relocated_main, runnable


class RunnableImageTests(unittest.TestCase):
    def test_the_packed_image_is_padded_and_its_header_updated(self):
        packed = bytearray(0x300)
        packed[0x200:0x204] = bytes((0x12, 0x34, 0x00, 0x01))
        image = runnable(bytes(packed))
        self.assertEqual(ROM_SIZE, len(image))
        self.assertEqual(b"\xff" * (ROM_SIZE - 0x300), image[0x300:])
        self.assertEqual(ROM_SIZE - 1, int.from_bytes(image[0x1A4:0x1A8], "big"))
        expected = (0x1234 + 0x0001 + 0xFFFF * ((ROM_SIZE - 0x300) // 2)) & 0xFFFF
        self.assertEqual(expected, int.from_bytes(image[0x18E:0x190], "big"))

    def test_an_image_larger_than_the_cartridge_is_refused(self):
        with self.assertRaises(SystemExit):
            runnable(bytes(ROM_SIZE + 2))


class RelocatedMainTests(unittest.TestCase):
    def test_probes_follow_every_module_from_the_startup_code_and_the_gaps_go(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "src"
            (source / "system").mkdir(parents=True)
            (source / "data").mkdir()
            (source / "data" / "bank0.s").write_text("                org     $10000\nBank0:\n")
            (source / "data" / "tables.s").write_text("Tables:\n                org     $1FFFF\n")
            main = source / "main.s"
            main.write_text(
                '                include "vectors.s"\n'
                '                include "system/startup.s"\n'
                '                include "data/bank0.s"\n'
                '                include "data/tables.s"\n',
                encoding="utf-8",
            )
            output = root / "out"
            output.mkdir()

            text, probes = relocated_main(main, output)

            self.assertEqual(2, probes)
            lines = text.splitlines()
            self.assertEqual('                include "src/vectors.s"', lines[0])
            self.assertEqual('                include "src/system/startup.s"', lines[1])
            self.assertIn("$4E71", lines[2])
            self.assertEqual("Bank0:\n", (output / "bank0.s").read_text())
            self.assertEqual("Tables:\n", (output / "tables.s").read_text())


if __name__ == "__main__":
    unittest.main()
