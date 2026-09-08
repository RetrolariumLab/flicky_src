#!/usr/bin/env python3
"""Capture a bounded Z80 chip-register trace with instrumented Gens."""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


def require_file(path: Path, description: str) -> None:
    if not path.is_file():
        raise FileNotFoundError(f"{description} not found: {path}")


def capture(
    gens: Path,
    rom: Path,
    movie: Path,
    config: Path,
    trace: Path,
    frames: Path,
    *,
    start_frame: int,
    end_frame: int,
) -> None:
    for path, description in (
        (gens, "instrumented Gens executable"),
        (rom, "built ROM"),
        (movie, "input movie"),
        (config, "sound trace configuration"),
    ):
        require_file(path, description)
    if start_frame < 0 or end_frame < start_frame:
        raise ValueError("sound trace frame range is invalid")

    trace.parent.mkdir(parents=True, exist_ok=True)
    frames.mkdir(parents=True, exist_ok=True)
    runtime_config = trace.parent / "Gens.sound-trace.cfg"
    shutil.copyfile(config, runtime_config)
    trace.unlink(missing_ok=True)

    command = [
        str(gens.resolve()),
        "-cfg", str(runtime_config.resolve()),
        "-rom", str(rom.resolve()),
        "-play", str(movie.resolve()),
        "-sound-trace", str(trace.resolve()),
        "-sound-start-frame", str(start_frame),
        "-sound-end-frame", str(end_frame),
        # Gens' automation frame limit is serviced by its screenshot path.
        "-screenshot-interval", "1000",
        "-screenshot-dir", str(frames.resolve()),
        # Gens has separate movie, rendered-frame, and public FrameCount
        # counters.  The established 1000-frame automation boundary reliably
        # carries FrameCount past this title-screen window on every run; the
        # sound hook itself stops recording at end_frame.
        "-max-frames", "1000",
        "-turbo",
        "-frameskip", "8",
    ]
    print(f"[RUN] {subprocess.list2cmdline(command)}")
    result = subprocess.run(command)
    if result.returncode:
        raise RuntimeError(f"Gens sound trace exited with {result.returncode}")
    require_file(trace, "sound register trace")
    if trace.stat().st_size <= len("sequence,frame,chip,port,address,value\n"):
        raise RuntimeError("Gens produced an empty sound register trace")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gens", type=Path, required=True)
    parser.add_argument("--rom", type=Path, default=Path("fbuilt.bin"))
    parser.add_argument("--movie", type=Path, default=Path("movies/flicky_longplay.gmv"))
    parser.add_argument("--config", type=Path, default=Path("config/gens_sound_trace.cfg"))
    parser.add_argument("--trace", type=Path, default=Path("build/sound_trace/gens.csv"))
    parser.add_argument("--frames", type=Path, default=Path("build/sound_trace/frames"))
    parser.add_argument("--start-frame", type=int, default=320)
    parser.add_argument("--end-frame", type=int, default=457)
    args = parser.parse_args()
    try:
        capture(
            args.gens, args.rom, args.movie, args.config, args.trace, args.frames,
            start_frame=args.start_frame, end_frame=args.end_frame,
        )
    except (OSError, RuntimeError, ValueError) as error:
        print(f"[ERROR] {error}", file=sys.stderr)
        return 1
    print(
        f"[OK] captured Z80 sound writes for frames "
        f"{args.start_frame}-{args.end_frame} in {args.trace}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
