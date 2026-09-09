from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

from validation import check_source_structure as structure  # noqa: E402


class SourceStructureTests(unittest.TestCase):
    def test_repository_structure_passes(self):
        config = json.loads((ROOT / "config/reconstruction/source_structure.json").read_text())
        errors, summary = structure.check(ROOT, config)
        self.assertEqual(errors, [])
        self.assertGreater(summary["preferred"], 0)
        self.assertGreater(summary["exceptions"], 0)

    def test_out_of_range_file_requires_a_reason(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "src").mkdir()
            (root / "src/tiny.s").write_text("rts\n")
            config = {
                "preferred_line_range": {"minimum": 3, "maximum": 5},
                "exceptions": {},
            }
            errors, _ = structure.check(root, config)
            self.assertIn("has no exception reason", errors[0])

    def test_repeated_prefix_requires_a_directory_or_better_name(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "src").mkdir()
            for name in ("enemy_cat.s", "enemy_snake.s"):
                (root / "src" / name).write_text("a\nb\nc\n")
            config = {
                "preferred_line_range": {"minimum": 3, "maximum": 5},
                "exceptions": {},
            }
            errors, _ = structure.check(root, config)
            self.assertTrue(any("repeated filename prefix 'enemy'" in error for error in errors))

    def test_stale_exception_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "src").mkdir()
            (root / "src/normal.s").write_text("a\nb\nc\n")
            config = {
                "preferred_line_range": {"minimum": 3, "maximum": 5},
                "exceptions": {
                    "src/normal.s": "This reason is deliberately long enough for the schema check."
                },
            }
            errors, _ = structure.check(root, config)
            self.assertTrue(any("stale size exception" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
