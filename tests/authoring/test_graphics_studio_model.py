import copy
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

from authoring import graphics_studio_model as model  # noqa: E402
from formats import enigma_dec, nemesis_dec  # noqa: E402


class GraphicsModelCli(unittest.TestCase):
    def run_validate(self, workspace: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                sys.executable,
                "-B",
                "scripts/run.py",
                "authoring.graphics_studio_model",
                "validate",
                "--workspace",
                str(workspace),
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )

    def test_missing_workspace_reports_a_public_command_error(self):
        with tempfile.TemporaryDirectory() as directory:
            workspace = Path(directory) / "missing.json"
            result = self.run_validate(workspace)

        self.assertEqual(result.returncode, 1)
        self.assertIn("[ERROR]", result.stderr)
        self.assertIn("missing.json", result.stderr)
        self.assertNotIn("Traceback", result.stderr)

    def test_malformed_workspace_reports_a_public_command_error(self):
        with tempfile.TemporaryDirectory() as directory:
            workspace = Path(directory) / "malformed.json"
            workspace.write_text("{not-json", encoding="utf-8")
            result = self.run_validate(workspace)

        self.assertEqual(result.returncode, 1)
        self.assertIn("[ERROR]", result.stderr)
        self.assertIn("Expecting property name", result.stderr)
        self.assertNotIn("Traceback", result.stderr)


class GraphicsDocument(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (ROOT / "data/artnem/data_LevelTiles.bin").is_file():
            raise unittest.SkipTest("extracted graphics are not present")
        cls.document = model.export_document(ROOT)

    def test_exports_all_fixed_region_assets(self):
        assets = model.asset_table(self.document)
        self.assertEqual(len(assets), 10)
        self.assertEqual(len(assets["level_tiles"]["tiles"]), 343)
        self.assertEqual(len(assets["sega_tilemap"]["words"]), 48)

    def test_zero_edit_preserves_every_compressed_byte(self):
        encoded = model.validate_document(self.document, ROOT)
        for identifier, _kind, relative, _capacity in model.ASSETS:
            self.assertEqual(encoded[identifier], (ROOT / relative).read_bytes())

    def test_edited_nemesis_tile_decodes_to_the_new_pixels(self):
        document = copy.deepcopy(self.document)
        assets = model.asset_table(document)
        pixel = assets["exit_tiles"]["tiles"][0][0][0]
        assets["exit_tiles"]["tiles"][0][0][0] = (pixel + 1) & 0x0F
        encoded = model.validate_document(document, ROOT)["exit_tiles"]
        decoded = nemesis_dec.decompress(encoded)
        self.assertEqual(decoded, model.tiles_to_packed_4bpp(assets["exit_tiles"]["tiles"]))

    def test_structured_sega_tilemap_edit_still_fits(self):
        document = copy.deepcopy(self.document)
        assets = model.asset_table(document)
        assets["sega_tilemap"]["words"] = list(range(1, 49))
        encoded = model.validate_document(document, ROOT)["sega_tilemap"]
        decoded = enigma_dec.decompress(encoded)
        self.assertEqual(
            decoded,
            b"".join(value.to_bytes(2, "big") for value in range(1, 49)),
        )

    def test_tile_count_cannot_change(self):
        document = copy.deepcopy(self.document)
        model.asset_table(document)["exit_tiles"]["tiles"].pop()
        with self.assertRaisesRegex(ValueError, "tile count cannot change"):
            model.validate_document(document, ROOT)

    def test_invalid_palette_channel_bits_are_rejected(self):
        document = copy.deepcopy(self.document)
        model.asset_table(document)["sega_palette"]["entries"][0]["colour"] = 1
        with self.assertRaisesRegex(ValueError, "bits \\$EEE"):
            model.validate_document(document, ROOT)


if __name__ == "__main__":
    unittest.main()
