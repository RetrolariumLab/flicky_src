#!/usr/bin/env python3
"""Compare Python sequencer chip writes with a real Gens Z80 trace."""

from __future__ import annotations

import argparse
import csv
import sys
from dataclasses import dataclass
from pathlib import Path

from authoring.sound_sequencer import ChipWrite, SoundSequencer


IGNORED_YM_REGISTERS = frozenset((0x24, 0x25, 0x26, 0x27))
TRACE_FRAME_RATE = 60.0
TIMING_TOLERANCE_FRAMES = 2.1


@dataclass(frozen=True)
class RegisterWrite:
    chip: str
    port: int
    address: int
    value: int

    def __str__(self) -> str:
        if self.chip == "YM2612":
            return f"YM2612 p{self.port} ${self.address:02X}=${self.value:02X}"
        return f"SN76489 ${self.value:02X}"


def python_timed_writes(writes: list[ChipWrite]) -> list[tuple[int, RegisterWrite]]:
    result = []
    for write in writes:
        if write.chip != "ym2612" or write.address in IGNORED_YM_REGISTERS:
            continue
        result.append((
            write.sample,
            RegisterWrite("YM2612", write.port, write.address, write.value),
        ))
    return result


def python_writes(writes: list[ChipWrite]) -> list[RegisterWrite]:
    return [write for _sample, write in python_timed_writes(writes)]


def gens_timed_writes(
    path: Path, first_frame: int, last_frame: int
) -> list[tuple[int, RegisterWrite]]:
    result = []
    with path.open(newline="", encoding="ascii") as source:
        rows = csv.DictReader(source)
        required = {"sequence", "frame", "chip", "port", "address", "value"}
        if rows.fieldnames is None or set(rows.fieldnames) != required:
            raise ValueError("Gens sound trace has unexpected CSV columns")
        for row in rows:
            frame = int(row["frame"])
            if not first_frame <= frame <= last_frame:
                continue
            if row["chip"] != "YM2612":
                continue
            address = int(row["address"], 16)
            if address in IGNORED_YM_REGISTERS:
                continue
            result.append((
                frame,
                RegisterWrite(
                    row["chip"], int(row["port"]), address, int(row["value"], 16)
                ),
            ))
    return result


def gens_writes(path: Path, first_frame: int, last_frame: int) -> list[RegisterWrite]:
    return [write for _frame, write in gens_timed_writes(path, first_frame, last_frame)]


def find_alignment(
    observed: list[RegisterWrite], expected: list[RegisterWrite], signature_size: int = 32
) -> int:
    if len(expected) < signature_size:
        raise ValueError("Python trace is shorter than the alignment signature")
    signature = expected[:signature_size]
    matches = [
        index for index in range(len(observed) - signature_size + 1)
        if observed[index:index + signature_size] == signature
    ]
    if len(matches) != 1:
        raise ValueError(
            f"expected one song-start signature in Gens trace, found {len(matches)}"
        )
    return matches[0]


def compare_traces(
    observed: list[RegisterWrite], expected: list[RegisterWrite], minimum: int
) -> int:
    start = find_alignment(observed, expected)
    actual = observed[start:]
    if len(actual) < minimum:
        raise ValueError(f"Gens comparison window has {len(actual)} writes; need {minimum}")
    if len(expected) < len(actual):
        raise ValueError(
            f"Python trace ended after {len(expected)} writes; Gens has {len(actual)}"
        )
    for index, (left, right) in enumerate(zip(actual, expected)):
        if left != right:
            raise ValueError(
                f"write {index} differs: Gens {left}, Python {right}"
            )
    return len(actual)


def compare_timing(
    observed: list[tuple[int, RegisterWrite]],
    expected: list[tuple[int, RegisterWrite]],
    sample_rate: int,
    *,
    frame_rate: float = TRACE_FRAME_RATE,
    tolerance_frames: float = TIMING_TOLERANCE_FRAMES,
) -> float:
    """Compare sample timing with the frame-resolution timestamps from Gens."""
    start = find_alignment(
        [write for _frame, write in observed],
        [write for _sample, write in expected],
    )
    actual = observed[start:]
    if not actual or len(expected) < len(actual):
        raise ValueError("sound timing comparison has incomplete traces")
    first_frame = actual[0][0]
    first_sample = expected[0][0]
    errors = [
        abs(
            (frame - first_frame)
            - (sample - first_sample) * frame_rate / sample_rate
        )
        for (frame, _observed_write), (sample, _expected_write)
        in zip(actual, expected)
    ]
    maximum = max(errors)
    if maximum > tolerance_frames:
        raise ValueError(
            f"sound timing differs by {maximum:.2f} frames; "
            f"allowed {tolerance_frames:.2f}"
        )
    return maximum


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--trace", type=Path, default=Path("build/sound_trace/gens.csv"))
    parser.add_argument("--source", type=Path, default=Path("src/sound/z80/data.asm"))
    parser.add_argument("--header", default="zMusic85Header")
    parser.add_argument("--seconds", type=float, default=4.0)
    parser.add_argument("--first-frame", type=int, default=320)
    parser.add_argument("--last-frame", type=int, default=457)
    parser.add_argument("--minimum-writes", type=int, default=2600)
    args = parser.parse_args()
    try:
        sequencer = SoundSequencer.from_source(args.source, args.source)
        rendered = sequencer.render(args.header, seconds=args.seconds)
        expected_timed = python_timed_writes(rendered.writes)
        observed_timed = gens_timed_writes(
            args.trace, args.first_frame, args.last_frame
        )
        expected = [write for _sample, write in expected_timed]
        observed = [write for _frame, write in observed_timed]
        count = compare_traces(observed, expected, args.minimum_writes)
        timing_error = compare_timing(
            observed_timed, expected_timed, rendered.sample_rate
        )
    except (OSError, ValueError) as error:
        print(f"[ERROR] sound sequencer fidelity: {error}", file=sys.stderr)
        return 1
    print(
        f"[OK] {count} ordered chip writes from {args.header} exactly match "
        f"the real Z80 driver in Gens; timing error <= {timing_error:.2f} frames"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
