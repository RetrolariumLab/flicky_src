import tempfile
import unittest
from argparse import Namespace
from pathlib import Path
from unittest.mock import Mock, patch

from authoring import build_content
from authoring.build_content import resolve_workspace_paths
from authoring.studio_build import build_content_command


class StudioBuildInputsTests(unittest.TestCase):
    def test_studio_command_propagates_exact_resolved_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            level = root / "alternate level.json"
            sound = root / "alternate sound.asm"
            command = build_content_command(
                {
                    "level_layouts": level,
                    "z80_sound_banks": sound,
                }
            )
            self.assertEqual(
                command,
                [
                    "make",
                    "build-content",
                    f"CONTENT_LEVEL_WORKSPACE={level.resolve().as_posix()}",
                    f"CONTENT_SOUND_WORKSPACE={sound.resolve().as_posix()}",
                ],
            )

    def test_builder_resolves_overrides_and_manifest_defaults(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            external = root.parent / "alternate-level.json"
            manifest = {
                "workspace": "content/workspace",
                "artifacts": [
                    {"id": artifact_id, "workspace": f"defaults/{artifact_id}.json"}
                    for artifact_id in (
                        "level_layouts",
                        "graphics_assets",
                        "graphics_semantics",
                        "graphics_sequences",
                        "z80_sound_banks",
                    )
                ],
            }
            paths = resolve_workspace_paths(
                root,
                manifest,
                {"level_layouts": str(external)},
            )
            self.assertEqual(paths["level_layouts"], external.resolve())
            self.assertEqual(
                paths["graphics_assets"],
                (root / "content/workspace/defaults/graphics_assets.json").resolve(),
            )

    def test_studio_command_rejects_unknown_override(self):
        with self.assertRaisesRegex(ValueError, "unsupported content workspace"):
            build_content_command({"unknown": Path("workspace")})

    def test_content_builder_consumes_every_explicit_input_path(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            inputs = {
                "level_layouts": root / "alternate/level.json",
                "graphics_assets": root / "alternate/graphics.json",
                "graphics_semantics": root / "alternate/semantics.json",
                "graphics_sequences": root / "alternate/sequences.json",
                "z80_sound_banks": root / "alternate/sound.asm",
            }
            manifest = {
                "workspace": "content/workspace",
                "output": "build/content/flicky.bin",
                "artifacts": [
                    {
                        "id": artifact_id,
                        "workspace": f"defaults/{artifact_id}",
                        "baseline": "src/sound/z80/data.asm",
                        "capacity": 2804,
                    }
                    for artifact_id in inputs
                ],
            }
            args = Namespace(
                manifest="manifest.json",
                root=str(root),
                as_bin="assembler",
                p2bin="p2bin",
                as_args="-maxerrors 2",
                original_rom="original.bin",
                asset_manifest="assets.json",
                zero_edit=False,
                **{
                    argument: str(inputs[artifact_id])
                    for artifact_id, argument in build_content.WORKSPACE_ARGUMENTS.items()
                },
            )
            level_load = Mock(return_value={})
            graphics_load = Mock(return_value={})
            semantics_load = Mock(return_value={})
            sequences_load = Mock(return_value={})
            with (
                patch.object(build_content, "load_manifest", return_value=manifest),
                patch.object(build_content, "validate_workspace") as validate,
                patch.object(build_content, "load_document", level_load),
                patch.object(build_content, "apply_document"),
                patch.object(build_content, "load_graphics_document", graphics_load),
                patch.object(build_content, "build_graphics_assets", return_value={}),
                patch.object(build_content, "redirect_graphics_includes"),
                patch.object(build_content, "load_graphics_semantics", semantics_load),
                patch.object(build_content, "apply_graphics_semantics"),
                patch.object(build_content, "load_graphics_sequences", sequences_load),
                patch.object(build_content, "apply_graphics_sequences"),
                patch.object(
                    build_content,
                    "stage_sources",
                    return_value=root / "build/content/src/main.s",
                ),
                patch.object(build_content, "run"),
                patch.object(build_content.argparse.ArgumentParser, "parse_args", return_value=args),
            ):
                self.assertEqual(build_content.main(), 0)

            validate.assert_called_once_with(root, manifest, overrides=inputs)
            level_load.assert_called_once_with(inputs["level_layouts"])
            graphics_load.assert_called_once_with(inputs["graphics_assets"])
            semantics_load.assert_called_once_with(inputs["graphics_semantics"])
            sequences_load.assert_called_once_with(inputs["graphics_sequences"])


if __name__ == "__main__":
    unittest.main()
