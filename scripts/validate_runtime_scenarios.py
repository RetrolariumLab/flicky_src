#!/usr/bin/env python3
"""Validate captured runtime scenarios against a reference capture."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"[ERROR] {message}", file=sys.stderr)
    raise SystemExit(1)


def frames(directory: Path) -> dict[str, str]:
    """Map each captured frame's filename to its SHA-1."""
    return {
        path.name: hashlib.sha1(path.read_bytes()).hexdigest()
        for path in sorted(directory.glob("*.png"))
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scenarios", default="scenarios/runtime_scenarios.json")
    parser.add_argument("--capture-dir", default="build/runtime")
    parser.add_argument("--reference-dir", help="Reference capture to compare against")
    parser.add_argument("--summary", help="Write a JSON summary here")
    args = parser.parse_args()

    spec = json.loads(Path(args.scenarios).read_text(encoding="utf-8"))
    capture_root = Path(args.capture_dir)
    if not capture_root.is_dir():
        fail(
            f"no capture found at {capture_root}\n"
            "        Run 'make trace-runtime' first. That needs the instrumented Gens\n"
            "        build, which needs Visual Studio 2022."
        )

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

        if reference_root is None:
            print(f"[INFO] {scenario['id']}: {len(captured)} frames, no reference to compare")
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
            detail = f"{len(differing)} differing, {len(missing)} missing"
            print(f"[ERROR] {scenario['id']}: {detail}", file=sys.stderr)
            for name in differing[:3]:
                print(f"[ERROR]     first differing frame: {name}", file=sys.stderr)
                break
            failures += 1
        else:
            print(f"[OK] {scenario['id']}: {len(captured)} frames match the reference")

    if args.summary:
        summary = Path(args.summary)
        summary.parent.mkdir(parents=True, exist_ok=True)
        summary.write_text(
            json.dumps({"results": results}, indent=2) + "\n", encoding="utf-8", newline=""
        )

    if failures:
        print(f"[FAIL] {failures} scenario(s) failed validation", file=sys.stderr)
        return 1
    print(f"[OK] {len(results)} scenario(s) validated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
