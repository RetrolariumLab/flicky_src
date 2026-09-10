#!/usr/bin/env python3
"""Tkinter Level Studio for Flicky's round layouts and object placements."""

from __future__ import annotations

import argparse
import copy
import os
import subprocess
import tkinter as tk
from pathlib import Path
from tkinter import messagebox, ttk
from typing import Any

from authoring.level_preview import LevelPreview, SCREEN_HEIGHT, SCREEN_WIDTH, md_color
from authoring.level_studio_model import MAP_HEIGHT, MAP_WIDTH, atomic_write_json, load_document, validate_document
from authoring.studio_build import build_content_command, verify_emulator_command
from runtime.level_playtest import playtest_command, playtest_environment


SCALE = 2
CELL = 8 * SCALE
VARIABLE_FIELDS = (
    "background_group_3", "background_group_4", "background_group_5",
    "chicks_a", "chicks_b", "flag_7", "flag_7_6", "flag_5",
)
MAIN_FIELDS = (
    "player", "entry_arrow", "cat_door", "exit_door", "background_group_3",
    "background_group_4", "background_group_5", "spawners", "chicks_a", "chicks_b",
)
SPECIAL_FIELDS = ("flag_7", "flag_7_6", "flag_5")
COLORS = {
    "player": "#4fc3f7",
    "entry_arrow": "#ffffff",
    "cat_door": "#ef5350",
    "exit_door": "#66bb6a",
    "background_group_3": "#ab47bc",
    "background_group_4": "#7e57c2",
    "background_group_5": "#5c6bc0",
    "spawners": "#ffa726",
    "chicks_a": "#ffee58",
    "chicks_b": "#fdd835",
    "flag_7": "#26c6da",
    "flag_7_6": "#ec407a",
    "flag_5": "#9ccc65",
}
FIELD_LABELS = {
    "player": "Flicky / exit door",
    "entry_arrow": "background object A",
    "cat_door": "background object B",
    "exit_door": "background object C",
    "background_group_3": "background group 3",
    "background_group_4": "background group 4",
    "background_group_5": "background group 5",
    "spawners": "collectible / throwable chicks",
    "chicks_a": "enemies A",
    "chicks_b": "enemies B",
    "flag_7": "special collision 7",
    "flag_7_6": "special collision 7/6",
    "flag_5": "special collision 5",
}


