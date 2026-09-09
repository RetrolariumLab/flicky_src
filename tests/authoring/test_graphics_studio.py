import unittest
from pathlib import Path
from unittest.mock import Mock, patch

from authoring import graphics_studio


class GraphicsStudioActions(unittest.TestCase):
    def studio(self) -> graphics_studio.GraphicsStudio:
        studio = graphics_studio.GraphicsStudio.__new__(
            graphics_studio.GraphicsStudio
        )
        studio.project = Path("project")
        studio.workspace = Path("graphics.json")
        studio.semantics_workspace = Path("semantics.json")
        studio.sequences_workspace = Path("sequences.json")
        studio.document = {}
        studio.semantics = {}
        studio.sequences = {}
        studio.status = Mock()
        return studio

    def test_build_rom_aborts_when_validation_fails(self):
        studio = self.studio()
        with (
            patch.object(
                graphics_studio,
                "validate_document",
                side_effect=ValueError("invalid graphics"),
            ),
            patch.object(graphics_studio.messagebox, "showerror") as error,
            patch.object(graphics_studio.subprocess, "Popen") as popen,
        ):
            studio.build_rom()

        error.assert_called_once()
        popen.assert_not_called()

    def test_build_rom_aborts_when_workspace_write_fails(self):
        studio = self.studio()
        with (
            patch.object(graphics_studio, "validate_document"),
            patch.object(graphics_studio, "validate_semantics"),
            patch.object(graphics_studio, "validate_sequences"),
            patch.object(
                graphics_studio,
                "atomic_write_json",
                side_effect=OSError("workspace is read-only"),
            ),
            patch.object(graphics_studio.messagebox, "showerror") as error,
            patch.object(graphics_studio.subprocess, "Popen") as popen,
        ):
            studio.build_rom()

        error.assert_called_once()
        popen.assert_not_called()

    def test_build_rom_starts_only_after_a_successful_save(self):
        studio = self.studio()
        studio.save = Mock(return_value=True)
        with patch.object(graphics_studio.subprocess, "Popen") as popen:
            studio.build_rom()

        studio.save.assert_called_once_with()
        popen.assert_called_once_with(["make", "build-content"], cwd=Path("project"))
        studio.status.set.assert_called_once_with("Started make build-content")


if __name__ == "__main__":
    unittest.main()
