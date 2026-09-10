import tempfile
import unittest
import subprocess
from pathlib import Path

from scripts.validation.make_interface import (
    makefile_paths,
    makefile_recipe,
    makefile_text,
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
            "verify-emulator",
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

    def test_standalone_z80_build_verifies_selected_tools_first(self):
        root = Path(__file__).resolve().parents[2]
        result = subprocess.run(
            [
                "make",
                "-n",
                "-B",
                "z80-check",
                "Z80_REFERENCE=assets/manifest.json",
                "Z80_BIN=build/tool-order-z80.bin",
                "Z80_OBJ=build/tool-order-z80.p",
            ],
            cwd=root,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        verification = result.stdout.index("validation.verify_toolchain")
        build = result.stdout.index("build.build_z80_driver")
        self.assertLess(verification, build)
        self.assertIn("--require-executable", result.stdout)

    def test_runtime_launch_verifies_the_selected_emulator_first(self):
        root = Path(__file__).resolve().parents[2]
        result = subprocess.run(
            [
                "make",
                "-n",
                "-B",
                "reference",
                "MOVIE=longplay",
                "GENS_EXE=alternate/Gens.exe",
            ],
            cwd=root,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        verification = result.stdout.index("validation.verify_toolchain")
        launch = result.stdout.index("-screenshot-interval")
        self.assertLess(verification, launch)
        self.assertIn(
            '--require-executable "emulator=alternate/Gens.exe"', result.stdout
        )

    def test_every_make_runtime_launch_requires_emulator_verification(self):
        root = Path(__file__).resolve().parents[2]
        text = makefile_text(root)
        for target in (
            "reference",
            "analyze",
            "trace-runtime",
            "playtest-level",
            "smoke-level-playtest",
            "trace-sound",
        ):
            with self.subTest(target=target):
                declaration = next(
                    line for line in text.splitlines() if line.startswith(f"{target}:")
                )
                self.assertIn("_require-emulator", declaration)

    def test_emulator_build_uses_the_manifest_pin_before_compilation(self):
        root = Path(__file__).resolve().parents[2]
        recipe = " ".join(makefile_recipe("build-gens", root))
        prepare = recipe.index("build.prepare_gens_checkout")
        compile_step = recipe.index("$(MAKE) -C")
        verify = recipe.index("validation.verify_toolchain")
        self.assertLess(prepare, compile_step)
        self.assertLess(compile_step, verify)
        self.assertNotIn("git clone", recipe)

    def test_ymfm_build_uses_the_python_command_surface(self):
        root = Path(__file__).resolve().parents[2]
        recipe = " ".join(makefile_recipe("build-ymfm-renderer", root))

        self.assertIn("authoring.build_ymfm_renderer", recipe)
        self.assertNotIn("docker build", recipe)


if __name__ == "__main__":
    unittest.main()