class LevelStudio:
    def __init__(
        self,
        root: tk.Tk,
        project: Path,
        workspace: Path,
        graphics_workspace: Path,
        semantics_workspace: Path,
        sequences_workspace: Path,
    ):
        self.root = root
        self.project = project
        self.workspace = workspace
        self.document = load_document(workspace)
        validate_document(self.document, self.project)
        self.saved = copy.deepcopy(self.document)
        self.graphics_workspace = graphics_workspace
        self.semantics_workspace = semantics_workspace
        self.sequences_workspace = sequences_workspace
        self.preview = LevelPreview.load(
            project, graphics_workspace, semantics_workspace, sequences_workspace
        )
        self.preview_image: tk.PhotoImage | None = None
        self.preview_native: tk.PhotoImage | None = None
        self.playtest_process: subprocess.Popen[bytes] | None = None
        self.round_number = tk.IntVar(value=1)
        self.show_grid = tk.BooleanVar(value=False)
        self.show_markers = tk.BooleanVar(value=True)
        self.show_collision_flags = tk.BooleanVar(value=False)
        self.object_key: tuple[str, int | None, bool] | None = None
        self.x_value = tk.IntVar(value=0)
        self.y_value = tk.IntVar(value=0)
        self.status = tk.StringVar(value="Ready")
        self._build_ui()
        self.refresh()

    def _build_ui(self) -> None:
        self.root.title("Flicky Level Studio")
        self.root.protocol("WM_DELETE_WINDOW", self.close)
        toolbar = ttk.Frame(self.root, padding=6)
        toolbar.pack(fill="x")
        ttk.Label(toolbar, text="Round").pack(side="left")
        chooser = ttk.Spinbox(
            toolbar, from_=1, to=48, width=5, textvariable=self.round_number,
            command=self.refresh,
        )
        chooser.pack(side="left", padx=(4, 12))
        chooser.bind("<Return>", lambda _event: self.refresh())
        ttk.Button(toolbar, text="Save", command=self.save).pack(side="left")
        ttk.Button(toolbar, text="Reload", command=self.reload).pack(side="left", padx=4)
        ttk.Button(toolbar, text="Build ROM", command=self.build_rom).pack(side="left")
        ttk.Button(toolbar, text="Playtest", command=self.playtest).pack(side="left", padx=(4, 0))
        ttk.Button(toolbar, text="Stop", command=self.stop_playtest).pack(side="left", padx=4)
        self.layout_label = ttk.Label(toolbar)
        self.layout_label.pack(side="left", padx=14)
        ttk.Checkbutton(
            toolbar, text="Grid", variable=self.show_grid, command=self.redraw
        ).pack(side="left", padx=(4, 0))
        ttk.Checkbutton(
            toolbar, text="Objects", variable=self.show_markers, command=self.redraw
        ).pack(side="left")
        ttk.Checkbutton(
            toolbar, text="Collision flags", variable=self.show_collision_flags,
            command=self.redraw,
        ).pack(side="left", padx=(4, 0))

        body = ttk.Frame(self.root, padding=(6, 0, 6, 6))
        body.pack(fill="both", expand=True)
        self.canvas = tk.Canvas(
            body, width=SCREEN_WIDTH * SCALE, height=SCREEN_HEIGHT * SCALE,
            background="#101820", highlightthickness=0,
        )
        self.canvas.pack(side="left", fill="both", expand=False)
        self.canvas.bind("<Button-1>", self.toggle_collision)

        panel = ttk.Frame(body, padding=(8, 0, 0, 0))
        panel.pack(side="left", fill="both", expand=True)
        ttk.Label(panel, text="Objects and special collision").pack(anchor="w")
        self.objects = ttk.Treeview(panel, columns=("x", "y"), show="tree headings", height=22)
        self.objects.heading("#0", text="Object")
        self.objects.heading("x", text="X")
        self.objects.heading("y", text="Y")
        self.objects.column("#0", width=180)
        self.objects.column("x", width=42, anchor="center")
        self.objects.column("y", width=42, anchor="center")
        self.objects.pack(fill="both", expand=True, pady=(4, 6))
        self.objects.bind("<<TreeviewSelect>>", self.select_object)

        coordinates = ttk.Frame(panel)
        coordinates.pack(fill="x")
        ttk.Label(coordinates, text="X").pack(side="left")
        ttk.Spinbox(coordinates, from_=0, to=31, width=4, textvariable=self.x_value).pack(side="left")
        ttk.Label(coordinates, text="Y").pack(side="left", padx=(8, 0))
        ttk.Spinbox(coordinates, from_=0, to=31, width=4, textvariable=self.y_value).pack(side="left")
        ttk.Button(coordinates, text="Update", command=self.update_object).pack(side="left", padx=8)
        ttk.Button(coordinates, text="Add", command=self.add_object).pack(side="left")
        ttk.Button(coordinates, text="Remove", command=self.remove_object).pack(side="left", padx=4)
        ttk.Label(panel, textvariable=self.status, wraplength=300).pack(anchor="w", pady=(8, 0))

    def layouts(self) -> tuple[dict[str, Any], dict[str, Any]]:
        round_index = max(1, min(48, self.round_number.get())) - 1
        layout_index = self.document["round_layouts"][round_index]
        special_index = self.document["round_special_layouts"][round_index]
        return self.document["layouts"][layout_index], self.document["layouts"][special_index]

    def refresh(self) -> None:
        layout, special = self.layouts()
        round_index = max(1, min(48, self.round_number.get())) - 1
        layout_id = self.document["round_layouts"][round_index]
        special_id = self.document["round_special_layouts"][round_index]
        shared = self.document["round_layouts"].count(layout_id)
        self.layout_label.configure(
            text=f"Layout {layout_id}; special {special_id}; shared by {shared} round(s)"
        )
        self.draw(layout, special)
        self.fill_objects(layout, special)
        self.status.set(
            "Click the map to toggle collision; graphics use the editable workspace"
        )

    def redraw(self) -> None:
        layout, special = self.layouts()
        self.draw(layout, special)

    def draw(self, layout: dict[str, Any], special: dict[str, Any]) -> None:
        self.canvas.delete("all")
        round_number = max(1, min(48, self.round_number.get()))
        frame = self.preview.render(layout, round_number)
        native = tk.PhotoImage(width=SCREEN_WIDTH, height=SCREEN_HEIGHT)
        rows = " ".join(
            "{" + " ".join(md_color(colour) for colour in row) + "}" for row in frame
        )
        native.put(rows)
        self.preview_native = native
        self.preview_image = native.zoom(SCALE, SCALE)
        self.canvas.create_image(0, 0, image=self.preview_image, anchor="nw")

        if self.show_grid.get():
            for x in range(MAP_WIDTH + 1):
                self.canvas.create_line(x * CELL, 0, x * CELL, SCREEN_HEIGHT * SCALE, fill="#63727a")
            for y in range(MAP_HEIGHT + 1):
                self.canvas.create_line(0, y * CELL, SCREEN_WIDTH * SCALE, y * CELL, fill="#63727a")
        if self.show_markers.get():
            for field in MAIN_FIELDS:
                value = layout[field]
                pairs = [value] if field in {"player", "entry_arrow", "cat_door", "exit_door"} else value
                self.draw_markers(field, pairs)
        if self.show_collision_flags.get():
            for field in SPECIAL_FIELDS:
                self.draw_markers(field, special[field], inset=5, dashed=True)

        selected = self.selected_key()
        if selected is not None:
            field, index, special_owner = selected
            owner = special if special_owner else layout
            pair = owner[field] if index is None else owner[field][index]
            if self.marker_is_visible(pair):
                self.canvas.create_rectangle(
                    pair[0] * CELL + 1, pair[1] * CELL + 1,
                    (pair[0] + 1) * CELL - 1, (pair[1] + 1) * CELL - 1,
                    outline="#ffffff", width=3,
                )

    @staticmethod
    def marker_is_visible(pair: list[int]) -> bool:
        return 0 <= pair[0] < MAP_WIDTH and 0 <= pair[1] < MAP_HEIGHT

    def draw_markers(
        self,
        field: str,
        pairs: list[list[int]],
        inset: int = 2,
        dashed: bool = False,
    ) -> None:
        for index, (x, y) in enumerate(pairs):
            if not self.marker_is_visible([x, y]):
                continue
            self.canvas.create_rectangle(
                x * CELL + inset, y * CELL + inset,
                (x + 1) * CELL - inset, (y + 1) * CELL - inset,
                outline=COLORS[field], width=2, dash=(3, 2) if dashed else None,
            )
            if len(pairs) > 1 and not dashed:
                self.canvas.create_text(
                    x * CELL + 3, y * CELL + 2,
                    text=str(index + 1), fill="#ffffff", anchor="nw",
                    font=("TkDefaultFont", 7, "bold"),
                )

    def fill_objects(self, layout: dict[str, Any], special: dict[str, Any]) -> None:
        self.objects.delete(*self.objects.get_children())
        for field in MAIN_FIELDS + SPECIAL_FIELDS:
            owner = special if field in SPECIAL_FIELDS else layout
            value = owner[field]
            pairs = [value] if field in {"player", "entry_arrow", "cat_door", "exit_door"} else value
            parent = self.objects.insert(
                "", "end", text=FIELD_LABELS[field], open=False, tags=(f"group:{field}",)
            )
            for index, (x, y) in enumerate(pairs):
                fixed_pair = field in {"player", "entry_arrow", "cat_door", "exit_door"}
                item = self.objects.insert(
                    parent, "end", text=FIELD_LABELS[field] if fixed_pair else str(index + 1), values=(x, y)
                )
                special_owner = field in SPECIAL_FIELDS
                self.objects.item(item, tags=(f"{field}|{index if not fixed_pair else -1}|{int(special_owner)}",))

    def selected_key(self) -> tuple[str, int | None, bool] | None:
        selection = self.objects.selection()
        if not selection:
            return None
        tags = self.objects.item(selection[0], "tags")
        if not tags or "|" not in tags[0]:
            return None
        field, raw_index, raw_special = tags[0].split("|")
        index = int(raw_index)
        return field, None if index < 0 else index, bool(int(raw_special))

    def select_object(self, _event: Any = None) -> None:
        key = self.selected_key()
        if key is None:
            return
        field, index, special_owner = key
        layout, special = self.layouts()
        owner = special if special_owner else layout
        pair = owner[field] if index is None else owner[field][index]
        self.x_value.set(pair[0])
        self.y_value.set(pair[1])
        self.draw(layout, special)

    def toggle_collision(self, event: tk.Event) -> None:
        x, y = event.x // CELL, event.y // CELL
        if not (0 <= x < MAP_WIDTH and 2 <= y < MAP_HEIGHT):
            self.status.set("Collision is editable in rows 2..27; boundary rows are generated by the game")
            return
        layout, special = self.layouts()
        layout["collision"][y][x] = 1 - layout["collision"][y][x]
        self.draw(layout, special)

    def update_object(self) -> None:
        key = self.selected_key()
        if key is None:
            self.status.set("Select an object row first")
            return
        field, index, special_owner = key
        layout, special = self.layouts()
        owner = special if special_owner else layout
        pair = [self.x_value.get(), self.y_value.get()]
        if index is None:
            owner[field] = pair
        else:
            owner[field][index] = pair
        try:
            validate_document(self.document, self.project)
        except ValueError as error:
            self.document = copy.deepcopy(self.saved)
            messagebox.showerror("Invalid edit", str(error))
        self.refresh()

    def add_object(self) -> None:
        selection = self.objects.selection()
        if not selection:
            self.status.set("Select a variable object group first")
            return
        item = selection[0]
        key = self.selected_key()
        if key:
            field, _index, special_owner = key
        else:
            tags = self.objects.item(item, "tags")
            if not tags or not tags[0].startswith("group:"):
                self.status.set("Select a variable object group first")
                return
            field = tags[0].split(":", 1)[1]
            special_owner = field in SPECIAL_FIELDS
        if field not in VARIABLE_FIELDS:
            self.status.set(f"{field} has a fixed item count")
            return
        layout, special = self.layouts()
        owner = special if special_owner else layout
        owner[field].append([self.x_value.get(), self.y_value.get()])
        self.refresh()

    def remove_object(self) -> None:
        key = self.selected_key()
        if key is None:
            self.status.set("Select an object row first")
            return
        field, index, special_owner = key
        if field not in VARIABLE_FIELDS or index is None:
            self.status.set(f"{field} has a fixed item count")
            return
        layout, special = self.layouts()
        owner = special if special_owner else layout
        del owner[field][index]
        self.refresh()

    def save(self) -> bool:
        try:
            validate_document(self.document, self.project)
            atomic_write_json(self.workspace, self.document)
        except (OSError, ValueError) as error:
            messagebox.showerror("Cannot save", str(error))
            return False
        self.saved = copy.deepcopy(self.document)
        self.status.set(f"Saved {self.workspace}")
        return True

    def reload(self) -> None:
        self.document = load_document(self.workspace)
        validate_document(self.document, self.project)
        self.preview = LevelPreview.load(
            self.project,
            self.graphics_workspace,
            self.semantics_workspace,
            self.sequences_workspace,
        )
        self.saved = copy.deepcopy(self.document)
        self.refresh()

    def build_rom(self) -> None:
        if not self.save():
            return
        subprocess.Popen(self.content_build_command(), cwd=self.project)
        self.status.set("Started make build-content")

    def content_build_command(self) -> list[str]:
        return build_content_command(
            {
                "level_layouts": self.workspace,
                "graphics_assets": self.graphics_workspace,
                "graphics_semantics": self.semantics_workspace,
                "graphics_sequences": self.sequences_workspace,
            }
        )

    def playtest(self) -> None:
        if not self.save():
            return
        self.status.set("Building editable ROM for playtest...")
        self.root.update_idletasks()
        result = subprocess.run(self.content_build_command(), cwd=self.project)
        if result.returncode:
            messagebox.showerror("Build failed", "make build-content failed")
            self.status.set("Playtest build failed")
            return
        gens = Path(os.environ.get(
            "GENS_EXE", self.project / ".." / "gens_automation" / "Output" / "Gens.exe"
        )).resolve()
        if not gens.is_file():
            messagebox.showerror(
                "Gens not found",
                "Build ../gens_automation/Output/Gens.exe with make build-gens",
            )
            self.status.set("Gens not found")
            return
        verification = subprocess.run(verify_emulator_command(gens), cwd=self.project)
        if verification.returncode:
            messagebox.showerror(
                "Unapproved Gens build",
                "The selected Gens executable did not pass make verify-emulator",
            )
            self.status.set("Gens verification failed")
            return
        self.stop_playtest(update_status=False)
        round_number = max(1, min(48, self.round_number.get()))
        result_path = self.project / "build" / "level_playtest.txt"
        self.playtest_process = subprocess.Popen(
            playtest_command(gens, self.project / "build/content/flicky.bin"),
            cwd=gens.parent,
            env=playtest_environment(round_number, result_path),
        )
        self.status.set(f"Playtesting round {round_number} in Gens")

    def stop_playtest(self, update_status: bool = True) -> None:
        if self.playtest_process is not None and self.playtest_process.poll() is None:
            self.playtest_process.terminate()
            try:
                self.playtest_process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.playtest_process.kill()
            if update_status:
                self.status.set("Playtest stopped")
        elif update_status:
            self.status.set("No playtest is running")
        self.playtest_process = None

    def close(self) -> None:
        if self.document != self.saved and not messagebox.askyesno(
            "Unsaved changes", "Discard unsaved changes?"
        ):
            return
        self.stop_playtest(update_status=False)
        self.root.destroy()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workspace", default="content/workspace/level/levels.json")
    parser.add_argument("--graphics", default="content/workspace/graphics/graphics.json")
    parser.add_argument("--semantics", default="content/workspace/graphics/semantics.json")
    parser.add_argument("--sequences", default="content/workspace/graphics/sequences.json")
    parser.add_argument("--check", action="store_true", help="load and validate without opening Tk")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[2]
    workspace = project / args.workspace
    graphics_workspace = project / args.graphics
    semantics_workspace = project / args.semantics
    sequences_workspace = project / args.sequences
    document = load_document(workspace)
    validate_document(document, project)
    preview = LevelPreview.load(
        project, graphics_workspace, semantics_workspace, sequences_workspace
    )
    layout_index = document["round_layouts"][0]
    preview.render(document["layouts"][layout_index], 1)
    if args.check:
        print("[OK] Level Studio loaded real tiles, mappings, palettes, and round objects")
        return 0
    root = tk.Tk()
    LevelStudio(
        root, project, workspace,
        graphics_workspace, semantics_workspace, sequences_workspace,
    )
    root.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
