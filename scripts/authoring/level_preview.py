"""Pixel-accurate level preview assembled from editable graphics workspaces."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from authoring.graphics_sequences_model import load_document as load_sequences_document


SCREEN_WIDTH = 256
SCREEN_HEIGHT = 224
TILE_SIZE = 8
MAP_WIDTH = SCREEN_WIDTH // TILE_SIZE
MAP_HEIGHT = SCREEN_HEIGHT // TILE_SIZE

VRAM_ASSETS = (
    (0x200, "level_tiles"),
    (0x400, "sprite_tiles"),
    (0x640, "score_tiles"),
    (0x693, "exit_tiles"),
)

SOLID_GROUND_WORDS = (
    0x220D, 0x2206, 0x2207, 0x2208,
    0x2209, 0x220A, 0x220B, 0x220C,
    0x220D, 0x220E, 0x220F, 0x2210,
    0x2211, 0x2212, 0x2213, 0x2214,
)

GROUP3_THEMES = (0, 1, 2, 3, 4, 0, 1, 2)
GROUP4_LABELS = (
    "Ending_GraphicsMap1", "Ending_GraphicsMap1", "Ending_GraphicsMap2",
    "Level_BgObject4Data2", "Level_BgObject4Data3", "Level_BgObject4Data4",
)
GROUP5_LABELS = (
    "Ending_GraphicsMap0", "Ending_GraphicsMap0", "Level_BgObject5Data1",
    "Level_BgObject5Data2", "Level_BgObject5Data3", "Level_BgObject5Data4",
)

TABLE_LABEL_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):\s*(.*)$")
DATA_RE = re.compile(r"^dc\.(b|w)\s+(.+)$", re.IGNORECASE)


def parse_number(value: str) -> int:
    value = value.strip()
    return int(value[1:], 16) if value.startswith("$") else int(value)


def table_words(path: Path, label: str) -> list[int]:
    """Read a word table, accepting a packed dc.b pair where the ROM does."""
    lines = path.read_text(encoding="utf-8").splitlines()
    collecting = False
    values: list[int] = []
    width: str | None = None
    for raw_line in lines:
        code = raw_line.split(";", 1)[0].strip()
        match = TABLE_LABEL_RE.match(code)
        if match:
            if collecting:
                break
            if match.group(1) != label:
                continue
            collecting = True
            code = match.group(2).strip()
        elif not collecting:
            continue
        directive = DATA_RE.match(code)
        if directive:
            current_width = directive.group(1).lower()
            if width is not None and current_width != width:
                raise ValueError(f"mixed-width data table: {label}")
            width = current_width
            mask = 0xFF if width == "b" else 0xFFFF
            values.extend(parse_number(token) & mask for token in directive.group(2).split(","))
        elif code:
            break
    if not values:
        raise ValueError(f"word table not found or empty: {label}")
    if width == "b":
        if len(values) % 2:
            raise ValueError(f"odd byte count in packed word table: {label}")
        return [(values[index] << 8) | values[index + 1] for index in range(0, len(values), 2)]
    return values


def md_color(word: int) -> str:
    red = ((word >> 1) & 7) * 255 // 7
    green = ((word >> 5) & 7) * 255 // 7
    blue = ((word >> 9) & 7) * 255 // 7
    return f"#{red:02x}{green:02x}{blue:02x}"


def round_theme(round_number: int) -> dict[str, int]:
    if not 1 <= round_number <= 48:
        raise ValueError("round number must be from 1 through 48")
    return {
        "tileset": (round_number % 24) // 4,
        "palette": (round_number % 48) // 4,
        "accent": (round_number - 1) % 15,
        "chick": (round_number - 1) % 15,
        "group3": ((round_number - 1) % 32) // 4,
    }


@dataclass
class LevelPreview:
    project: Path
    assets: dict[str, dict[str, Any]]
    palettes: dict[str, list[int]]
    mappings: dict[str, dict[str, Any]]
    tables: dict[str, list[int]]
    shared_palette: list[int]

    @classmethod
    def load(
        cls,
        project: Path,
        graphics_workspace: Path,
        semantics_workspace: Path,
        sequences_workspace: Path,
    ) -> "LevelPreview":
        graphics = json.loads(graphics_workspace.read_text(encoding="utf-8"))
        semantics = json.loads(semantics_workspace.read_text(encoding="utf-8"))
        sequences = load_sequences_document(sequences_workspace)
        return cls.from_documents(project, graphics, semantics, sequences)

    @classmethod
    def from_documents(
        cls,
        project: Path,
        graphics: dict[str, Any],
        semantics: dict[str, Any],
        sequences: dict[str, Any],
    ) -> "LevelPreview":
        assets = {entry["id"]: entry for entry in graphics["assets"]}
        palettes = {entry["id"]: entry["colours"] for entry in semantics["palettes"]}
        mappings = {entry["id"]: entry for entry in sequences["mappings"]}

        tables_path = project / "src/data/tables.s"
        table_labels = {
            "Level_DrawCatDoorData",
            *{f"Level_BackgroundTileData{index}" for index in range(6)},
            *{f"Level_UpperGroundData{index}" for index in range(6)},
            *{f"Level_LowerGroundData{index}" for index in range(6)},
            *{f"Level_GroundTileData{index}" for index in range(6)},
            "Level_BgObject0Data", "Level_BgObject1Data", "Level_BgObject2Data",
            *{f"Level_BgObject3Data{index}" for index in range(5)},
            *GROUP4_LABELS, *GROUP5_LABELS,
        }
        tables = {label: table_words(tables_path, label) for label in table_labels}
        tables["UI_EntryArrowFrame1"] = table_words(
            project / "src/rendering/hud.s", "UI_EntryArrowFrame1"
        )
        shared_words = table_words(project / "src/game/screens/game_over.s", "Gfx_SharedPalette")
        shared_palette = [0] * 64
        for word in shared_words:
            index = (word & 0x10) | ((word >> 12) & 0xF) | ((word & 0x100) >> 3)
            shared_palette[index] = word & 0xEEE
            if word & 1:
                break
        return cls(project, assets, palettes, mappings, tables, shared_palette)

    def palette_for_round(self, round_number: int) -> list[int]:
        theme = round_theme(round_number)
        palette = list(self.shared_palette)
        palette[16:32] = self.palettes[f"Level_Palette{theme['palette']}"]
        palette[60:64] = self.palettes[f"Level_AccentPalette{theme['accent']}"]
        return palette

    def tile(self, index: int) -> list[list[int]]:
        for base, identifier in reversed(VRAM_ASSETS):
            tiles = self.assets[identifier]["tiles"]
            offset = index - base
            if 0 <= offset < len(tiles):
                return tiles[offset]
        return [[0] * TILE_SIZE for _ in range(TILE_SIZE)]

    def draw_tile(
        self,
        frame: list[list[int]],
        palette: list[int],
        x: int,
        y: int,
        word: int,
        *,
        transparent: bool = False,
    ) -> None:
        pixels = self.tile(word & 0x7FF)
        palette_base = ((word >> 13) & 3) * 16
        hflip = bool(word & 0x0800)
        vflip = bool(word & 0x1000)
        for target_y in range(TILE_SIZE):
            source_y = TILE_SIZE - 1 - target_y if vflip else target_y
            screen_y = y + target_y
            if not 0 <= screen_y < SCREEN_HEIGHT:
                continue
            for target_x in range(TILE_SIZE):
                source_x = TILE_SIZE - 1 - target_x if hflip else target_x
                colour_index = pixels[source_y][source_x]
                if transparent and colour_index == 0:
                    continue
                screen_x = (x + target_x) % SCREEN_WIDTH
                frame[screen_y][screen_x] = palette[palette_base + colour_index]

    def draw_tilemap(
        self,
        frame: list[list[int]],
        palette: list[int],
        x: int,
        y: int,
        words: list[int],
        width: int,
        height: int,
        *,
        transparent: bool = True,
    ) -> None:
        for row in range(height):
            for column in range(width):
                self.draw_tile(
                    frame, palette,
                    (x + column) * TILE_SIZE, (y + row) * TILE_SIZE,
                    words[row * width + column],
                    transparent=transparent,
                )

    def draw_mapping(
        self,
        frame: list[list[int]],
        palette: list[int],
        identifier: str,
        center_x: int,
        center_y: int,
    ) -> None:
        mapping = self.mappings[identifier]
        for piece in mapping["pieces"]:
            width, height = piece["width"], piece["height"]
            for column in range(width):
                source_column = width - 1 - column if piece["hflip"] else column
                for row in range(height):
                    source_row = height - 1 - row if piece["vflip"] else row
                    tile_offset = source_column * height + source_row
                    word = piece["tile"] + tile_offset
                    word |= piece["palette"] << 13
                    if piece["hflip"]:
                        word |= 0x0800
                    if piece["vflip"]:
                        word |= 0x1000
                    self.draw_tile(
                        frame, palette,
                        center_x + piece["x"] + column * TILE_SIZE,
                        center_y + piece["y"] + row * TILE_SIZE,
                        word, transparent=True,
                    )

    @staticmethod
    def _linear(grid: list[list[int]], position: int) -> bool:
        return 0 <= position < MAP_WIDTH * MAP_HEIGHT and bool(
            grid[position // MAP_WIDTH][position % MAP_WIDTH]
        )

    def ground_word(self, grid: list[list[int]], x: int, y: int, theme: int) -> int:
        position = y * MAP_WIDTH + x
        solid = bool(grid[y][x])
        if solid:
            if x == 0:
                neighbours = (position - 32, position + 32, position + 31, position + 1)
            elif x == 31:
                neighbours = (position - 32, position + 32, position - 1, position - 31)
            else:
                neighbours = (position - 32, position + 32, position - 1, position + 1)
            mask = sum(int(self._linear(grid, neighbour)) << bit for bit, neighbour in enumerate(neighbours))
            return SOLID_GROUND_WORDS[mask]
        if x == 0:
            neighbours = (position - 32, position - 1, position + 31)
        else:
            neighbours = (position - 32, position - 33, position - 1)
        mask = sum(int(self._linear(grid, neighbour)) << bit for bit, neighbour in enumerate(neighbours))
        return self.tables[f"Level_GroundTileData{theme}"][mask]

    def render(
        self,
        layout: dict[str, Any],
        round_number: int,
    ) -> list[list[int]]:
        theme = round_theme(round_number)
        palette = self.palette_for_round(round_number)
        background_word = self.tables[f"Level_BackgroundTileData{theme['tileset']}"][0]
        background_colour = palette[((background_word >> 13) & 3) * 16]
        frame = [[background_colour] * SCREEN_WIDTH for _ in range(SCREEN_HEIGHT)]
        for y in range(MAP_HEIGHT):
            for x in range(MAP_WIDTH):
                self.draw_tile(frame, palette, x * TILE_SIZE, y * TILE_SIZE, background_word)

        grid = layout["collision"]
        for y in range(2, 26):
            for x in range(MAP_WIDTH):
                word = self.ground_word(grid, x, y, theme["tileset"])
                self.draw_tile(frame, palette, x * TILE_SIZE, y * TILE_SIZE, word, transparent=True)
        for x in range(MAP_WIDTH):
            if not grid[2][x]:
                word = self.tables[f"Level_GroundTileData{theme['tileset']}"][3]
                self.draw_tile(frame, palette, x * TILE_SIZE, 2 * TILE_SIZE, word, transparent=True)

        upper = self.tables[f"Level_UpperGroundData{theme['tileset']}"]
        lower = self.tables[f"Level_LowerGroundData{theme['tileset']}"]
        for x in range(0, MAP_WIDTH, 4):
            self.draw_tilemap(frame, palette, x, 0, upper, 4, 2)
            self.draw_tilemap(frame, palette, x, 26, lower, 4, 2)

        # The game's two tilemap planes are composed with the decorative
        # object plane above the ground plane. Colour zero remains transparent.
        objects = (
            ("player", "Level_BgObject0Data", 3, 3),
            ("entry_arrow", "Level_BgObject1Data", 2, 2),
            ("cat_door", "Level_BgObject1Data", 2, 2),
            ("exit_door", "Level_BgObject2Data", 2, 3),
        )
        for field, label, width, height in objects:
            self.draw_tilemap(frame, palette, *layout[field], self.tables[label], width, height)

        group3 = GROUP3_THEMES[theme["group3"]]
        dynamic_groups = (
            ("background_group_3", f"Level_BgObject3Data{group3}", 2, 3),
            ("background_group_4", GROUP4_LABELS[theme["tileset"]], 5, 3),
            ("background_group_5", GROUP5_LABELS[theme["tileset"]], 4, 4),
        )
        for field, label, width, height in dynamic_groups:
            for x, y in layout[field]:
                self.draw_tilemap(frame, palette, x, y, self.tables[label], width, height)

        self.draw_tilemap(
            frame, palette, layout["player"][0], layout["player"][1],
            self.tables["Level_DrawCatDoorData"], 3, 3,
        )
        self.draw_tilemap(
            frame, palette, layout["player"][0], layout["player"][1] - 1,
            self.tables["UI_EntryArrowFrame1"], 3, 1,
        )

        self.draw_mapping(
            frame, palette, "Player_WalkFrame1",
            layout["player"][0] * 8 + 12, layout["player"][1] * 8 + 24,
        )
        chick_mapping = f"Chick_ThrownAnim{theme['chick']}Data0"
        for x, y in layout["spawners"]:
            self.draw_mapping(frame, palette, chick_mapping, x * 8 + 8, y * 8 + 8)

        for field, mapping in (("chicks_a", "Cat_WalkFrame0"), ("chicks_b", "Cat_WalkAltFrame0")):
            for x, y in layout[field]:
                self.draw_mapping(frame, palette, mapping, x * 8 + 8, y * 8 + 16)
        return frame
