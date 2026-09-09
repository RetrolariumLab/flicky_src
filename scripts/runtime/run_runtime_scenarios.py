#!/usr/bin/env python3
"""Replay the tracked movies under the instrumented Gens build and capture frames."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"[ERROR] {message}", file=sys.stderr)
    raise SystemExit(1)


def sha1_of(path: Path) -> str:
    return hashlib.sha1(path.read_bytes()).hexdigest()


def check_inputs(spec: dict, rom: Path) -> None:
    """Refuse to capture against inputs the scenarios were not written for."""
    if not rom.is_file():
        fail(f"ROM not found: {rom}. Run 'make build' first.")
    actual = sha1_of(rom)
    if actual != spec["rom_sha1"]:
        fail(
            "the built ROM does not match the scenarios.\n"
            f"        expected SHA1 {spec['rom_sha1']}\n"
            f"        actual   SHA1 {actual}\n"
            "        Captures against a different build prove nothing."
        )
    for name, movie in spec["movies"].items():
        path = Path(movie["path"])
        if not path.is_file():
            fail(f"movie not found: {path}")
        if sha1_of(path) != movie["sha1"]:
            fail(f"movie {name} does not match the SHA-1 the scenarios pin")


def capture_provenance(gens: Path, rom: Path, scenarios: Path) -> dict:
    """Record which binaries produced a capture.

    The runtime gate verifies both the pinned source checkout and the approved
    executable hash before this runner starts. Recording the same hash here
    binds each capture to the exact binary that produced it.
    """
    return {
        "emulator": {
            "path": str(gens),
            "size": gens.stat().st_size,
            "sha256": hashlib.sha256(gens.read_bytes()).hexdigest(),
        },
        "rom": {"path": str(rom), "sha1": sha1_of(rom)},
        "scenarios": str(scenarios),
    }


def prune_to_window(directory: Path, first: int, last: int) -> tuple[int, int]:
    """Delete captures outside the scenario's frame range.

    A movie can only be replayed from its start, so the emulator writes every
    frame from zero up to `last_frame`. Only the window says anything about the
    scene the scenario names, and the rest is bulk: the girl-in-window scenario
    asserts 17 frames and would otherwise leave 1,679 on disk. Dropping them
    keeps a full capture around 100 MB instead of well over a gigabyte.
    """
    removed = freed = 0
    for path in directory.iterdir():
        if path.suffix not in (".png", ".genstate") or not path.stem.isdigit():
            continue
        if first <= int(path.stem) <= last:
            continue
        freed += path.stat().st_size
        path.unlink()
        removed += 1
    return removed, freed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scenarios", default="scenarios/runtime_scenarios.json")
    parser.add_argument("--gens", required=True, help="Path to the instrumented Gens build")
    parser.add_argument("--rom", default="fbuilt.bin")
    parser.add_argument("--output-dir", default="build/runtime")
    parser.add_argument("--only", help="Run one scenario id")
    args = parser.parse_args()

    spec = json.loads(Path(args.scenarios).read_text(encoding="utf-8"))
    if spec.get("schema_version") != 2:
        fail("unsupported scenarios schema_version")

    gens = Path(args.gens)
    if not gens.is_file():
        fail(
            f"instrumented Gens build not found: {gens}\n"
            "        Build it with 'make build-gens', which cross-compiles it in\n"
            "        Docker and needs no Visual Studio. Without the emulator this\n"
            "        evidence layer cannot run and no capture is produced."
        )

    check_inputs(spec, Path(args.rom))

    scenarios = spec["scenarios"]
    if args.only:
        scenarios = [s for s in scenarios if s["id"] == args.only]
        if not scenarios:
            fail(f"no scenario with id {args.only}")

    output_root = Path(args.output_dir)
    output_root.mkdir(parents=True, exist_ok=True)
    provenance = capture_provenance(gens, Path(args.rom), Path(args.scenarios))
    (output_root / "capture_info.json").write_text(
        json.dumps(provenance, indent=2) + "\n", encoding="utf-8", newline=""
    )
    print(f"[INFO] emulator sha256 {provenance['emulator']['sha256'][:16]}..., "
          f"recorded in {output_root / 'capture_info.json'}")

    capture = spec["capture"]
    failures = 0

    for scenario in scenarios:
        movie = spec["movies"][scenario["movie"]]
        target = output_root / scenario["id"]
        target.mkdir(parents=True, exist_ok=True)
        command = [
            str(gens),
            "-rom", args.rom,
            "-play", movie["path"],
            "-screenshot-interval", str(capture["interval"]),
            "-screenshot-dir", str(target),
            "-max-frames", str(scenario["last_frame"]),
            "-save-state-dumps",
            "-turbo",
            "-frameskip", str(capture["frameskip"]),
            "-nosound",
        ]
        print(f"[RUN] {scenario['id']}: frames {scenario['first_frame']}-{scenario['last_frame']}")
        result = subprocess.run(command)
        if result.returncode != 0:
            print(f"[ERROR] {scenario['id']}: emulator exited {result.returncode}", file=sys.stderr)
            failures += 1
            continue
        produced = sorted(target.glob("*.png"))
        if not produced:
            print(f"[ERROR] {scenario['id']}: no frames captured", file=sys.stderr)
            failures += 1
            continue

        removed, freed = prune_to_window(
            target, scenario["first_frame"], scenario["last_frame"]
        )
        kept = sorted(target.glob("*.png"))
        if not kept:
            print(f"[ERROR] {scenario['id']}: nothing captured inside frames "
                  f"{scenario['first_frame']}-{scenario['last_frame']}", file=sys.stderr)
            failures += 1
            continue
        note = f", dropped {removed} outside the window ({freed // (1024 * 1024)} MB)"
        print(f"[OK] {scenario['id']}: {len(kept)} frames in {target}{note}")

    if failures:
        print(f"[FAIL] {failures} scenario(s) did not capture", file=sys.stderr)
        return 1
    print(f"[OK] captured {len(scenarios)} scenario(s) into {output_root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
