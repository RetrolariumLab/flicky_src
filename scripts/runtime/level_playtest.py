#!/usr/bin/env python3
"""Launch an editable Flicky ROM directly in a selected round."""

from __future__ import annotations

import argparse
import os
import subprocess
import time
from pathlib import Path


SCRIPT = Path(__file__).with_suffix(".lua")


def validate_round_number(round_number: int) -> int:
    if not 1 <= round_number <= 48:
        raise ValueError("round number must be from 1 through 48")
    return round_number


def round_word(round_number: int) -> int:
    """Return the game's packed BCD-display/plain-index round word."""
    validate_round_number(round_number)
    bcd = (round_number // 10) * 0x10 + round_number % 10
    return bcd << 8 | round_number


def playtest_environment(
    round_number: int,
    result: Path | None = None,
    *,
    exit_when_ready: bool = False,
) -> dict[str, str]:
    environment = os.environ.copy()
    environment["FLICKY_PLAYTEST_ROUND"] = str(validate_round_number(round_number))
    if result is not None:
        environment["FLICKY_PLAYTEST_RESULT"] = str(result.resolve())
    else:
        environment.pop("FLICKY_PLAYTEST_RESULT", None)
    if exit_when_ready:
        environment["FLICKY_PLAYTEST_EXIT"] = "1"
    else:
        environment.pop("FLICKY_PLAYTEST_EXIT", None)
    return environment


def playtest_command(
    gens: Path,
    rom: Path,
    *,
    automated: bool = False,
) -> list[str]:
    command = [
        str(gens.resolve()),
        "-rom", str(rom.resolve()),
        "-lua", str(SCRIPT.resolve()),
    ]
    if automated:
        command.extend(["-max-frames", "1200", "-turbo", "-frameskip", "8", "-nosound"])
    return command


def parse_result(path: Path, round_number: int) -> dict[str, str]:
    try:
        line = path.read_text(encoding="utf-8").strip().splitlines()[0]
    except (OSError, IndexError) as error:
        raise RuntimeError(f"cannot read playtest result {path}: {error}") from error
    fields = dict(item.split("=", 1) for item in line.split())
    expected_word = f"{round_word(round_number):04X}"
    if (
        fields.get("status") != "ready"
        or fields.get("round") != str(round_number)
        or fields.get("round_word") != expected_word
        or fields.get("mode") != "24"
    ):
        raise RuntimeError(f"selected round playtest failed: {line}")
    return fields


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gens", default="../gens_automation/Output/Gens.exe")
    parser.add_argument("--rom", default="build/content/flicky.bin")
    parser.add_argument("--round", type=int, default=1)
    parser.add_argument("--result", default="build/level_playtest.txt")
    parser.add_argument(
        "--check", action="store_true", help="exit after the round becomes playable"
    )
    args = parser.parse_args()

    gens = Path(args.gens)
    rom = Path(args.rom)
    result = Path(args.result)
    validate_round_number(args.round)
    if not gens.is_file():
        raise SystemExit(f"Gens not found: {gens}. Run 'make build-gens' first.")
    if not rom.is_file():
        raise SystemExit(f"content ROM not found: {rom}. Run 'make build-content' first.")
    result.parent.mkdir(parents=True, exist_ok=True)
    if result.exists():
        result.unlink()
    process = subprocess.Popen(
        playtest_command(gens, rom, automated=args.check),
        cwd=gens.resolve().parent,
        env=playtest_environment(args.round, result, exit_when_ready=args.check),
    )
    if not args.check:
        print(f"[OK] launched round {args.round} playtest in Gens")
        return 0
    deadline = time.monotonic() + 60
    fields: dict[str, str] | None = None
    while time.monotonic() < deadline:
        if result.is_file() and result.stat().st_size:
            try:
                fields = parse_result(result, args.round)
            except RuntimeError:
                pass
            else:
                break
        return_code = process.poll()
        if return_code is not None:
            raise SystemExit(f"Gens playtest exited with code {return_code} before reporting")
        time.sleep(0.05)
    process.terminate()
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait(timeout=5)
    if fields is None:
        raise SystemExit("playtest did not report readiness within 60 seconds")
    print(
        f"[OK] round {args.round} reached gameplay at frame {fields['frame']} "
        f"with {fields['lives']} lives"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
