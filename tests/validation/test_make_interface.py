import tempfile
import unittest
import subprocess
from pathlib import Path

from scripts.validation.make_interface import (
    makefile_paths,
    makefile_recipe,
    makefile_targets,
)


class MakeInterfaceTests(unittest.TestCase):
    def test_project_interface_includes_workflow_fragments(self):
        root = Path(__file__).resolve().parents[2]
        paths = makefile_paths(root)

        self.assertEqual(paths[0], root / "Makefile")
        self.assertIn(root / "mk" / "authoring.mk", paths)
        self.assertIn("source-2-check", makefile_targets(root))
        self.assertIn("level-studio", makefile_targets(root))
        self.assertIn("smoke-studios-workstation", makefile_targets(root))
        self.assertIn("scaffold-check", makefile_targets(root))
        self.assertIn("format-check", makefile_targets(root))

    def test_explicit_targets_are_collected_from_root_and_fragments(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "mk").mkdir()
            (root / "Makefile").write_text("root-target:\n\t@true\n", encoding="utf-8")
            (root / "mk" / "workflow.mk").write_text(
                "first second:\n\t@true\n", encoding="utf-8"
            )

            self.assertEqual(
                makefile_targets(root), {"root-target", "first", "second"}
            )
            self.assertEqual(makefile_recipe("second", root), ["@true"])

    def test_help_lists_the_release_workflow(self):
        root = Path(__file__).resolve().parents[2]
        result = subprocess.run(
            ["make", "help"], cwd=root, capture_output=True, text=True, check=False
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        for target in (
            "format-check",
            "scaffold-check",
            "source-2-check",
            "source-2-pre-tag-check",
            "source-2-tag-check",
            "smoke-studios-workstation",
        ):
            self.assertIn(f"make {target}", result.stdout)

    def test_source_2_check_uses_the_manifest_audit(self):
        root = Path(__file__).resolve().parents[2]
        recipe = makefile_recipe("source-2-check", root)
        self.assertEqual(recipe[0], "$(MAKE) release-check")
        self.assertIn("$(MAKE) smoke-studios-workstation", recipe)
        self.assertEqual(recipe[-1], "$(MAKE) source-2-audit")

    def test_content_build_passes_every_workspace_selector(self):
        root = Path(__file__).resolve().parents[2]
        recipe = " ".join(makefile_recipe("build-content", root))
        for option in (
            "--level-workspace",
            "--graphics-workspace",
            "--semantics-workspace",
            "--sequences-workspace",
            "--sound-workspace",
        ):
            self.assertIn(option, recipe)


if __name__ == "__main__":
    unittest.main()
