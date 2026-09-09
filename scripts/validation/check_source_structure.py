#!/usr/bin/env python3
"""Enforce assembly source granularity and filename-prefix structure."""

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path


SOURCE_SUFFIXES = frozenset({".s", ".asm", ".inc"})


def source_files(root: Path) -> list[Path]:
    return sorted(
        path for path in (root / "src").rglob("*")
        if path.is_file() and path.suffix.lower() in SOURCE_SUFFIXES
    )


def line_count(path: Path) -> int:
    return len(path.read_text(encoding="utf-8").splitlines())


def filename_prefix(path: Path) -> str:
    return path.stem.split("_", 1)[0].casefold()


def check(root: Path, config: dict) -> tuple[list[str], dict[str, int]]:
    preferred = config["preferred_line_range"]
    minimum = int(preferred["minimum"])
    maximum = int(preferred["maximum"])
    exceptions = config.get("exceptions", {})
    files = source_files(root)
    errors: list[str] = []
    outside = 0

    if minimum < 1 or maximum < minimum:
        errors.append(f"invalid preferred line range {minimum}-{maximum}")

    known = {path.relative_to(root).as_posix() for path in files}
    for relative, reason in exceptions.items():
        if relative not in known:
            errors.append(f"stale size exception for missing source: {relative}")
        if not isinstance(reason, str) or len(reason.strip()) < 40:
            errors.append(f"size exception needs a concrete reason: {relative}")

    for path in files:
        relative = path.relative_to(root).as_posix()
        count = line_count(path)
        in_range = minimum <= count <= maximum
        if not in_range:
            outside += 1
            if relative not in exceptions:
                errors.append(
                    f"{relative}: {count} lines is outside {minimum}-{maximum} "
                    "and has no exception reason"
                )
        elif relative in exceptions:
            errors.append(f"{relative}: stale size exception; {count} lines is now in range")

    by_directory: dict[Path, dict[str, list[str]]] = defaultdict(lambda: defaultdict(list))
    for path in files:
        by_directory[path.parent][filename_prefix(path)].append(path.name)
    for directory, prefixes in sorted(by_directory.items()):
        for prefix, names in sorted(prefixes.items()):
            if len(names) > 1:
                relative_dir = directory.relative_to(root).as_posix()
                errors.append(
                    f"{relative_dir}: repeated filename prefix '{prefix}' in "
                    f"{', '.join(sorted(names))}; use a subdirectory or a stronger name"
                )

    return errors, {
        "files": len(files),
        "preferred": len(files) - outside,
        "exceptions": outside,
        "directories": len(by_directory),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", default="config/reconstruction/source_structure.json")
    parser.add_argument("--root", default=".")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    config = json.loads((root / args.config).read_text(encoding="utf-8"))
    errors, summary = check(root, config)
    if errors:
        for error in errors:
            print(f"[ERROR] {error}", file=sys.stderr)
        print(f"[FAIL] {len(errors)} source-structure issue(s)", file=sys.stderr)
        return 1

    print(
        f"[OK] {summary['files']} assembly sources across {summary['directories']} directories: "
        f"{summary['preferred']} in the preferred range, "
        f"{summary['exceptions']} justified exception(s), no repeated filename prefixes"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
