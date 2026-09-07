#!/usr/bin/env python3
"""Validate captured runtime scenarios.

Two independent layers, and they answer different questions.

The state layer is the evidence. Each scenario declares fields of work RAM that
the game must be in when the movie reaches that scene, `holds` for every frame
of the window and `reaches` for at least one. The values are read out of the
`.genstate` dumps through the symbols in `src/memory/ram.inc`, so a scenario
fails if the emulated game diverges even where the picture would look right.

The frame layer compares screenshots against a previous capture, and only runs
when `--reference-dir` names one. It catches rendering changes the state layer
cannot see, and needs a capture from a known-good build to compare against.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

from runtime import genstate
from validation import debug_symbols


def fail(message: str) -> None:
    print(f"[ERROR] {message}", file=sys.stderr)
    raise SystemExit(1)


def frames(directory: Path) -> dict[str, str]:
    """Map each captured frame's filename to its SHA-1."""
    return {
        path.name: hashlib.sha1(path.read_bytes()).hexdigest()
        for path in sorted(directory.glob("*.png"))
    }


def parse_value(text: str) -> int:
    """Read a declared value. `$` marks hex, as everywhere else in the sources."""
    return int(text[1:], 16) if text.startswith("$") else int(text, 0)


def dumps_in_window(directory: Path, first: int, last: int) -> list[Path]:
    """State dumps inside a scenario's frame range.

    A capture runs from frame zero, because a movie can only be replayed from
    its start, so the directory holds every frame up to `last`. Only the ones
    inside the window say anything about the scene the scenario names.
    """
    found = []
    for path in sorted(directory.glob("*.genstate")):
        if path.stem.isdigit() and first <= int(path.stem) <= last:
            found.append(path)
    return found


