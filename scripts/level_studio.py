#!/usr/bin/env python3
"""Tkinter Level Studio for Flicky's round layouts and object placements."""

from __future__ import annotations

import argparse
import copy
import subprocess
import tkinter as tk
from pathlib import Path
from tkinter import messagebox, ttk
from typing import Any

from level_studio_model import MAP_HEIGHT, MAP_WIDTH, atomic_write_json, load_document, validate_document


CELL = 18
WORLD_HEIGHT = 32
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


class LevelStudio:
    def __init__(self, root: tk.Tk, project: Path, workspace: Path):
        self.root = root
        self.project = project
        self.workspace = workspace
        self.document = load_document(workspace)
        validate_document(self.document)
        self.saved = copy.deepcopy(self.document)
        self.round_number = tk.IntVar(value=1)
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
        self.layout_label = ttk.Label(toolbar)
        self.layout_label.pack(side="left", padx=14)

        body = ttk.Frame(self.root, padding=(6, 0, 6, 6))
        body.pack(fill="both", expand=True)
        self.canvas = tk.Canvas(
            body, width=MAP_WIDTH * CELL, height=WORLD_HEIGHT * CELL,
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
        self.status.set("Click the grid to toggle collision; shared layouts update every linked round")

    def draw(self, layout: dict[str, Any], special: dict[str, Any]) -> None:
        self.canvas.delete("all")
        grid = layout["collision"]
        for y in range(WORLD_HEIGHT):
            for x in range(MAP_WIDTH):
                solid = y < MAP_HEIGHT and grid[y][x]
                fill = "#455a64" if solid else ("#17242d" if y < MAP_HEIGHT else "#0b1116")
                self.canvas.create_rectangle(
                    x * CELL, y * CELL, (x + 1) * CELL, (y + 1) * CELL,
                    fill=fill, outline="#26343d",
                )
        for field in MAIN_FIELDS:
            value = layout[field]
            pairs = [value] if field in {"player", "entry_arrow", "cat_door", "exit_door"} else value
            self.draw_markers(field, pairs)
        for field in SPECIAL_FIELDS:
            self.draw_markers(field, special[field], inset=5)

    def draw_markers(self, field: str, pairs: list[list[int]], inset: int = 3) -> None:
        for index, (x, y) in enumerate(pairs):
            self.canvas.create_oval(
                x * CELL + inset, y * CELL + inset,
                (x + 1) * CELL - inset, (y + 1) * CELL - inset,
                fill=COLORS[field], outline="",
            )
            if len(pairs) > 1 and inset < 5:
                self.canvas.create_text(
                    x * CELL + CELL // 2, y * CELL + CELL // 2,
                    text=str(index + 1), fill="#101010", font=("TkDefaultFont", 7),
                )

    def fill_objects(self, layout: dict[str, Any], special: dict[str, Any]) -> None:
        self.objects.delete(*self.objects.get_children())
        for field in MAIN_FIELDS + SPECIAL_FIELDS:
            owner = special if field in SPECIAL_FIELDS else layout
            value = owner[field]
            pairs = [value] if field in {"player", "entry_arrow", "cat_door", "exit_door"} else value
            parent = self.objects.insert("", "end", text=field, open=False)
            for index, (x, y) in enumerate(pairs):
                fixed_pair = field in {"player", "entry_arrow", "cat_door", "exit_door"}
                item = self.objects.insert(
                    parent, "end", text=field if fixed_pair else str(index + 1), values=(x, y)
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
            validate_document(self.document)
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
            field = self.objects.item(item, "text")
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

    def save(self) -> None:
        try:
            validate_document(self.document)
            atomic_write_json(self.workspace, self.document)
        except (OSError, ValueError) as error:
            messagebox.showerror("Cannot save", str(error))
            return
        self.saved = copy.deepcopy(self.document)
        self.status.set(f"Saved {self.workspace}")

    def reload(self) -> None:
        self.document = load_document(self.workspace)
        validate_document(self.document)
        self.saved = copy.deepcopy(self.document)
        self.refresh()

    def build_rom(self) -> None:
        self.save()
        subprocess.Popen(["make", "build-content"], cwd=self.project)
        self.status.set("Started make build-content")

    def close(self) -> None:
        if self.document != self.saved and not messagebox.askyesno(
            "Unsaved changes", "Discard unsaved changes?"
        ):
            return
        self.root.destroy()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workspace", default="content/workspace/level/levels.json")
    parser.add_argument("--check", action="store_true", help="load and validate without opening Tk")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    workspace = project / args.workspace
    document = load_document(workspace)
    validate_document(document)
    if args.check:
        print("[OK] Level Studio model loaded headlessly")
        return 0
    root = tk.Tk()
    LevelStudio(root, project, workspace)
    root.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
