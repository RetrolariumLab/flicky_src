#!/usr/bin/env python3
"""Tkinter editor for Flicky's resident Z80 music and sound effects."""

from __future__ import annotations

import argparse
import copy
import subprocess
import threading
import tkinter as tk
from pathlib import Path
from tkinter import messagebox, ttk

from authoring import sound_studio_model as model
from authoring.sound_sequencer import SoundSequencer
from authoring.sound_vgm import write_vgm
from authoring.studio_build import build_content_command

try:
    import winsound
except ImportError:  # pragma: no cover - the supported Studio host is Windows
    winsound = None


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
        self.song_id = tk.StringVar(value=self.music_header_ids[0])
        self.sfx_id = tk.StringVar(value=self.sfx_header_ids[0])
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
        self.piano_note_index = -1
        self.note_pitch = tk.IntVar()
        self.note_duration = tk.IntVar(value=1)
        self.note_rest = tk.BooleanVar()
        self.note_help = tk.StringVar()
        self.voice_bank = tk.StringVar(value=next(iter(self.voice_banks)))
        self.voice_index = tk.IntVar(value=0)
        self.voice_algorithm = tk.IntVar()
        self.voice_feedback = tk.IntVar()
        self.operator_vars = [
            {name: tk.IntVar() for name in model.OPERATOR_FIELDS}
            for _operator in range(4)
        ]
        self.envelope_index = tk.IntVar(value=0)
        self.envelope_value = tk.StringVar()
        self.channel_vars: list[tk.BooleanVar] = []
        self.preview_generation = 0
        self._build_ui()

    def _index(self) -> None:
        self.headers = {item["id"]: item for item in self.document["headers"]}
        self.sequences = {item["id"]: item for item in self.document["sequences"]}
        self.voice_banks = {item["id"]: item for item in self.document["voice_banks"]}
        self.music_header_ids = [
            identifier for identifier, header in self.headers.items()
            if header["kind"] == "music"
        ]
        self.sfx_header_ids = [
            identifier for identifier, header in self.headers.items()
            if header["kind"] == "sfx"
        ]
        if not self.music_header_ids or not self.sfx_header_ids:
            raise ValueError("Sound Studio requires at least one song and one SFX")

    def _build_ui(self) -> None:
        self.root.title("Flicky Sound Studio")
        self.root.protocol("WM_DELETE_WINDOW", self.close)
        toolbar = ttk.Frame(self.root, padding=6)
        toolbar.pack(fill="x")
        ttk.Button(toolbar, text="Save", command=self.save).pack(side="left")
        ttk.Button(toolbar, text="Reload", command=self.reload).pack(side="left", padx=4)
        ttk.Button(toolbar, text="Build ROM", command=self.build_rom).pack(side="left")
        ttk.Label(toolbar, text="Song").pack(side="left", padx=(10, 2))
        self.song_box = ttk.Combobox(
            toolbar,
            values=self.music_header_ids,
            textvariable=self.song_id,
            state="readonly",
            width=20,
        )
        self.song_box.current(0)
        self.song_box.pack(side="left")
        self.song_box.bind(
            "<<ComboboxSelected>>",
            lambda _event: self.select_preview_header(self.song_id.get()),
        )
        ttk.Button(
            toolbar, text="Preview song", command=lambda: self.preview(self.song_id.get())
        ).pack(side="left", padx=(4, 0))
        ttk.Label(toolbar, text="SFX").pack(side="left", padx=(10, 2))
        self.sfx_box = ttk.Combobox(
            toolbar,
            values=self.sfx_header_ids,
            textvariable=self.sfx_id,
            state="readonly",
            width=20,
        )
        self.sfx_box.current(0)
        self.sfx_box.pack(side="left")
        self.sfx_box.bind(
            "<<ComboboxSelected>>",
            lambda _event: self.select_preview_header(self.sfx_id.get()),
        )
        ttk.Button(
            toolbar, text="Preview SFX", command=lambda: self.preview(self.sfx_id.get())
        ).pack(side="left", padx=(4, 0))
        ttk.Button(toolbar, text="Stop", command=self.stop_preview).pack(side="left", padx=4)
        ttk.Label(toolbar, textvariable=self.status).pack(side="left", padx=12)
        notebook = ttk.Notebook(self.root)
        notebook.pack(fill="both", expand=True, padx=6, pady=(0, 6))
        self._build_headers_tab(notebook)
        self._build_events_tab(notebook)
        self._build_voices_tab(notebook)
        self._build_envelopes_tab(notebook)

    def _spin(
        self,
        parent: ttk.Frame,
        row: int,
        column: int,
        label: str,
        variable: tk.Variable,
        maximum: int = 255,
    ) -> None:
        ttk.Label(parent, text=label).grid(row=row, column=column, sticky="e", padx=(6, 2), pady=3)
        ttk.Spinbox(parent, from_=0, to=maximum, width=7, textvariable=variable).grid(
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
        self.channel_frame = ttk.LabelFrame(tab, text="Preview channels", padding=5)
        self.channel_frame.grid(row=9, column=0, columnspan=4, sticky="ew", pady=(8, 0))
        self.select_header()

    def _build_events_tab(self, notebook: ttk.Notebook) -> None:
        tab = ttk.Frame(notebook, padding=8)
        notebook.add(tab, text="Piano roll")
        chooser = ttk.Combobox(tab, values=list(self.sequences), textvariable=self.sequence_id, state="readonly", width=36)
        chooser.grid(row=0, column=0, columnspan=2, sticky="w")
        chooser.bind("<<ComboboxSelected>>", lambda _event: self.refresh_piano_roll())
        canvas_frame = ttk.Frame(tab)
        canvas_frame.grid(row=1, column=0, columnspan=2, sticky="nsew", pady=6)
        self.piano_canvas = tk.Canvas(canvas_frame, width=820, height=390, background="#16191d")
        x_scroll = ttk.Scrollbar(canvas_frame, orient="horizontal", command=self.piano_canvas.xview)
        y_scroll = ttk.Scrollbar(canvas_frame, orient="vertical", command=self.piano_canvas.yview)
        self.piano_canvas.configure(xscrollcommand=x_scroll.set, yscrollcommand=y_scroll.set)
        self.piano_canvas.grid(row=0, column=0, sticky="nsew")
        y_scroll.grid(row=0, column=1, sticky="ns")
        x_scroll.grid(row=1, column=0, sticky="ew")
        canvas_frame.rowconfigure(0, weight=1)
        canvas_frame.columnconfigure(0, weight=1)
        controls = ttk.Frame(tab)
        controls.grid(row=2, column=0, sticky="w")
        self._spin(controls, 0, 0, "Pitch", self.note_pitch, 94)
        self._spin(controls, 0, 2, "Duration", self.note_duration, 127)
        ttk.Checkbutton(controls, text="Rest", variable=self.note_rest).grid(row=0, column=4, padx=8)
        ttk.Button(controls, text="Update note", command=self.update_piano_note).grid(row=0, column=5)
        ttk.Label(tab, textvariable=self.note_help, wraplength=760).grid(row=3, column=0, sticky="w")
        tab.rowconfigure(1, weight=1)
        tab.columnconfigure(0, weight=1)
        self.refresh_piano_roll()

    def _build_voices_tab(self, notebook: ttk.Notebook) -> None:
        tab = ttk.Frame(notebook, padding=8)
        notebook.add(tab, text="FM voices")
        chooser = ttk.Combobox(tab, values=list(self.voice_banks), textvariable=self.voice_bank, state="readonly", width=32)
        chooser.grid(row=0, column=0, columnspan=8, sticky="w")
        chooser.bind("<<ComboboxSelected>>", lambda _event: self.select_voice_bank())
        self._spin(tab, 1, 0, "Voice", self.voice_index)
        ttk.Button(tab, text="Load voice", command=self.refresh_voice).grid(row=1, column=2, sticky="w")
        global_frame = ttk.LabelFrame(tab, text="Voice routing", padding=5)
        global_frame.grid(row=2, column=0, columnspan=8, sticky="w", pady=6)
        self._spin(global_frame, 0, 0, "Algorithm", self.voice_algorithm, 7)
        self._spin(global_frame, 0, 2, "Feedback", self.voice_feedback, 7)

        operators = ttk.Frame(tab)
        operators.grid(row=3, column=0, columnspan=8, sticky="nsew")
        labels = (
            ("detune", "Detune", 7), ("multiple", "Multiple", 15),
            ("rate_scale", "Rate scale", 3), ("attack", "Attack", 31),
            ("amplitude_modulation", "AM", 1), ("decay_1", "Decay 1", 31),
            ("decay_2", "Decay 2", 31), ("sustain_level", "Sustain", 15),
            ("release", "Release", 15), ("total_level", "Total level", 127),
        )
        for operator, variables in enumerate(self.operator_vars):
            frame = ttk.LabelFrame(operators, text=f"Operator {operator + 1}", padding=4)
            frame.grid(row=0, column=operator, sticky="n", padx=(0, 5))
            for row, (name, label, maximum) in enumerate(labels):
                self._spin(frame, row, 0, label, variables[name], maximum)
        ttk.Button(tab, text="Update FM instrument", command=self.update_voice).grid(
            row=4, column=0, columnspan=2, sticky="w", pady=6
        )
        ttk.Label(
            tab,
            text="Parameters are decoded from the driver's native 25-byte YM2612 voice format.",
        ).grid(row=5, column=0, columnspan=8, sticky="w")
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
        header = self.headers[self.header_id.get()]
        if header["kind"] == "music":
            self.song_id.set(header["id"])
        else:
            self.sfx_id.set(header["id"])
        self.load_header_track()
        self.refresh_channels()

    def select_preview_header(self, header_id: str) -> None:
        """Open the sound selected in either preview dropdown for editing."""
        self.header_id.set(header_id)
        self.select_header()

    def refresh_channels(self) -> None:
        for child in self.channel_frame.winfo_children():
            child.destroy()
        self.channel_vars = []
        header = self.headers[self.header_id.get()]
        for index, track in enumerate(header["tracks"]):
            variable = tk.BooleanVar(value=True)
            self.channel_vars.append(variable)
            label = f"{index + 1}: {track['type']}"
            ttk.Checkbutton(self.channel_frame, text=label, variable=variable).grid(
                row=index // 4, column=index % 4, sticky="w", padx=(0, 12)
            )

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
        if hasattr(self, "piano_canvas"):
            self.sequence_id.set(track["sequence"])
            self.refresh_piano_roll()

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

    def refresh_piano_roll(self) -> None:
        data = self.sequences[self.sequence_id.get()]["bytes"]
        self.piano_notes = model.piano_roll_notes(data)
        self.piano_note_index = -1
        self.piano_canvas.delete("all")
        margin = 52
        tick_width = 5
        row_height = 8
        roll_height = 95 * row_height
        total_ticks = max((note["start"] + note["duration"] for note in self.piano_notes), default=32)
        roll_width = max(820, margin + total_ticks * tick_width + 20)
        for pitch in range(0, 95):
            y = (94 - pitch) * row_height
            if pitch % 12 == 0:
                self.piano_canvas.create_line(margin, y, roll_width, y, fill="#3d4650")
                self.piano_canvas.create_text(
                    margin - 5, y + 4, anchor="e", fill="#b8c0c8", text=f"{pitch:02d}"
                )
        for index, note in enumerate(self.piano_notes):
            x0 = margin + note["start"] * tick_width
            x1 = max(x0 + 3, x0 + note["duration"] * tick_width)
            pitch = note["note"] if note["note"] is not None else 0
            y0 = (94 - pitch) * row_height
            tag = f"piano-note-{index}"
            color = "#6f7780" if note["rest"] else "#45a3e5"
            self.piano_canvas.create_rectangle(
                x0, y0, x1, y0 + row_height - 1,
                fill=color, outline="#dceeff", tags=(tag, "piano-note"),
            )
            self.piano_canvas.tag_bind(tag, "<Button-1>", lambda _event, item=index: self.select_piano_note(item))
        self.piano_canvas.configure(scrollregion=(0, 0, roll_width, roll_height))
        commands = sum(event["name"] not in ("duration", "rest") and not event["name"].startswith("note_")
                       for event in model.describe_sequence(data))
        self.note_help.set(
            f"{len(self.piano_notes)} notes/rests · {commands} preserved driver commands. "
            "Click a block to edit pitch and duration."
        )

    def select_piano_note(self, index: int) -> None:
        self.piano_note_index = index
        note = self.piano_notes[index]
        self.note_pitch.set(note["note"] or 0)
        self.note_duration.set(note["duration"])
        self.note_rest.set(note["rest"])
        sharing = "shared inherited duration" if note["duration_is_shared"] else "own duration"
        self.note_help.set(f"Sequence offset ${note['offset']:04X}; {sharing}.")
        self.piano_canvas.itemconfigure("piano-note", outline="#dceeff", width=1)
        self.piano_canvas.itemconfigure(f"piano-note-{index}", outline="#ffe06a", width=2)

    def update_piano_note(self) -> None:
        if self.piano_note_index < 0:
            messagebox.showinfo("Choose note", "Click a piano-roll block first")
            return
        data = self.sequences[self.sequence_id.get()]["bytes"]
        note = self.piano_notes[self.piano_note_index]
        previous = list(data)
        try:
            pitch = self.note_pitch.get()
            duration = self.note_duration.get()
            if not 0 <= pitch <= 94 or not 1 <= duration <= 127:
                raise ValueError("pitch must be 0..94 and duration must be 1..127")
            data[note["offset"]] = 0x80 if self.note_rest.get() else 0x81 + pitch
            if note["duration_offset"] is None:
                if duration != note["duration"]:
                    raise ValueError("this first note has no editable duration byte")
            else:
                data[note["duration_offset"]] = duration
            model.validate_document(self.document, self.baseline)
        except (ValueError, tk.TclError) as error:
            data[:] = previous
            messagebox.showerror("Invalid note", str(error))
            return
        self.refresh_piano_roll()

    def select_voice_bank(self) -> None:
        self.voice_index.set(0)
        self.refresh_voice()

    def refresh_voice(self) -> None:
        bank = self.voice_banks[self.voice_bank.get()]
        index = max(0, min(len(bank["voices"]) - 1, self.voice_index.get()))
        self.voice_index.set(index)
        parameters = model.decode_fm_voice(bank["voices"][index])
        self.voice_algorithm.set(parameters["algorithm"])
        self.voice_feedback.set(parameters["feedback"])
        for variables, operator in zip(self.operator_vars, parameters["operators"]):
            for name, variable in variables.items():
                variable.set(operator[name])

    def update_voice(self) -> None:
        voice = self.voice_banks[self.voice_bank.get()]["voices"][self.voice_index.get()]
        previous = list(voice)
        try:
            parameters = {
                "algorithm": self.voice_algorithm.get(),
                "feedback": self.voice_feedback.get(),
                "operators": [
                    {name: variable.get() for name, variable in variables.items()}
                    for variables in self.operator_vars
                ],
            }
            voice[:] = model.encode_fm_voice(parameters, voice)
            model.validate_document(self.document, self.baseline)
        except (ValueError, tk.TclError) as error:
            voice[:] = previous
            messagebox.showerror("Invalid FM instrument", str(error))
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
        self.song_box.configure(values=self.music_header_ids)
        self.sfx_box.configure(values=self.sfx_header_ids)
        if self.song_id.get() not in self.music_header_ids:
            self.song_id.set(self.music_header_ids[0])
        if self.sfx_id.get() not in self.sfx_header_ids:
            self.sfx_id.set(self.sfx_header_ids[0])
        self.select_header()
        self.refresh_piano_roll()
        self.select_voice_bank()
        self.refresh_envelopes()
        self.status.set("Reloaded")

    def build_rom(self) -> None:
        if self.save():
            command = build_content_command({"z80_sound_banks": self.workspace})
            subprocess.Popen(command, cwd=self.project)
            self.status.set("Started make build-content")

    def preview(self, header_id: str) -> None:
        if self.header_id.get() != header_id:
            self.select_preview_header(header_id)
        renderer = self.project / "bin/windows_i386/ymfm_renderer.exe"
        if not renderer.is_file():
            messagebox.showerror(
                "Renderer not found",
                "Run make build-ymfm-renderer to create the standalone audio renderer",
            )
            return
        if winsound is None:
            messagebox.showerror("Preview unavailable", "WAV playback is currently supported on Windows")
            return

        enabled = {index for index, variable in enumerate(self.channel_vars) if variable.get()}
        if not enabled:
            messagebox.showinfo("No channels", "Enable at least one preview channel")
            return
        self.stop_preview()
        generation = self.preview_generation
        document = copy.deepcopy(self.document)
        output_dir = self.project / "build/sound_preview"
        vgm_path = output_dir / f"{header_id}.vgm"
        wav_path = output_dir / f"{header_id}.wav"
        self.status.set(f"Rendering {header_id}...")

        def worker() -> None:
            try:
                result = SoundSequencer(document, self.baseline).render(
                    header_id, seconds=30.0, enabled_channels=enabled
                )
                write_vgm(result, vgm_path)
                subprocess.run(
                    [str(renderer), str(vgm_path), str(wav_path)],
                    cwd=self.project,
                    check=True,
                    capture_output=True,
                    text=True,
                )
            except (OSError, subprocess.CalledProcessError, ValueError) as error:
                self.root.after(0, lambda: self._preview_failed(generation, str(error)))
                return
            self.root.after(0, lambda: self._preview_ready(generation, header_id, wav_path))

        threading.Thread(target=worker, daemon=True).start()

    def _preview_failed(self, generation: int, detail: str) -> None:
        if generation != self.preview_generation:
            return
        self.status.set("Preview failed")
        messagebox.showerror("Preview failed", detail)

    def _preview_ready(self, generation: int, header_id: str, wav_path: Path) -> None:
        if generation != self.preview_generation:
            return
        winsound.PlaySound(str(wav_path), winsound.SND_FILENAME | winsound.SND_ASYNC)
        self.status.set(f"Playing {header_id}")

    def stop_preview(self) -> None:
        self.preview_generation += 1
        if winsound is not None:
            winsound.PlaySound(None, winsound.SND_PURGE)
        self.status.set("Stopped")

    def close(self) -> None:
        if self.document != self.saved and not messagebox.askyesno("Unsaved changes", "Discard unsaved changes?"):
            return
        self.stop_preview()
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
