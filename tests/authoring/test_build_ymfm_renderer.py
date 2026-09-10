import unittest
from pathlib import Path

from authoring import build_ymfm_renderer


class BuildYmfmRendererTests(unittest.TestCase):
    def test_native_frontend_build_uses_the_scripts_source_and_pinned_platform(self):
        command = build_ymfm_renderer.build_command(
            "approved-docker", Path("bin/windows_i386")
        )

        self.assertEqual(
            command[:4],
            ["approved-docker", "build", "--platform", "linux/amd64"],
        )
        self.assertIn("scripts/authoring/ymfm_renderer/Dockerfile", command)
        self.assertEqual(command[-1], ".")

    def test_python_codecs_are_the_only_nemesis_and_enigma_implementations(self):
        root = Path(__file__).resolve().parents[2]
        expected = {
            "enigma_dec.py",
            "enigma_enc.py",
            "nemesis_dec.py",
            "nemesis_enc.py",
        }

        self.assertEqual(
            {path.name for path in (root / "scripts" / "formats").glob("*.py")}
            - {"__init__.py"},
            expected,
        )
        self.assertFalse((root / "tools").exists())
        self.assertEqual(
            [path for path in root.rglob("*emesis_dec.c") if ".git" not in path.parts],
            [],
        )
        self.assertEqual(
            [path for path in root.rglob("*nigma_dec.c") if ".git" not in path.parts],
            [],
        )


if __name__ == "__main__":
    unittest.main()
