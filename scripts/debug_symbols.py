#!/usr/bin/env python3
"""Export the assembled symbol table for debuggers and trace annotation."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

# A listing row is "(depth) line/ address : <20 columns of bytes><source>".
# The depth prefix is present for included files, which is every module.
LISTING_ROW_RE = re.compile(r"^(?:\(\d+\))?\s*\d+/\s*([0-9A-F]+) : (.{20})(.*)$")
DEFINITION_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)(?=:)")
EQUATE_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):?\s+equ\s+\$([0-9A-F]+)", re.IGNORECASE)


def fail(message: str) -> None:
    print(f"[ERROR] {message}", file=sys.stderr)
    raise SystemExit(1)


def code_of(line: str) -> str:
    in_string = False
    for index, char in enumerate(line):
        if char == '"':
            in_string = not in_string
        elif char == ";" and not in_string:
            return line[:index]
    return line


def collect_from_listing(listing: Path) -> dict[str, int]:
    """Resolve every column-zero label to the address it assembled at.

    The listing is parsed rather than the assembler's own symbol table because
    that table uppercases every name, which would throw away the casing the
    naming convention depends on.
    """
    resolved: dict[str, int] = {}
    for row in listing.read_text(encoding="latin-1").splitlines():
        match = LISTING_ROW_RE.match(row)
        if not match:
            continue
        source = match.group(3)
        label = DEFINITION_RE.match(code_of(source))
        if label:
            resolved.setdefault(label.group(1), int(match.group(1), 16))
    return resolved


def equates(paths: list[Path]) -> dict[str, int]:
    found: dict[str, int] = {}
    for path in paths:
        for raw in path.read_text(encoding="utf-8").split("\n"):
            match = EQUATE_RE.match(code_of(raw))
            if match:
                found[match.group(1)] = int(match.group(2), 16)
    return found


def load_config(path: Path, key: str) -> list[dict]:
    if not path.is_file():
        return []
    data = json.loads(path.read_text(encoding="utf-8"))
    return data.get(key, [])


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--listing", default="flicky.lst")
    parser.add_argument("--ram", default="src/memory/ram.inc")
    parser.add_argument("--hardware", default="src/memory/hardware.inc")
    parser.add_argument("--breakpoints", default="config/debugger_breakpoints.json")
    parser.add_argument("--watches", default="config/debugger_watches.json")
    parser.add_argument("--sym", default="build/flicky.sym")
    parser.add_argument("--summary", default="build/debug_symbols.json")
    args = parser.parse_args()

    listing = Path(args.listing)
    if not listing.is_file():
        fail(f"listing not found: {listing}. Run 'make flicky.lst' first.")

    rom = collect_from_listing(listing)
    if not rom:
        fail("no ROM symbols found in the listing")

    ram = equates([Path(args.ram)])
    hardware = equates([Path(args.hardware)])

    sym_path = Path(args.sym)
    sym_path.parent.mkdir(parents=True, exist_ok=True)
    lines = [f"{address:06X} {name}" for name, address in sorted(rom.items(), key=lambda kv: kv[1])]
    sym_path.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="")

    problems = []
    resolved_breakpoints = []
    for entry in load_config(Path(args.breakpoints), "breakpoints"):
        name = entry["symbol"]
        if name not in rom:
            problems.append(f"breakpoint symbol not found: {name}")
            continue
        resolved_breakpoints.append({**entry, "address": f"0x{rom[name]:06X}"})

    resolved_watches = []
    for entry in load_config(Path(args.watches), "watches"):
        name = entry["symbol"]
        address = ram.get(name, hardware.get(name))
        if address is None:
            problems.append(f"watch symbol not found: {name}")
            continue
        resolved_watches.append({**entry, "address": f"0x{address:06X}"})

    summary_path = Path(args.summary)
    summary_path.parent.mkdir(parents=True, exist_ok=True)
    summary_path.write_text(
        json.dumps(
            {
                "rom_symbols": len(rom),
                "ram_symbols": len(ram),
                "hardware_symbols": len(hardware),
                "breakpoints": resolved_breakpoints,
                "watches": resolved_watches,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
        newline="",
    )

    if problems:
        for problem in problems:
            print(f"[ERROR] {problem}", file=sys.stderr)
        print(f"[FAIL] {len(problems)} unresolved symbol(s)", file=sys.stderr)
        return 1

    print(f"[OK] {len(rom)} ROM symbols written to {sym_path}")
    print(f"[OK] {len(ram)} RAM and {len(hardware)} hardware symbols read")
    print(
        f"[OK] {len(resolved_breakpoints)} breakpoints and {len(resolved_watches)} "
        f"watches resolved into {summary_path}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
