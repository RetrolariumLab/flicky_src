import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import graphics_semantics_model, graphics_sequences_model  # noqa: E402
from authoring import graphics_studio_model, level_preview, level_studio_model  # noqa: E402


class LevelPreviewRendering(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.graphics = graphics_studio_model.export_document(ROOT)
        cls.semantics = graphics_semantics_model.export_document(ROOT)
        cls.sequences = graphics_sequences_model.export_document(ROOT)
        cls.preview = level_preview.LevelPreview.from_documents(
            ROOT, cls.graphics, cls.semantics, cls.sequences
        )
        cls.levels = level_studio_model.export_document(ROOT)

    def test_round_theme_matches_the_game_modulo_tables(self) -> None:
        self.assertEqual(
            level_preview.round_theme(1),
            {"tileset": 0, "palette": 0, "accent": 0, "chick": 0, "group3": 0},
        )
        self.assertEqual(level_preview.round_theme(24)["tileset"], 0)
        self.assertEqual(level_preview.round_theme(48)["palette"], 0)
        self.assertEqual(level_preview.round_theme(16)["accent"], 0)
        self.assertEqual(level_preview.round_theme(3)["tileset"], 0)
        self.assertEqual(level_preview.round_theme(4)["tileset"], 1)
        self.assertEqual(level_preview.round_theme(23)["tileset"], 5)
        self.assertEqual(level_preview.round_theme(47)["palette"], 11)

    def test_cram_channels_follow_megadrive_bgr_word_order(self) -> None:
        self.assertEqual(level_preview.md_color(0x00E), "#fc0000")
        self.assertEqual(level_preview.md_color(0x0E0), "#00fc00")
        self.assertEqual(level_preview.md_color(0xE00), "#0000fc")

    def test_upper_ground_replaces_background_tilemap_cells(self) -> None:
        layout = self.levels["layouts"][self.levels["round_layouts"][3]]
        frame = self.preview.render(layout, 4)
        palette = self.preview.palette_for_round(4)
        background_word = self.preview.tables["Level_BackgroundTileData1"][0]
        upper = self.preview.tables["Level_UpperGroundData1"]

        found_transparent_sample = False
        for screen_y in range(16):
            for plane_x in range(32):
                word = upper[(screen_y // 8) * 4 + plane_x // 8]
                tile = self.preview.tile(word & 0x7FF)
                colour = tile[screen_y % 8][plane_x % 8]
                screen_x = (plane_x + level_preview.PLANE_B_SCROLL_X) % 256
                background = self.preview.tile(background_word & 0x7FF)
                background_colour = background[screen_y % 8][screen_x % 8]
                if colour or not background_colour:
                    continue
                self.assertEqual(frame[screen_y][screen_x], palette[0])
                found_transparent_sample = True
        self.assertTrue(found_transparent_sample)

    def test_vram_indices_resolve_to_editable_graphics(self) -> None:
        assets = {entry["id"]: entry for entry in self.graphics["assets"]}
        self.assertEqual(self.preview.tile(0x200), assets["level_tiles"]["tiles"][0])
        self.assertEqual(self.preview.tile(0x400), assets["sprite_tiles"]["tiles"][0])
        self.assertEqual(self.preview.tile(0x640), assets["score_tiles"]["tiles"][0])
        self.assertEqual(self.preview.tile(0x693), assets["exit_tiles"]["tiles"][0])

    def test_canonical_exit_door_uses_the_exit_letter_tiles(self) -> None:
        self.assertEqual(self.preview.tables["UI_EntryArrowFrame1"], [0x693, 0x694, 0x695])

    def test_round_palette_combines_shared_level_and_accent_colours(self) -> None:
        palette = self.preview.palette_for_round(1)
        palettes = {entry["id"]: entry["colours"] for entry in self.semantics["palettes"]}
        self.assertEqual(palette[16:32], palettes["Level_Palette0"])
        self.assertEqual(palette[60:64], palettes["Level_AccentPalette0"])
        self.assertNotEqual(palette[32:48], [0] * 16)

    def test_round_renders_a_complete_game_frame(self) -> None:
        layout = self.levels["layouts"][self.levels["round_layouts"][0]]
        frame = self.preview.render(layout, 1)
        self.assertEqual(len(frame), level_preview.SCREEN_HEIGHT)
        self.assertTrue(all(len(row) == level_preview.SCREEN_WIDTH for row in frame))
        self.assertGreater(len({colour for row in frame for colour in row}), 12)

    def test_hanging_chicks_and_enemy_groups_affect_the_frame(self) -> None:
        layout = self.levels["layouts"][self.levels["round_layouts"][0]]
        full = self.preview.render(layout, 1)
        without_chicks = dict(layout, spawners=[])
        without_enemies = dict(layout, chicks_a=[], chicks_b=[])
        self.assertNotEqual(full, self.preview.render(without_chicks, 1))
        self.assertNotEqual(full, self.preview.render(without_enemies, 1))


if __name__ == "__main__":
    unittest.main()
