#!/usr/bin/env python3
"""Render a Flicky song or sound effect to VGM and WAV without an emulator."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

from authoring import sound_studio_model
from authoring.sound_sequencer import SoundSequencer
from authoring.sound_vgm import write_vgm


def render_preview(
    project: Path,
    workspace: Path,
    header_id: str,
    vgm_path: Path,
    wav_path: Path | None,
    *,
    seconds: float = 30.0,
    enabled_channels: set[int] | None = None,
    renderer: Path | None = None,
) -> tuple[Path, Path | None]:
    baseline = project / sound_studio_model.SOURCE
    sequencer = SoundSequencer.from_source(workspace, baseline)
    result = sequencer.render(
        header_id,
        seconds=seconds,
        enabled_channels=enabled_channels,
    )
    write_vgm(result, vgm_path)

    if wav_path is not None:
        if renderer is None:
            renderer = project / "bin/windows_i386/ymfm_renderer.exe"
        if not renderer.is_file():
            raise FileNotFoundError(
                f"offline renderer not found: {renderer}; run make build-ymfm-renderer"
            )
        wav_path.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(
            [str(renderer), str(vgm_path), str(wav_path)],
            cwd=project,
            check=True,
        )
    return vgm_path, wav_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("header", help="resident header id, for example zMusic81Header")
    parser.add_argument(
        "--workspace",
        default="content/workspace/sound/z80_sound_data.asm",
        help="editable sound-data assembly source",
    )
    parser.add_argument("--vgm", default="build/sound_preview.vgm")
    parser.add_argument("--wav", default="build/sound_preview.wav")
    parser.add_argument("--renderer", default="bin/windows_i386/ymfm_renderer.exe")
    parser.add_argument("--seconds", type=float, default=30.0)
    parser.add_argument(
        "--channels",
        help="comma-separated zero-based track indexes; default renders every track",
    )
    parser.add_argument("--vgm-only", action="store_true")
    args = parser.parse_args()

    project = Path(__file__).resolve().parents[2]
    workspace = project / args.workspace
    enabled = None
    if args.channels is not None:
        enabled = {int(value) for value in args.channels.split(",") if value.strip()}
    vgm_path = (project / args.vgm).resolve()
    wav_path = None if args.vgm_only else (project / args.wav).resolve()
    renderer = (project / args.renderer).resolve()
    try:
        render_preview(
            project,
            workspace,
            args.header,
            vgm_path,
            wav_path,
            seconds=args.seconds,
            enabled_channels=enabled,
            renderer=renderer,
        )
    except (OSError, subprocess.CalledProcessError, ValueError) as error:
        print(f"[FAIL] {error}", file=sys.stderr)
        return 1

    detail = f"VGM {vgm_path}"
    if wav_path is not None:
        detail += f"; WAV {wav_path}"
    print(f"[OK] rendered {args.header}: {detail}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
