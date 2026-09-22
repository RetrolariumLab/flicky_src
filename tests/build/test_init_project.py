import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from scripts.build import init_project


class InitProjectTests(unittest.TestCase):
    def test_builds_z80_components_after_extraction_before_main_rom(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            rom = root / "reference.bin"
            rom.write_bytes(b"reference")
            manifest = root / "manifest.json"
            manifest.write_text(
                json.dumps(
                    {
                        "reference_rom": {
                            "name": "fixture",
                            "sha1": hashlib.sha1(rom.read_bytes()).hexdigest(),
                        }
                    }
                ),
                encoding="utf-8",
            )
            commands = []

            def record(command):
                commands.append(command)
                return subprocess.CompletedProcess(command, 0)

            with patch.object(
                sys,
                "argv",
                ["init_project", "--orig-rom", str(rom), "--manifest", str(manifest)],
            ), patch.object(init_project.subprocess, "run", side_effect=record):
                self.assertEqual(init_project.main(), 0)

            self.assertEqual(
                [command[2] for command in commands],
                [
                    "build.split_data_from_rom",
                    "build.check_assets",
                    "build.build_z80_driver",
                    "build.build_z80_driver",
                    "build.build_rom",
                ],
            )
            self.assertIn("--reference-offset", commands[3])
            self.assertEqual(commands[3][commands[3].index("--reference-offset") + 1], "12")


if __name__ == "__main__":
    unittest.main()
