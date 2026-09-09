#!/usr/bin/env python3
"""Exercise the public actions of all three Tk Studios on a real Tk runtime."""

from __future__ import annotations

import shutil
import subprocess
import tempfile
import tkinter as tk
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from authoring import graphics_studio, level_studio, sound_studio


class ProcessStub:
    """Record a launched adapter without starting a second build or emulator."""

    def __init__(self, *args, **kwargs):
        self.args = args
        self.kwargs = kwargs
        self.running = True

    def poll(self) -> int | None:
        return None if self.running else 0

    def terminate(self) -> None:
        self.running = False

    def wait(self, timeout: int | None = None) -> int:
        self.running = False
        return 0

    def kill(self) -> None:
        self.running = False


class ThreadStub:
    """Stop asynchronous preview at its already-tested worker boundary."""

    starts = 0

    def __init__(self, target, daemon: bool = False):
        self.target = target
        self.daemon = daemon

    def start(self) -> None:
        type(self).starts += 1


class WinSoundStub:
    SND_FILENAME = 1
    SND_ASYNC = 2
    SND_PURGE = 4

    @staticmethod
    def PlaySound(_path, _flags) -> None:
        return None


def walk_widgets(widget: tk.Misc):
    for child in widget.winfo_children():
        yield child
        yield from walk_widgets(child)


def invoke_button(root: tk.Tk, label: str) -> None:
    matches = []
    for widget in walk_widgets(root):
        try:
            if widget.winfo_class() == "TButton" and widget.cget("text") == label:
                matches.append(widget)
        except tk.TclError:
            continue
    if len(matches) != 1:
        raise RuntimeError(f"expected one {label!r} button, found {len(matches)}")
    matches[0].invoke()
    root.update_idletasks()


def window_exists(root: tk.Tk) -> bool:
    try:
        return bool(root.winfo_exists())
    except tk.TclError:
        return False


def exercise_dirty_close(app, messagebox_module) -> None:
    app.document["_workstation_smoke_dirty"] = True
    with patch.object(
        messagebox_module, "askyesno", side_effect=(False, True)
    ) as confirm:
        app.close()
        if not window_exists(app.root):
            raise RuntimeError("dirty-close cancellation destroyed the Studio window")
        app.close()
        if window_exists(app.root):
            raise RuntimeError("dirty-close confirmation left the Studio window open")
    if confirm.call_count != 2:
        raise RuntimeError("dirty-close confirmation was not requested twice")


def make_root() -> tk.Tk:
    try:
        root = tk.Tk()
    except tk.TclError as error:
        raise RuntimeError(f"Tk workstation is unavailable: {error}") from error
    root.withdraw()
    return root


def smoke_level(project: Path, workspace: Path) -> None:
    root = make_root()
    process = ProcessStub()
    with (
        patch.object(level_studio.subprocess, "Popen", return_value=process) as popen,
        patch.object(
            level_studio.subprocess,
            "run",
            return_value=SimpleNamespace(returncode=0),
        ) as run,
    ):
        app = level_studio.LevelStudio(
            root,
            project,
            workspace / "level/levels.json",
            workspace / "graphics/graphics.json",
            workspace / "graphics/semantics.json",
            workspace / "graphics/sequences.json",
        )
        root.update()
        invoke_button(root, "Save")
        invoke_button(root, "Build ROM")
        invoke_button(root, "Playtest")
        invoke_button(root, "Stop")
        if popen.call_count != 2 or run.call_count != 1:
            raise RuntimeError("Level Studio did not reach build and playtest adapters")
        exercise_dirty_close(app, level_studio.messagebox)
    print("[OK] Level Studio Save, Build ROM, Playtest, Stop, and dirty-close actions")


def smoke_graphics(project: Path, workspace: Path) -> None:
    root = make_root()
    with patch.object(graphics_studio.subprocess, "Popen") as popen:
        app = graphics_studio.GraphicsStudio(
            root,
            project,
            workspace / "graphics/graphics.json",
            workspace / "graphics/semantics.json",
            workspace / "graphics/sequences.json",
        )
        root.update()
        invoke_button(root, "Save")
        invoke_button(root, "Build ROM")
        if popen.call_count != 1:
            raise RuntimeError("Graphics Studio did not reach the build adapter")
        exercise_dirty_close(app, graphics_studio.messagebox)
    print("[OK] Graphics Studio Save, Build ROM, and dirty-close actions")


def smoke_sound(project: Path, workspace: Path) -> None:
    root = make_root()
    ThreadStub.starts = 0
    with (
        patch.object(sound_studio.subprocess, "Popen") as popen,
        patch.object(sound_studio.threading, "Thread", ThreadStub),
        patch.object(sound_studio, "winsound", WinSoundStub),
    ):
        app = sound_studio.SoundStudio(
            root, project, workspace / "sound/z80_sound_data.asm"
        )
        root.update()
        invoke_button(root, "Save")
        invoke_button(root, "Build ROM")
        invoke_button(root, "Preview song")
        invoke_button(root, "Preview SFX")
        invoke_button(root, "Stop")
        if popen.call_count != 1 or ThreadStub.starts != 2:
            raise RuntimeError("Sound Studio did not reach build and preview adapters")
        exercise_dirty_close(app, sound_studio.messagebox)
    print("[OK] Sound Studio Save, Build ROM, previews, Stop, and dirty-close actions")


def main() -> int:
    project = Path(__file__).resolve().parents[2]
    source = project / "content/workspace"
    if not source.is_dir():
        raise SystemExit("content workspace is missing; run make init-content")
    with tempfile.TemporaryDirectory(prefix="flicky-studio-smoke-") as directory:
        workspace = Path(directory) / "workspace"
        shutil.copytree(source, workspace)
        smoke_level(project, workspace)
        smoke_graphics(project, workspace)
        smoke_sound(project, workspace)
    print("[OK] all Tk Studio workstation interactions passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
