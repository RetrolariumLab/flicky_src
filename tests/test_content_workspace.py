import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

from authoring import content_workspace  # noqa: E402


def manifest() -> dict:
    return {
        "schema_version": 1,
        "profile": "canonical",
        "workspace": "content/workspace",
        "output": "build/content/flicky.bin",
        "image_size": 131072,
        "image_sha1": "83d8bbf0a9b38c42a0bf492d105cc3abe9644a96",
        "studios": [
            {"id": "level", "status": "planned", "artifacts": []},
            {"id": "graphics", "status": "planned", "artifacts": []},
            {
                "id": "sound",
                "status": "foundation",
                "artifacts": ["sound"],
            },
        ],
        "artifacts": [
            {
                "id": "sound",
                "studio": "sound",
                "kind": "assembly_source",
                "baseline": "src/sound.asm",
                "workspace": "sound/sound.asm",
                "output": "build/content/sound.bin",
                "capacity": 8,
            }
        ],
    }


class ManifestValidation(unittest.TestCase):
    def test_project_manifest_is_valid(self):
        path = Path(__file__).resolve().parents[1] / "config" / "content_studios.json"
        self.assertEqual(content_workspace.validate_manifest(json.loads(path.read_text())), [])

    def test_parent_paths_are_rejected(self):
        document = manifest()
        document["artifacts"][0]["workspace"] = "../outside.asm"
        self.assertIn(
            "invalid artifact workspace: sound",
            content_workspace.validate_manifest(document),
        )


class WorkspaceLifecycle(unittest.TestCase):
    def test_init_does_not_overwrite_an_edit_without_force(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            baseline = root / "src" / "sound.asm"
            baseline.parent.mkdir(parents=True)
            baseline.write_text("baseline\n", encoding="utf-8")
            content_workspace.initialize(root, manifest())
            workspace = root / "content" / "workspace" / "sound" / "sound.asm"
            workspace.write_text("edited\n", encoding="utf-8")
            content_workspace.initialize(root, manifest())
            self.assertEqual(workspace.read_text(encoding="utf-8"), "edited\n")
            content_workspace.initialize(root, manifest(), force=True)
            self.assertEqual(workspace.read_text(encoding="utf-8"), "baseline\n")

    def test_staging_redirects_both_generated_sound_images(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "src"
            (source / "data").mkdir(parents=True)
            (source / "sound" / "z80").mkdir(parents=True)
            (source / "main.s").write_text('include "data/bank0.s"\n', encoding="utf-8")
            (source / "data" / "bank0.s").write_text(
                'binclude "build/z80_driver.bin"\n', encoding="utf-8"
            )
            (source / "sound" / "z80" / "load_data.s").write_text(
                'binclude "build/z80_sound_data.bin"\n', encoding="utf-8"
            )
            main = content_workspace.stage_sources(
                root,
                root / "build" / "content" / "src",
                Path("build/content/z80_driver.bin"),
                Path("build/content/z80_sound_data.bin"),
            )
            self.assertTrue(main.is_file())
            self.assertIn(
                'binclude "build/content/z80_driver.bin"',
                (main.parent / "data" / "bank0.s").read_text(encoding="utf-8"),
            )
            self.assertIn(
                'binclude "build/content/z80_sound_data.bin"',
                (main.parent / "sound" / "z80" / "load_data.s").read_text(encoding="utf-8"),
            )


if __name__ == "__main__":
    unittest.main()
