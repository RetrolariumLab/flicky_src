import tempfile
import unittest
from pathlib import Path
from unittest import mock

from build import build_rom


class BuildRomTests(unittest.TestCase):
    def test_link_atomically_replaces_an_existing_rom(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            obj = root / "main.p"
            output = root / "flicky.bin"
            converter = root / "p2bin"
            output.write_bytes(b"previous ROM")

            def convert(command, cwd=None):
                self.assertIsNone(cwd)
                Path(command[2]).write_bytes(b"replacement ROM")
                return 0

            with mock.patch.object(build_rom, "run", side_effect=convert):
                build_rom.link(obj, output, converter, "FF")

            self.assertEqual(output.read_bytes(), b"replacement ROM")
            self.assertEqual(list(root.glob(".flicky.bin.*.tmp")), [])

    def test_link_preserves_existing_rom_when_converter_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            obj = root / "main.p"
            output = root / "flicky.bin"
            converter = root / "p2bin"
            output.write_bytes(b"verified ROM")

            def fail_after_partial_output(command, cwd=None):
                self.assertIsNone(cwd)
                Path(command[2]).write_bytes(b"partial output")
                return 1

            with mock.patch.object(
                build_rom,
                "run",
                side_effect=fail_after_partial_output,
            ):
                with self.assertRaises(SystemExit):
                    build_rom.link(obj, output, converter, "FF")

            self.assertEqual(output.read_bytes(), b"verified ROM")
            self.assertEqual(list(root.glob(".flicky.bin.*.tmp")), [])


if __name__ == "__main__":
    unittest.main()
