#!/usr/bin/env python3
"""Tkinter Graphics Studio for Flicky's raster and semantic visual assets."""

from __future__ import annotations

import argparse
import copy
import subprocess
import tkinter as tk
from pathlib import Path
from tkinter import messagebox, ttk
from typing import Any

from authoring.graphics_studio_model import atomic_write_json, asset_table, load_document, validate_document
from authoring.graphics_semantics_model import (
    atomic_write_json as atomic_write_semantics,
    load_document as load_semantics,
    validate_document as validate_semantics,
)
from authoring.graphics_sequences_model import (
    atomic_write_json as atomic_write_sequences,
    load_document as load_sequences,
    validate_document as validate_sequences,
)


PIXEL = 40
GENERIC_COLORS = (
    "#000000", "#202020", "#404040", "#606060",
    "#004080", "#0060a0", "#0080c0", "#00a0e0",
    "#804000", "#a06000", "#c08000", "#e0a000",
    "#800040", "#a00060", "#c00080", "#ffffff",
)


def md_color(word: int) -> str:
    red = ((word >> 1) & 7) * 255 // 7
    green = ((word >> 5) & 7) * 255 // 7
    blue = ((word >> 9) & 7) * 255 // 7
    return f"#{red:02x}{green:02x}{blue:02x}"