def check_state(scenario: dict, directory: Path, symbols: dict, sizes: dict) -> list[str]:
    """Compare declared expectations against the captured work RAM."""
    expectations = scenario.get("expect_state")
    if not expectations:
        return []

    window = dumps_in_window(directory, scenario["first_frame"], scenario["last_frame"])
    if not window:
        return [f"no state dumps between frames "
                f"{scenario['first_frame']} and {scenario['last_frame']}"]

    observed: dict[str, list[tuple[int, int]]] = {}
    for path in window:
        ram = genstate.work_ram(path)
        for name in set(expectations.get("holds", {})) | set(expectations.get("reaches", {})):
            if name not in symbols:
                continue
            value = genstate.read(ram, symbols[name], sizes[name])
            observed.setdefault(name, []).append((int(path.stem), value))

    errors = []
    for name in sorted(set(expectations.get("holds", {})) | set(expectations.get("reaches", {}))):
        if name not in symbols:
            errors.append(f"{name} is not defined in the RAM map")
        elif name not in sizes:
            errors.append(f"{name} has no declared size")

    width = {1: 2, 2: 4, 4: 8}
    for name, declared in sorted(expectations.get("holds", {}).items()):
        if name not in observed:
            continue
        want = parse_value(declared)
        wrong = [(frame, value) for frame, value in observed[name] if value != want]
        if wrong:
            frame, value = wrong[0]
            digits = width[sizes[name]]
            errors.append(
                f"{name} should hold {declared} across frames "
                f"{scenario['first_frame']}-{scenario['last_frame']}, but is "
                f"${value:0{digits}X} at frame {frame} "
                f"({len(wrong)} of {len(observed[name])} frames differ)"
            )

    for name, declared in sorted(expectations.get("reaches", {}).items()):
        if name not in observed:
            continue
        want = parse_value(declared)
        if not any(value == want for _frame, value in observed[name]):
            digits = width[sizes[name]]
            seen = sorted({value for _frame, value in observed[name]})
            shown = ", ".join(f"${value:0{digits}X}" for value in seen[:6])
            errors.append(
                f"{name} never reaches {declared} between frames "
                f"{scenario['first_frame']}-{scenario['last_frame']}; saw {shown}"
            )
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scenarios", default="scenarios/runtime_scenarios.json")
    parser.add_argument("--capture-dir", default="build/runtime")
    parser.add_argument("--reference-dir", help="Reference capture to compare frames against")
    parser.add_argument("--summary", help="Write a JSON summary here")
    args = parser.parse_args()

    spec = json.loads(Path(args.scenarios).read_text(encoding="utf-8"))
    capture_root = Path(args.capture_dir)
    if not capture_root.is_dir():
        fail(
            f"no capture found at {capture_root}\n"
            "        Run 'make trace-runtime' first. That needs a Gens build:\n"
            "        'make -f Makefile.docker win-i386' in the gens_automation\n"
            "        checkout, or Visual Studio."
        )

    declared = spec.get("symbols", {})
    sizes = declared.get("sizes", {})
    symbols = debug_symbols.equates([Path(declared.get("source", "src/memory/ram.inc"))])

    reference_root = Path(args.reference_dir) if args.reference_dir else None
    results = []
    failures = 0

    for scenario in spec["scenarios"]:
        target = capture_root / scenario["id"]
        if not target.is_dir():
            print(f"[ERROR] {scenario['id']}: not captured", file=sys.stderr)
            failures += 1
            continue

        captured = frames(target)
        if not captured:
            print(f"[ERROR] {scenario['id']}: capture directory is empty", file=sys.stderr)
            failures += 1
            continue

        entry = {"id": scenario["id"], "frames": len(captured), "expects": scenario["expects"]}

        state_errors = check_state(scenario, target, symbols, sizes)
        expectations = scenario.get("expect_state", {})
        checked = len(expectations.get("holds", {})) + len(expectations.get("reaches", {}))
        entry["state_checks"] = checked
        entry["state_ok"] = not state_errors

        if state_errors:
            failures += 1
            for message in state_errors:
                print(f"[ERROR] {scenario['id']}: {message}", file=sys.stderr)
        elif checked:
            print(f"[OK] {scenario['id']}: {checked} state expectation(s) hold "
                  f"across {len(captured)} frames")
        else:
            print(f"[WARN] {scenario['id']}: no state expectations declared")

        if reference_root is None:
            entry["compared"] = False
            results.append(entry)
            continue

        reference = reference_root / scenario["id"]
        if not reference.is_dir():
            print(f"[ERROR] {scenario['id']}: no reference capture", file=sys.stderr)
            failures += 1
            continue

        expected = frames(reference)
        differing = [name for name, digest in expected.items() if captured.get(name) != digest]
        missing = [name for name in expected if name not in captured]
        entry.update({"compared": True, "differing": len(differing), "missing": len(missing)})
        results.append(entry)

        if differing or missing:
            print(f"[ERROR] {scenario['id']}: {len(differing)} differing, "
                  f"{len(missing)} missing", file=sys.stderr)
            for name in differing[:1]:
                print(f"[ERROR]     first differing frame: {name}", file=sys.stderr)
            failures += 1
        else:
            print(f"[OK] {scenario['id']}: {len(captured)} frames match the reference")

    if args.summary:
        summary = Path(args.summary)
        summary.parent.mkdir(parents=True, exist_ok=True)
        # The capture's own provenance travels with the result, so a summary
        # always says which emulator build and which ROM produced it.
        info = capture_root / "capture_info.json"
        payload: dict = {"results": results}
        if info.is_file():
            payload["capture"] = json.loads(info.read_text(encoding="utf-8"))
        summary.write_text(
            json.dumps(payload, indent=2) + "\n", encoding="utf-8", newline=""
        )

    if failures:
        print(f"[FAIL] {failures} scenario(s) failed validation", file=sys.stderr)
        return 1
    total = sum(entry["state_checks"] for entry in results)
    print(f"[OK] {len(results)} scenario(s) validated, {total} state expectation(s) checked")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
