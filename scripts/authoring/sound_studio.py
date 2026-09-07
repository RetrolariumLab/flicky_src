#!/usr/bin/env python3
"""Tkinter editor for Flicky's resident Z80 music and sound effects."""

from __future__ import annotations

import argparse
import copy
import subprocess
import tkinter as tk
from pathlib import Path
from tkinter import messagebox, ttk

from authoring import sound_studio_model as model


class SoundStudio:
    def __init__(self, root: tk.Tk, project: Path, workspace: Path):
        self.root = root
        self.project = project
        self.workspace = workspace
        self.baseline = project / model.SOURCE
        self.document = model.export_document(workspace)
        model.validate_document(self.document, self.baseline)
        self.saved = copy.deepcopy(self.document)
        self._index()
        self.status = tk.StringVar(value="Ready")
        self.header_id = tk.StringVar(value=next(iter(self.headers)))
        self.header_track = tk.IntVar(value=0)
        self.header_scale = tk.IntVar()
        self.header_tempo = tk.IntVar()
        self.track_sequence = tk.StringVar()
        self.track_transpose = tk.IntVar()
        self.track_volume = tk.IntVar()
        self.track_flags = tk.IntVar()
        self.track_channel = tk.IntVar()
        self.track_pitch_env = tk.IntVar()
        self.track_volume_env = tk.IntVar()
        self.sequence_id = tk.StringVar(value=next(iter(self.sequences)))
        self.sequence_byte = tk.IntVar(value=0)
        self.sequence_value = tk.StringVar()
        self.voice_bank = tk.StringVar(value=next(iter(self.voice_banks)))
        self.voice_index = tk.IntVar(value=0)
        self.voice_field = tk.IntVar(value=0)
        self.voice_value = tk.StringVar()
        self.envelope_index = tk.IntVar(value=0)
        self.envelope_value = tk.StringVar()
        self._build_ui()

    def _index(self) -> None:
        self.headers = {item["id"]: item for item in self.document["headers"]}
        self.sequences = {item["id"]: item for item in self.document["sequences"]}
        self.voice_banks = {item["id"]: item for item in self.document["voice_banks"]}

    def _build_ui(self) -> None:
        self.root.title("Flicky Sound Studio")
        self.root.protocol("WM_DELETE_WINDOW", self.close)
        toolbar = ttk.Frame(self.root, padding=6)
        toolbar.pack(fill="x")
        ttk.Button(toolbar, text="Save", command=self.save).pack(side="left")
        ttk.Button(toolbar, text="Reload", command=self.reload).pack(side="left", padx=4)
        ttk.Button(toolbar, text="Build ROM", command=self.build_rom).pack(side="left")
        ttk.Button(toolbar, text="Preview in Gens", command=self.preview).pack(side="left", padx=4)
        ttk.Label(toolbar, textvariable=self.status).pack(side="left", padx=12)
        notebook = ttk.Notebook(self.root)
        notebook.pack(fill="both", expand=True, padx=6, pady=(0, 6))
        self._build_headers_tab(notebook)
        self._build_events_tab(notebook)
        self._build_voices_tab(notebook)
        self._build_envelopes_tab(notebook)

    def _spin(self, parent: ttk.Frame, row: int, column: int, label: str, variable: tk.Variable) -> None:
        ttk.Label(parent, text=label).grid(row=row, column=column, sticky="e", padx=(6, 2), pady=3)
        ttk.Spinbox(parent, from_=0, to=255, width=7, textvariable=variable).grid(
            row=row, column=column + 1, sticky="w", pady=3
        )

    def _build_headers_tab(self, notebook: ttk.Notebook) -> None:
        tab = ttk.Frame(notebook, padding=8)
        notebook.add(tab, text="Songs and SFX")
        chooser = ttk.Combobox(tab, values=list(self.headers), textvariable=self.header_id, state="readonly", width=34)
        chooser.grid(row=0, column=0, columnspan=4, sticky="w")
        chooser.bind("<<ComboboxSelected>>", lambda _event: self.select_header())
        self._spin(tab, 1, 0, "Track", self.header_track)
        ttk.Button(tab, text="Load track", command=self.load_header_track).grid(row=1, column=2, sticky="w")
        self._spin(tab, 2, 0, "Scale", self.header_scale)
        self._spin(tab, 2, 2, "Tempo", self.header_tempo)
        ttk.Label(tab, text="Sequence").grid(row=3, column=0, sticky="e")
        self.header_sequence_chooser = ttk.Combobox(
            tab, values=list(self.sequences), textvariable=self.track_sequence, state="readonly", width=32
        )
        self.header_sequence_chooser.grid(row=3, column=1, columnspan=3, sticky="w")
        self._spin(tab, 4, 0, "Transpose", self.track_transpose)
        self._spin(tab, 4, 2, "Volume", self.track_volume)
        self._spin(tab, 5, 0, "Flags", self.track_flags)
        self._spin(tab, 5, 2, "Channel", self.track_channel)
        self._spin(tab, 6, 0, "Pitch envelope", self.track_pitch_env)
        self._spin(tab, 6, 2, "Volume envelope", self.track_volume_env)
        ttk.Button(tab, text="Update header / track", command=self.update_header).grid(
            row=7, column=0, columnspan=2, sticky="w", pady=8
        )
        self.header_help = ttk.Label(tab, wraplength=620)
        self.header_help.grid(row=8, column=0, columnspan=4, sticky="w")
        self.select_header()

    def _build_events_tab(self, notebook: ttk.Notebook) -> None:
        tab = ttk.Frame(notebook, padding=8)
        notebook.add(tab, text="Event streams")
        chooser = ttk.Combobox(tab, values=list(self.sequences), textvariable=self.sequence_id, state="readonly", width=36)
        chooser.pack(anchor="w")
        chooser.bind("<<ComboboxSelected>>", lambda _event: self.refresh_events())
        self.event_tree = ttk.Treeview(tab, columns=("offset", "bytes", "meaning"), show="headings", height=17)
        for column, width in (("offset", 70), ("bytes", 180), ("meaning", 280)):
            self.event_tree.heading(column, text=column.title())
            self.event_tree.column(column, width=width)
        self.event_tree.pack(fill="both", expand=True, pady=6)
        self.event_tree.bind("<<TreeviewSelect>>", self.select_event)
        controls = ttk.Frame(tab)
        controls.pack(anchor="w")
        ttk.Label(controls, text="Byte offset").pack(side="left")
        ttk.Spinbox(controls, from_=0, to=2048, width=7, textvariable=self.sequence_byte, command=self.load_sequence_byte).pack(side="left", padx=4)
        ttk.Label(controls, text="Value $00").pack(side="left")
        ttk.Entry(controls, width=8, textvariable=self.sequence_value).pack(side="left", padx=4)
        ttk.Button(controls, text="Update byte", command=self.update_sequence_byte).pack(side="left")
        self.refresh_events()

    def _build_voices_tab(self, notebook: ttk.Notebook) -> None:
        tab = ttk.Frame(notebook, padding=8)
        notebook.add(tab, text="FM voices")
        chooser = ttk.Combobox(tab, values=list(self.voice_banks), textvariable=self.voice_bank, state="readonly", width=32)
        chooser.grid(row=0, column=0, columnspan=4, sticky="w")
        chooser.bind("<<ComboboxSelected>>", lambda _event: self.select_voice_bank())
        self._spin(tab, 1, 0, "Voice", self.voice_index)
        ttk.Button(tab, text="Load voice", command=self.refresh_voice).grid(row=1, column=2, sticky="w")
        self.voice_tree = ttk.Treeview(tab, columns=("index", "field", "value"), show="headings", height=15)
        for column, width in (("index", 60), ("field", 300), ("value", 80)):
            self.voice_tree.heading(column, text=column.title())
            self.voice_tree.column(column, width=width)
        self.voice_tree.grid(row=2, column=0, columnspan=4, pady=6)
        self.voice_tree.bind("<<TreeviewSelect>>", self.select_voice_field)
        self._spin(tab, 3, 0, "Field", self.voice_field)
        ttk.Label(tab, text="Value $00").grid(row=3, column=2, sticky="e")
        ttk.Entry(tab, width=8, textvariable=self.voice_value).grid(row=3, column=3, sticky="w")
        ttk.Button(tab, text="Update register byte", command=self.update_voice).grid(row=4, column=0, columnspan=2, sticky="w", pady=6)
        self.select_voice_bank()

    def _build_envelopes_tab(self, notebook: ttk.Notebook) -> None:
        tab = ttk.Frame(notebook, padding=8)
        notebook.add(tab, text="Priorities / envelopes")
        self.envelope_list = tk.Listbox(tab, width=30, height=20, font=("Consolas", 10))
        self.envelope_list.pack(anchor="w")
        self.envelope_list.bind("<<ListboxSelect>>", self.select_envelope)
        controls = ttk.Frame(tab)
        controls.pack(anchor="w", pady=6)
        ttk.Label(controls, text="Offset").pack(side="left")
        ttk.Spinbox(controls, from_=0, to=62, width=6, textvariable=self.envelope_index, command=self.load_envelope).pack(side="left", padx=4)
        ttk.Label(controls, text="Value $00").pack(side="left")
        ttk.Entry(controls, width=8, textvariable=self.envelope_value).pack(side="left", padx=4)
        ttk.Button(controls, text="Update byte", command=self.update_envelope).pack(side="left")
        ttk.Label(tab, text="This 63-byte table is shared by SFX priorities and the driver's pitch/volume envelope indexes.", wraplength=620).pack(anchor="w")
        self.refresh_envelopes()

    @staticmethod
    def parse_byte(value: str) -> int:
        return int(value.replace("$", "0x"), 0)

    def select_header(self) -> None:
        self.header_track.set(0)
        self.load_header_track()

    def load_header_track(self) -> None:
        header = self.headers[self.header_id.get()]
        index = max(0, min(len(header["tracks"]) - 1, self.header_track.get()))
        self.header_track.set(index)
        track = header["tracks"][index]
        self.header_scale.set(header["scale"])
        self.header_tempo.set(header.get("tempo", 0))
        self.track_sequence.set(track["sequence"])
        self.track_transpose.set(track["transpose"])
        self.track_volume.set(track["volume"])
        self.track_flags.set(track.get("flags", 0))
        self.track_channel.set(track.get("channel", 0))
        self.track_pitch_env.set(track.get("pitch_envelope", 0))
        self.track_volume_env.set(track.get("volume_envelope", 0))
        self.header_help.configure(
            text=f"{header['kind']} · track {index + 1}/{len(header['tracks'])} · {track['type']} · voices {header['voices']}"
        )

    def update_header(self) -> None:
        header = self.headers[self.header_id.get()]
        previous = copy.deepcopy(header)
        track = header["tracks"][self.header_track.get()]
        header["scale"] = self.header_scale.get()
        if header["kind"] == "music":
            header["tempo"] = self.header_tempo.get()
        track["sequence"] = self.track_sequence.get()
        track["transpose"] = self.track_transpose.get()
        track["volume"] = self.track_volume.get()
        if track["type"] == "sfx":
            track["flags"] = self.track_flags.get()
            track["channel"] = self.track_channel.get()
        elif track["type"] == "psg":
            track["pitch_envelope"] = self.track_pitch_env.get()
            track["volume_envelope"] = self.track_volume_env.get()
        try:
            model.validate_document(self.document, self.baseline)
        except ValueError as error:
            header.clear()
            header.update(previous)
            messagebox.showerror("Invalid header", str(error))
            return
        self.load_header_track()

    def refresh_events(self) -> None:
        self.event_tree.delete(*self.event_tree.get_children())
        data = self.sequences[self.sequence_id.get()]["bytes"]
        for event in model.describe_sequence(data):
            values = " ".join(f"{value:02X}" for value in event["bytes"])
            self.event_tree.insert("", "end", iid=str(event["offset"]), values=(f"${event['offset']:04X}", values, event["name"]))
        self.sequence_byte.set(min(self.sequence_byte.get(), len(data) - 1))
        self.load_sequence_byte()

    def select_event(self, _event: tk.Event) -> None:
        selected = self.event_tree.selection()
        if selected:
            self.sequence_byte.set(int(selected[0]))
            self.load_sequence_byte()

    def load_sequence_byte(self) -> None:
        data = self.sequences[self.sequence_id.get()]["bytes"]
        index = max(0, min(len(data) - 1, self.sequence_byte.get()))
        self.sequence_byte.set(index)
        self.sequence_value.set(f"${data[index]:02X}")

    def update_sequence_byte(self) -> None:
        data = self.sequences[self.sequence_id.get()]["bytes"]
        index = self.sequence_byte.get()
        previous = data[index]
        try:
            data[index] = self.parse_byte(self.sequence_value.get())
            model.validate_document(self.document, self.baseline)
        except (ValueError, tk.TclError) as error:
            data[index] = previous
            messagebox.showerror("Invalid event byte", str(error))
            return
        self.refresh_events()

    def select_voice_bank(self) -> None:
        self.voice_index.set(0)
        self.refresh_voice()

    def refresh_voice(self) -> None:
        bank = self.voice_banks[self.voice_bank.get()]
        index = max(0, min(len(bank["voices"]) - 1, self.voice_index.get()))
        self.voice_index.set(index)
        self.voice_tree.delete(*self.voice_tree.get_children())
        for field, (name, value) in enumerate(zip(model.VOICE_FIELDS, bank["voices"][index])):
            self.voice_tree.insert("", "end", iid=str(field), values=(field, name, f"${value:02X}"))
        self.voice_field.set(min(self.voice_field.get(), 24))
        self.load_voice_field()

    def select_voice_field(self, _event: tk.Event) -> None:
        selected = self.voice_tree.selection()
        if selected:
            self.voice_field.set(int(selected[0]))
            self.load_voice_field()

    def load_voice_field(self) -> None:
        bank = self.voice_banks[self.voice_bank.get()]
        value = bank["voices"][self.voice_index.get()][self.voice_field.get()]
        self.voice_value.set(f"${value:02X}")

    def update_voice(self) -> None:
        voice = self.voice_banks[self.voice_bank.get()]["voices"][self.voice_index.get()]
        field = self.voice_field.get()
        previous = voice[field]
        try:
            voice[field] = self.parse_byte(self.voice_value.get())
            model.validate_document(self.document, self.baseline)
        except (ValueError, tk.TclError) as error:
            voice[field] = previous
            messagebox.showerror("Invalid voice byte", str(error))
            return
        self.refresh_voice()

    def refresh_envelopes(self) -> None:
        self.envelope_list.delete(0, "end")
        for index, value in enumerate(self.document["priority_envelopes"]):
            self.envelope_list.insert("end", f"${index:02X}  ${value:02X}")
        self.load_envelope()

    def select_envelope(self, _event: tk.Event) -> None:
        selected = self.envelope_list.curselection()
        if selected:
            self.envelope_index.set(selected[0])
            self.load_envelope()

    def load_envelope(self) -> None:
        index = max(0, min(62, self.envelope_index.get()))
        self.envelope_index.set(index)
        self.envelope_value.set(f"${self.document['priority_envelopes'][index]:02X}")

    def update_envelope(self) -> None:
        index = self.envelope_index.get()
        previous = self.document["priority_envelopes"][index]
        try:
            self.document["priority_envelopes"][index] = self.parse_byte(self.envelope_value.get())
            model.validate_document(self.document, self.baseline)
        except (ValueError, tk.TclError) as error:
            self.document["priority_envelopes"][index] = previous
            messagebox.showerror("Invalid envelope byte", str(error))
            return
        self.refresh_envelopes()

    def save(self) -> bool:
        try:
            model.apply_document(self.document, self.baseline, self.workspace)
        except (OSError, ValueError) as error:
            messagebox.showerror("Cannot save", str(error))
            return False
        self.document = model.export_document(self.workspace)
        self.saved = copy.deepcopy(self.document)
        self._index()
        self.status.set("Saved")
        return True

    def reload(self) -> None:
        self.document = model.export_document(self.workspace)
        model.validate_document(self.document, self.baseline)
        self.saved = copy.deepcopy(self.document)
        self._index()
        self.select_header()
        self.refresh_events()
        self.select_voice_bank()
        self.refresh_envelopes()
        self.status.set("Reloaded")

    def build_rom(self) -> None:
        if self.save():
            subprocess.Popen(["make", "build-content"], cwd=self.project)
            self.status.set("Started make build-content")

    def preview(self) -> None:
        if not self.save():
            return
        result = subprocess.run(["make", "build-content"], cwd=self.project)
        if result.returncode:
            messagebox.showerror("Build failed", "make build-content failed")
            return
        gens = (self.project / ".." / "gens_automation" / "Output" / "Gens.exe").resolve()
        if not gens.is_file():
            messagebox.showerror("Gens not found", "Build ../gens_automation/Output/Gens.exe with make build-gens")
            return
        subprocess.Popen([str(gens), "-rom", str(self.project / "build/content/flicky.bin")], cwd=gens.parent)
        self.status.set("Preview launched in Gens")

    def close(self) -> None:
        if self.document != self.saved and not messagebox.askyesno("Unsaved changes", "Discard unsaved changes?"):
            return
        self.root.destroy()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workspace", default="content/workspace/sound/z80_sound_data.asm")
    parser.add_argument("--check", action="store_true", help="validate without opening Tk")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[2]
    workspace = project / args.workspace
    document = model.export_document(workspace)
    model.validate_document(document, project / model.SOURCE)
    if args.check:
        print(
            f"[OK] Sound Studio model loaded: {len(document['headers'])} headers, "
            f"{len(document['sequences'])} sequences, "
            f"{sum(len(bank['voices']) for bank in document['voice_banks'])} FM voices"
        )
        return 0
    root = tk.Tk()
    SoundStudio(root, project, workspace)
    root.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