class GraphicsStudio:
    def __init__(
        self,
        root: tk.Tk,
        project: Path,
        workspace: Path,
        semantics_workspace: Path,
        sequences_workspace: Path,
    ):
        self.root = root
        self.project = project
        self.workspace = workspace
        self.document = load_document(workspace)
        validate_document(self.document, project)
        self.semantics_workspace = semantics_workspace
        self.semantics = load_semantics(semantics_workspace)
        validate_semantics(self.semantics, project)
        self.sequences_workspace = sequences_workspace
        self.sequences = load_sequences(sequences_workspace)
        validate_sequences(self.sequences, project)
        self.saved = copy.deepcopy(self.document)
        self.saved_semantics = copy.deepcopy(self.semantics)
        self.saved_sequences = copy.deepcopy(self.sequences)
        self.assets = asset_table(self.document)
        self.texts = {record["id"]: record for record in self.semantics["texts"]}
        self.game_palettes = {record["id"]: record for record in self.semantics["palettes"]}
        self.mappings = {record["id"]: record for record in self.sequences["mappings"]}
        self.animations = {record["id"]: record for record in self.sequences["animations"]}
        self.tile_asset = tk.StringVar(value="level_tiles")
        self.tile_index = tk.IntVar(value=0)
        self.paint_color = tk.IntVar(value=1)
        self.palette_entry = tk.IntVar(value=0)
        self.palette_index = tk.IntVar(value=0)
        self.palette_colour = tk.StringVar(value="$000")
        self.screen_cell = tk.IntVar(value=0)
        self.screen_word = tk.StringVar(value="$0000")
        self.text_id = tk.StringVar(value=next(iter(self.texts)))
        self.text_value = tk.StringVar()
        self.game_palette_id = tk.StringVar(value=next(iter(self.game_palettes)))
        self.game_palette_entry = tk.IntVar(value=0)
        self.game_palette_colour = tk.StringVar(value="$000")
        self.mapping_id = tk.StringVar(value=next(iter(self.mappings)))
        self.mapping_piece = tk.IntVar(value=0)
        self.mapping_x = tk.IntVar()
        self.mapping_flipped_x = tk.IntVar()
        self.mapping_y = tk.IntVar()
        self.mapping_width = tk.IntVar()
        self.mapping_height = tk.IntVar()
        self.mapping_tile = tk.IntVar()
        self.mapping_palette = tk.IntVar()
        self.mapping_priority = tk.BooleanVar()
        self.mapping_hflip = tk.BooleanVar()
        self.mapping_vflip = tk.BooleanVar()
        self.animation_id = tk.StringVar(value=next(iter(self.animations)))
        self.animation_frame = tk.IntVar(value=0)
        self.animation_delay = tk.IntVar()
        self.animation_mapping = tk.StringVar()
        self.status = tk.StringVar(value="Ready")
        self._build_ui()
        self.refresh_tiles()
        self.refresh_palette()
        self.refresh_screen()

    def _build_ui(self) -> None:
        self.root.title("Flicky Graphics Studio")
        self.root.protocol("WM_DELETE_WINDOW", self.close)
        toolbar = ttk.Frame(self.root, padding=6)
        toolbar.pack(fill="x")
        ttk.Button(toolbar, text="Save", command=self.save).pack(side="left")
        ttk.Button(toolbar, text="Reload", command=self.reload).pack(side="left", padx=4)
        ttk.Button(toolbar, text="Build ROM", command=self.build_rom).pack(side="left")
        ttk.Label(toolbar, textvariable=self.status).pack(side="left", padx=12)
        notebook = ttk.Notebook(self.root)
        notebook.pack(fill="both", expand=True, padx=6, pady=(0, 6))
        self._build_tiles_tab(notebook)
        self._build_palette_tab(notebook)
        self._build_screen_tab(notebook)
        self._build_text_tab(notebook)
        self._build_game_palettes_tab(notebook)
        self._build_mappings_tab(notebook)
        self._build_animations_tab(notebook)

    def _build_tiles_tab(self, notebook: ttk.Notebook) -> None:
        tab = ttk.Frame(notebook, padding=8)
        notebook.add(tab, text="Tiles and fonts")
        controls = ttk.Frame(tab)
        controls.pack(fill="x")
        tile_ids = [
            identifier for identifier, asset in self.assets.items()
            if asset["kind"] in {"tiles_4bpp", "tiles_1bpp"}
        ]
        chooser = ttk.Combobox(controls, values=tile_ids, textvariable=self.tile_asset, state="readonly")
        chooser.pack(side="left")
        chooser.bind("<<ComboboxSelected>>", lambda _event: self.select_tile_asset())
        ttk.Button(controls, text="<", width=3, command=lambda: self.step_tile(-1)).pack(side="left", padx=(8, 2))
        spin = ttk.Spinbox(controls, from_=0, to=999, width=6, textvariable=self.tile_index, command=self.refresh_tiles)
        spin.pack(side="left")
        spin.bind("<Return>", lambda _event: self.refresh_tiles())
        ttk.Button(controls, text=">", width=3, command=lambda: self.step_tile(1)).pack(side="left", padx=2)
        ttk.Label(controls, text="Paint index").pack(side="left", padx=(14, 4))
        ttk.Spinbox(controls, from_=0, to=15, width=4, textvariable=self.paint_color).pack(side="left")
        self.tile_label = ttk.Label(controls)
        self.tile_label.pack(side="left", padx=12)
        self.tile_canvas = tk.Canvas(
            tab, width=8 * PIXEL, height=8 * PIXEL, background="#111111", highlightthickness=0
        )
        self.tile_canvas.pack(anchor="w", pady=8)
        self.tile_canvas.bind("<Button-1>", self.paint_pixel)
        self.tile_canvas.bind("<Button-3>", self.erase_pixel)

    def _build_palette_tab(self, notebook: ttk.Notebook) -> None:
        tab = ttk.Frame(notebook, padding=8)
        notebook.add(tab, text="Sega palette")
        self.palette_canvas = tk.Canvas(tab, width=10 * 48, height=64, highlightthickness=0)
        self.palette_canvas.pack(anchor="w")
        self.palette_canvas.bind("<Button-1>", self.select_palette_swatch)
        controls = ttk.Frame(tab)
        controls.pack(anchor="w", pady=8)
        ttk.Label(controls, text="Entry").pack(side="left")
        ttk.Spinbox(
            controls, from_=0, to=9, width=4, textvariable=self.palette_entry,
            command=self.load_palette_entry,
        ).pack(side="left")
        ttk.Label(controls, text="CRAM index").pack(side="left", padx=(12, 4))
        ttk.Spinbox(controls, from_=0, to=63, width=4, textvariable=self.palette_index).pack(side="left")
        ttk.Label(controls, text="Colour $0EEE").pack(side="left", padx=(12, 4))
        ttk.Entry(controls, width=8, textvariable=self.palette_colour).pack(side="left")
        ttk.Button(controls, text="Update", command=self.update_palette).pack(side="left", padx=8)

    def _build_screen_tab(self, notebook: ttk.Notebook) -> None:
        tab = ttk.Frame(notebook, padding=8)
        notebook.add(tab, text="Sega screen")
        self.screen_canvas = tk.Canvas(tab, width=12 * 48, height=4 * 48, background="#111111")
        self.screen_canvas.pack(anchor="w")
        self.screen_canvas.bind("<Button-1>", self.select_screen_cell)
        controls = ttk.Frame(tab)
        controls.pack(anchor="w", pady=8)
        ttk.Label(controls, text="Cell").pack(side="left")
        ttk.Spinbox(
            controls, from_=0, to=47, width=5, textvariable=self.screen_cell,
            command=self.load_screen_word,
        ).pack(side="left")
        ttk.Label(controls, text="Tile word").pack(side="left", padx=(12, 4))
        ttk.Entry(controls, width=9, textvariable=self.screen_word).pack(side="left")
        ttk.Button(controls, text="Update", command=self.update_screen_word).pack(side="left", padx=8)
        ttk.Label(
            tab,
            text="The original slot is only 10 bytes. Save/build reports when an edited optimal Enigma stream cannot fit.",
            wraplength=560,
        ).pack(anchor="w")

    def _build_text_tab(self, notebook: ttk.Notebook) -> None:
        tab = ttk.Frame(notebook, padding=8)
        notebook.add(tab, text="Game text")
        chooser = ttk.Combobox(
            tab, values=list(self.texts), textvariable=self.text_id, state="readonly", width=40
        )
        chooser.pack(anchor="w")
        chooser.bind("<<ComboboxSelected>>", lambda _event: self.load_text())
        ttk.Entry(tab, textvariable=self.text_value, width=70).pack(anchor="w", pady=8)
        ttk.Button(tab, text="Update", command=self.update_text).pack(anchor="w")
        self.text_help = ttk.Label(tab, wraplength=620)
        self.text_help.pack(anchor="w", pady=8)
        ttk.Label(
            tab,
            text="Shorter text is padded with spaces in the staged ROM; addresses and section sizes stay fixed.",
            wraplength=620,
        ).pack(anchor="w")
        self.load_text()

    def _build_game_palettes_tab(self, notebook: ttk.Notebook) -> None:
        tab = ttk.Frame(notebook, padding=8)
        notebook.add(tab, text="Game palettes")
        chooser = ttk.Combobox(
            tab,
            values=list(self.game_palettes),
            textvariable=self.game_palette_id,
            state="readonly",
            width=36,
        )
        chooser.pack(anchor="w")
        chooser.bind("<<ComboboxSelected>>", lambda _event: self.refresh_game_palette())
        self.game_palette_canvas = tk.Canvas(tab, width=16 * 40, height=60, highlightthickness=0)
        self.game_palette_canvas.pack(anchor="w", pady=8)
        self.game_palette_canvas.bind("<Button-1>", self.select_game_palette_swatch)
        controls = ttk.Frame(tab)
        controls.pack(anchor="w")
        ttk.Label(controls, text="Entry").pack(side="left")
        ttk.Spinbox(
            controls,
            from_=0,
            to=15,
            width=4,
            textvariable=self.game_palette_entry,
            command=self.load_game_palette_entry,
        ).pack(side="left")
        ttk.Label(controls, text="Colour $0EEE").pack(side="left", padx=(12, 4))
        ttk.Entry(controls, width=8, textvariable=self.game_palette_colour).pack(side="left")
        ttk.Button(controls, text="Update", command=self.update_game_palette).pack(side="left", padx=8)
        self.refresh_game_palette()

    def _build_mappings_tab(self, notebook: ttk.Notebook) -> None:
        tab = ttk.Frame(notebook, padding=8)
        notebook.add(tab, text="Sprite mappings")
        chooser = ttk.Combobox(
            tab, values=list(self.mappings), textvariable=self.mapping_id, state="readonly", width=42
        )
        chooser.grid(row=0, column=0, columnspan=6, sticky="w")
        chooser.bind("<<ComboboxSelected>>", lambda _event: self.select_mapping())
        self.mapping_canvas = tk.Canvas(tab, width=420, height=280, background="#182026")
        self.mapping_canvas.grid(row=1, column=0, columnspan=6, sticky="w", pady=8)
        fields = (
            ("Piece", self.mapping_piece, 0, 31),
            ("X", self.mapping_x, -128, 127),
            ("Mirrored X", self.mapping_flipped_x, -128, 127),
            ("Y", self.mapping_y, -128, 127),
            ("Width", self.mapping_width, 1, 4),
            ("Height", self.mapping_height, 1, 4),
            ("Tile", self.mapping_tile, 0, 0x7FF),
            ("Palette", self.mapping_palette, 0, 3),
        )
        for index, (label, variable, low, high) in enumerate(fields):
            row, column = 2 + index // 4, (index % 4) * 2
            ttk.Label(tab, text=label).grid(row=row, column=column, sticky="e", padx=(4, 2), pady=3)
            command = self.load_mapping_piece if label == "Piece" else None
            ttk.Spinbox(
                tab, from_=low, to=high, width=7, textvariable=variable, command=command
            ).grid(row=row, column=column + 1, sticky="w", pady=3)
        flags = ttk.Frame(tab)
        flags.grid(row=4, column=0, columnspan=6, sticky="w", pady=5)
        ttk.Checkbutton(flags, text="Priority", variable=self.mapping_priority).pack(side="left")
        ttk.Checkbutton(flags, text="H flip", variable=self.mapping_hflip).pack(side="left", padx=8)
        ttk.Checkbutton(flags, text="V flip", variable=self.mapping_vflip).pack(side="left")
        ttk.Button(flags, text="Update piece", command=self.update_mapping_piece).pack(side="left", padx=16)
        self.mapping_help = ttk.Label(tab)
        self.mapping_help.grid(row=5, column=0, columnspan=6, sticky="w")
        self.select_mapping()

    def _build_animations_tab(self, notebook: ttk.Notebook) -> None:
        tab = ttk.Frame(notebook, padding=8)
        notebook.add(tab, text="Animations")
        chooser = ttk.Combobox(
            tab, values=list(self.animations), textvariable=self.animation_id, state="readonly", width=42
        )
        chooser.grid(row=0, column=0, columnspan=4, sticky="w")
        chooser.bind("<<ComboboxSelected>>", lambda _event: self.select_animation())
        ttk.Label(tab, text="Delay").grid(row=1, column=0, sticky="e", pady=8)
        ttk.Spinbox(tab, from_=0, to=255, width=7, textvariable=self.animation_delay).grid(
            row=1, column=1, sticky="w", padx=4
        )
        ttk.Label(tab, text="Frame").grid(row=1, column=2, sticky="e")
        ttk.Spinbox(
            tab, from_=0, to=63, width=7, textvariable=self.animation_frame,
            command=self.load_animation_frame,
        ).grid(row=1, column=3, sticky="w", padx=4)
        ttk.Label(tab, text="Mapping / tilemap").grid(row=2, column=0, sticky="e")
        self.animation_mapping_chooser = ttk.Combobox(
            tab, textvariable=self.animation_mapping, state="readonly", width=42
        )
        self.animation_mapping_chooser.grid(row=2, column=1, columnspan=3, sticky="w", padx=4)
        ttk.Button(tab, text="Update frame", command=self.update_animation).grid(
            row=3, column=0, columnspan=2, sticky="w", pady=10
        )
        self.animation_help = ttk.Label(tab, wraplength=620)
        self.animation_help.grid(row=4, column=0, columnspan=4, sticky="w")
        self.select_animation()

    def selected_tile_asset(self) -> dict[str, Any]:
        return self.assets[self.tile_asset.get()]

    def select_tile_asset(self) -> None:
        self.tile_index.set(0)
        asset = self.selected_tile_asset()
        self.paint_color.set(min(self.paint_color.get(), 1 if asset["kind"] == "tiles_1bpp" else 15))
        self.refresh_tiles()

    def step_tile(self, delta: int) -> None:
        count = len(self.selected_tile_asset()["tiles"])
        self.tile_index.set((self.tile_index.get() + delta) % count)
        self.refresh_tiles()

    def refresh_tiles(self) -> None:
        asset = self.selected_tile_asset()
        index = max(0, min(len(asset["tiles"]) - 1, self.tile_index.get()))
        self.tile_index.set(index)
        maximum = 1 if asset["kind"] == "tiles_1bpp" else 15
        tile = asset["tiles"][index]
        self.tile_canvas.delete("all")
        for y, row in enumerate(tile):
            for x, pixel in enumerate(row):
                color = GENERIC_COLORS[pixel]
                self.tile_canvas.create_rectangle(
                    x * PIXEL, y * PIXEL, (x + 1) * PIXEL, (y + 1) * PIXEL,
                    fill=color, outline="#303030",
                )
        self.tile_label.configure(text=f"Tile {index + 1}/{len(asset['tiles'])}; indices 0..{maximum}")

    def set_pixel(self, event: tk.Event, value: int) -> None:
        x, y = event.x // PIXEL, event.y // PIXEL
        if not 0 <= x < 8 or not 0 <= y < 8:
            return
        asset = self.selected_tile_asset()
        maximum = 1 if asset["kind"] == "tiles_1bpp" else 15
        asset["tiles"][self.tile_index.get()][y][x] = max(0, min(maximum, value))
        self.refresh_tiles()

    def paint_pixel(self, event: tk.Event) -> None:
        self.set_pixel(event, self.paint_color.get())

    def erase_pixel(self, event: tk.Event) -> None:
        self.set_pixel(event, 0)

    def refresh_palette(self) -> None:
        self.palette_canvas.delete("all")
        entries = self.assets["sega_palette"]["entries"]
        for index, entry in enumerate(entries):
            self.palette_canvas.create_rectangle(
                index * 48, 0, (index + 1) * 48, 48,
                fill=md_color(entry["colour"]), outline="#ffffff",
            )
            self.palette_canvas.create_text(index * 48 + 24, 56, text=str(index))
        self.load_palette_entry()

    def select_palette_swatch(self, event: tk.Event) -> None:
        self.palette_entry.set(max(0, min(9, event.x // 48)))
        self.load_palette_entry()

    def load_palette_entry(self) -> None:
        entry = self.assets["sega_palette"]["entries"][self.palette_entry.get()]
        self.palette_index.set(entry["index"])
        self.palette_colour.set(f"${entry['colour']:03X}")

    def update_palette(self) -> None:
        try:
            colour = int(self.palette_colour.get().replace("$", "0x"), 0)
        except ValueError:
            messagebox.showerror("Invalid colour", "Use a value such as $0EEE")
            return
        entry = self.assets["sega_palette"]["entries"][self.palette_entry.get()]
        previous = dict(entry)
        entry["index"] = self.palette_index.get()
        entry["colour"] = colour
        try:
            validate_document(self.document, self.project)
        except ValueError as error:
            entry.clear()
            entry.update(previous)
            messagebox.showerror("Invalid palette", str(error))
            return
        self.refresh_palette()

    def refresh_screen(self) -> None:
        self.screen_canvas.delete("all")
        words = self.assets["sega_tilemap"]["words"]
        for index, word in enumerate(words):
            x, y = index % 12, index // 12
            self.screen_canvas.create_rectangle(
                x * 48, y * 48, (x + 1) * 48, (y + 1) * 48,
                fill="#263238", outline="#607d8b",
            )
            self.screen_canvas.create_text(
                x * 48 + 24, y * 48 + 24, text=f"{word:04X}", fill="#ffffff"
            )
        self.load_screen_word()

    def select_screen_cell(self, event: tk.Event) -> None:
        x, y = event.x // 48, event.y // 48
        self.screen_cell.set(max(0, min(47, y * 12 + x)))
        self.load_screen_word()

    def load_screen_word(self) -> None:
        word = self.assets["sega_tilemap"]["words"][self.screen_cell.get()]
        self.screen_word.set(f"${word:04X}")

    def update_screen_word(self) -> None:
        try:
            word = int(self.screen_word.get().replace("$", "0x"), 0)
        except ValueError:
            messagebox.showerror("Invalid tile word", "Use a value such as $002A")
            return
        self.assets["sega_tilemap"]["words"][self.screen_cell.get()] = word
        self.refresh_screen()

    def load_text(self) -> None:
        record = self.texts[self.text_id.get()]
        self.text_value.set(record["value"])
        self.text_help.configure(
            text=f"{record['source']} · {len(record['value'])}/{record['capacity']} ASCII bytes"
        )

    def update_text(self) -> None:
        record = self.texts[self.text_id.get()]
        previous = record["value"]
        record["value"] = self.text_value.get()
        try:
            validate_semantics(self.semantics, self.project)
        except ValueError as error:
            record["value"] = previous
            messagebox.showerror("Invalid text", str(error))
            return
        self.load_text()

    def refresh_game_palette(self) -> None:
        colours = self.game_palettes[self.game_palette_id.get()]["colours"]
        self.game_palette_entry.set(min(self.game_palette_entry.get(), len(colours) - 1))
        self.game_palette_canvas.delete("all")
        for index, colour in enumerate(colours):
            self.game_palette_canvas.create_rectangle(
                index * 40, 0, (index + 1) * 40, 40,
                fill=md_color(colour), outline="#ffffff",
            )
            self.game_palette_canvas.create_text(index * 40 + 20, 51, text=str(index))
        self.load_game_palette_entry()

    def select_game_palette_swatch(self, event: tk.Event) -> None:
        colours = self.game_palettes[self.game_palette_id.get()]["colours"]
        self.game_palette_entry.set(max(0, min(len(colours) - 1, event.x // 40)))
        self.load_game_palette_entry()

    def load_game_palette_entry(self) -> None:
        colours = self.game_palettes[self.game_palette_id.get()]["colours"]
        index = max(0, min(len(colours) - 1, self.game_palette_entry.get()))
        self.game_palette_entry.set(index)
        self.game_palette_colour.set(f"${colours[index]:03X}")

    def update_game_palette(self) -> None:
        try:
            colour = int(self.game_palette_colour.get().replace("$", "0x"), 0)
        except ValueError:
            messagebox.showerror("Invalid colour", "Use a value such as $0EEE")
            return
        colours = self.game_palettes[self.game_palette_id.get()]["colours"]
        index = self.game_palette_entry.get()
        previous = colours[index]
        colours[index] = colour
        try:
            validate_semantics(self.semantics, self.project)
        except ValueError as error:
            colours[index] = previous
            messagebox.showerror("Invalid palette", str(error))
            return
        self.refresh_game_palette()

    def select_mapping(self) -> None:
        self.mapping_piece.set(0)
        self.load_mapping_piece()

    def load_mapping_piece(self) -> None:
        mapping = self.mappings[self.mapping_id.get()]
        index = max(0, min(len(mapping["pieces"]) - 1, self.mapping_piece.get()))
        self.mapping_piece.set(index)
        piece = mapping["pieces"][index]
        self.mapping_x.set(piece["x"])
        self.mapping_flipped_x.set(piece["flipped_x"])
        self.mapping_y.set(piece["y"])
        self.mapping_width.set(piece["width"])
        self.mapping_height.set(piece["height"])
        self.mapping_tile.set(piece["tile"])
        self.mapping_palette.set(piece["palette"])
        self.mapping_priority.set(piece["priority"])
        self.mapping_hflip.set(piece["hflip"])
        self.mapping_vflip.set(piece["vflip"])
        self.mapping_help.configure(
            text=f"{mapping['source']} · piece {index + 1}/{len(mapping['pieces'])} · render flags ${mapping['render_flags']:02X}"
        )
        self.draw_mapping()

    def draw_mapping(self) -> None:
        canvas = self.mapping_canvas
        canvas.delete("all")
        center_x, center_y = 210, 140
        canvas.create_line(center_x, 0, center_x, 280, fill="#52616b")
        canvas.create_line(0, center_y, 420, center_y, fill="#52616b")
        mapping = self.mappings[self.mapping_id.get()]
        colors = ("#607d8b", "#4caf50", "#ff9800", "#ab47bc")
        for index, piece in enumerate(mapping["pieces"]):
            x = center_x + piece["x"]
            y = center_y + piece["y"]
            width, height = piece["width"] * 8, piece["height"] * 8
            canvas.create_rectangle(
                x, y, x + width, y + height,
                fill=colors[piece["palette"]],
                outline="#ffffff" if index == self.mapping_piece.get() else "#263238",
                width=2 if index == self.mapping_piece.get() else 1,
            )
            canvas.create_text(x + width / 2, y + height / 2, text=f"{piece['tile']:03X}")

    def update_mapping_piece(self) -> None:
        mapping = self.mappings[self.mapping_id.get()]
        index = self.mapping_piece.get()
        previous = dict(mapping["pieces"][index])
        mapping["pieces"][index] = {
            "x": self.mapping_x.get(),
            "flipped_x": self.mapping_flipped_x.get(),
            "y": self.mapping_y.get(),
            "width": self.mapping_width.get(),
            "height": self.mapping_height.get(),
            "tile": self.mapping_tile.get(),
            "palette": self.mapping_palette.get(),
            "priority": self.mapping_priority.get(),
            "hflip": self.mapping_hflip.get(),
            "vflip": self.mapping_vflip.get(),
        }
        try:
            validate_sequences(self.sequences, self.project)
        except ValueError as error:
            mapping["pieces"][index] = previous
            messagebox.showerror("Invalid mapping", str(error))
            return
        self.load_mapping_piece()

    def select_animation(self) -> None:
        animation = self.animations[self.animation_id.get()]
        self.animation_frame.set(0)
        self.animation_delay.set(animation["delay"])
        allowed = sorted({
            frame
            for candidate in self.animations.values()
            if candidate["kind"] == animation["kind"]
            for frame in candidate["frames"]
        })
        self.animation_mapping_chooser.configure(values=allowed)
        self.animation_help.configure(
            text=f"{animation['source']} · {animation['kind']} · {len(animation['frames'])} fixed frame slots"
        )
        self.load_animation_frame()

    def load_animation_frame(self) -> None:
        animation = self.animations[self.animation_id.get()]
        index = max(0, min(len(animation["frames"]) - 1, self.animation_frame.get()))
        self.animation_frame.set(index)
        self.animation_mapping.set(animation["frames"][index])

    def update_animation(self) -> None:
        animation = self.animations[self.animation_id.get()]
        previous = copy.deepcopy(animation)
        animation["delay"] = self.animation_delay.get()
        animation["frames"][self.animation_frame.get()] = self.animation_mapping.get()
        try:
            validate_sequences(self.sequences, self.project)
        except ValueError as error:
            animation.clear()
            animation.update(previous)
            messagebox.showerror("Invalid animation", str(error))
            return
        self.select_animation()

    def save(self) -> bool:
        try:
            validate_document(self.document, self.project)
            validate_semantics(self.semantics, self.project)
            validate_sequences(self.sequences, self.project)
            atomic_write_json(self.workspace, self.document)
            atomic_write_semantics(self.semantics_workspace, self.semantics)
            atomic_write_sequences(self.sequences_workspace, self.sequences)
        except (OSError, ValueError) as error:
            messagebox.showerror("Cannot save", str(error))
            return False
        self.saved = copy.deepcopy(self.document)
        self.saved_semantics = copy.deepcopy(self.semantics)
        self.saved_sequences = copy.deepcopy(self.sequences)
        self.status.set("Saved")
        return True

    def reload(self) -> None:
        self.document = load_document(self.workspace)
        validate_document(self.document, self.project)
        self.semantics = load_semantics(self.semantics_workspace)
        validate_semantics(self.semantics, self.project)
        self.sequences = load_sequences(self.sequences_workspace)
        validate_sequences(self.sequences, self.project)
        self.saved = copy.deepcopy(self.document)
        self.saved_semantics = copy.deepcopy(self.semantics)
        self.saved_sequences = copy.deepcopy(self.sequences)
        self.assets = asset_table(self.document)
        self.texts = {record["id"]: record for record in self.semantics["texts"]}
        self.game_palettes = {record["id"]: record for record in self.semantics["palettes"]}
        self.mappings = {record["id"]: record for record in self.sequences["mappings"]}
        self.animations = {record["id"]: record for record in self.sequences["animations"]}
        self.refresh_tiles()
        self.refresh_palette()
        self.refresh_screen()
        self.load_text()
        self.refresh_game_palette()
        self.select_mapping()
        self.select_animation()

    def build_rom(self) -> None:
        if not self.save():
            return
        subprocess.Popen(["make", "build-content"], cwd=self.project)
        self.status.set("Started make build-content")

    def close(self) -> None:
        dirty = (
            self.document != self.saved
            or self.semantics != self.saved_semantics
            or self.sequences != self.saved_sequences
        )
        if dirty and not messagebox.askyesno(
            "Unsaved changes", "Discard unsaved changes?"
        ):
            return
        self.root.destroy()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workspace", default="content/workspace/graphics/graphics.json")
    parser.add_argument("--semantics-workspace", default="content/workspace/graphics/semantics.json")
    parser.add_argument("--sequences-workspace", default="content/workspace/graphics/sequences.json")
    parser.add_argument("--check", action="store_true", help="validate without opening Tk")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[2]
    workspace = project / args.workspace
    semantics_workspace = project / args.semantics_workspace
    sequences_workspace = project / args.sequences_workspace
    document = load_document(workspace)
    validate_document(document, project)
    semantics = load_semantics(semantics_workspace)
    validate_semantics(semantics, project)
    sequences = load_sequences(sequences_workspace)
    validate_sequences(sequences, project)
    if args.check:
        print("[OK] Graphics Studio model loaded headlessly")
        return 0
    root = tk.Tk()
    GraphicsStudio(root, project, workspace, semantics_workspace, sequences_workspace)
    root.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
