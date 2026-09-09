import stat
import tempfile
import unittest
from pathlib import Path

from build import clean_project


class CleanProjectTests(unittest.TestCase):
    def test_clean_preserves_workspace_and_unapproved_tmp_directories(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            generated = root / "build" / "tmp" / "result.bin"
            readonly = root / "build" / "source-checkout" / "readonly.pack"
            workspace = root / "content" / "workspace" / "tmp" / "draft.json"
            unrelated = root / "notes" / "tmp" / "research.txt"
            cache = root / "scripts" / "authoring" / "__pycache__" / "model.pyc"
            for path in (generated, readonly, workspace, unrelated, cache):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("keep-or-remove", encoding="utf-8")
            readonly.chmod(stat.S_IREAD)

            clean_project.clean(root)

            self.assertFalse((root / "build").exists())
            self.assertFalse(cache.parent.exists())
            self.assertEqual(workspace.read_text(encoding="utf-8"), "keep-or-remove")
            self.assertEqual(unrelated.read_text(encoding="utf-8"), "keep-or-remove")

    def test_cleanup_rejects_resolved_paths_outside_project(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            with self.assertRaisesRegex(ValueError, "escapes the project root"):
                clean_project.resolved_inside(root, root.parent / "outside")
            with self.assertRaisesRegex(ValueError, "project root"):
                clean_project.resolved_inside(root, root)


if __name__ == "__main__":
    unittest.main()
