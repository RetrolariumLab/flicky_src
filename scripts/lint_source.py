#!/usr/bin/env python3
"""Check semantic invariants of the assembly source."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# A module owns one coherent subsystem. See docs/source_layout.md.
MODULE_LINE_LIMIT = 700

# Names produced by the disassembler carry the ROM address they happened to sit
# at. They say nothing about what the symbol is for, and they go stale the
# moment anything moves. See docs/naming.md.
ADDRESS_DERIVED_RE = re.compile(r"^(?:loc|locret|sub|nullsub|off|unk|byte|word|dword|flt|stru|asc)_[0-9A-F]{1,6}$")

# Hardware ports and the Z80 memory map are named once, in src/memory/, and
# referenced by symbol everywhere else.
RAW_HARDWARE_RE = re.compile(r"\$(?:C0000[0-9A-F]|A1[0-9A-F]{4}|A0[0-9A-F]{4})(?![0-9A-F])")
DEFINITIONS_DIR = Path("src/memory")

LABEL_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
EQUATE_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s+equ\b", re.IGNORECASE)
MACRO_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s+macro\b", re.IGNORECASE)
CALL_RE = re.compile(r"^\s+(?:bsr|jsr)(?:\.[bwsl])?\s+(?:\()?([A-Za-z_][A-Za-z0-9_]*)")


def split_comment(text: str) -> str:
    """Return the code part of a line, ignoring anything after an unquoted ';'."""
    in_string = False
    for index, char in enumerate(text):
        if char == '"':
            in_string = not in_string
        elif char == ";" and not in_string:
            return text[:index]
    return text


def source_files() -> list[Path]:
    files = sorted(Path("src").rglob("*.s")) + sorted(Path("src").rglob("*.inc"))
    if Path("flicky.s").is_file():
        files.append(Path("flicky.s"))
    return files


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--strict-naming",
        action="store_true",
        help="Treat every remaining address-derived identifier as an error",
    )
    args = parser.parse_args()

    files = source_files()
    errors: list[str] = []
    definitions: dict[str, str] = {}
    duplicates: list[str] = []
    address_derived: list[str] = []
    call_targets: list[tuple[str, str]] = []

    for path in files:
        lines = path.read_text(encoding="utf-8").split("\n")
        if lines and lines[-1] == "":
            lines.pop()

        if path.suffix == ".s" and len(lines) > MODULE_LINE_LIMIT:
            errors.append(
                f"{path}: {len(lines)} lines exceeds the {MODULE_LINE_LIMIT}-line module limit"
            )

        for number, raw in enumerate(lines, 1):
            code = split_comment(raw)
            where = f"{path}:{number}"

            name = None
            for pattern in (LABEL_RE, EQUATE_RE, MACRO_RE):
                match = pattern.match(code)
                if match:
                    name = match.group(1)
                    break

            if name:
                if name in definitions:
                    duplicates.append(f"{where}: '{name}' already defined at {definitions[name]}")
                else:
                    definitions[name] = where
                if ADDRESS_DERIVED_RE.match(name):
                    address_derived.append(f"{where}: {name}")

            call = CALL_RE.match(code)
            if call:
                call_targets.append((call.group(1), where))

            if DEFINITIONS_DIR not in path.parents and RAW_HARDWARE_RE.search(code):
                errors.append(
                    f"{where}: raw hardware address; use a symbol defined in {DEFINITIONS_DIR}/"
                )

    for target, where in call_targets:
        if target not in definitions:
            errors.append(f"{where}: call target '{target}' is not defined in the source")

    errors.extend(duplicates)

    if args.strict_naming:
        errors.extend(f"{entry}: address-derived name; see docs/naming.md" for entry in address_derived)

    if errors:
        for error in errors[:60]:
            print(f"[ERROR] {error}", file=sys.stderr)
        if len(errors) > 60:
            print(f"[ERROR] ... and {len(errors) - 60} more", file=sys.stderr)
        print(f"[FAIL] {len(errors)} source issue(s)", file=sys.stderr)
        return 1

    print(f"[OK] {len(definitions)} symbols across {len(files)} files; no duplicate or dangling names")
    if address_derived:
        print(
            f"[INFO] {len(address_derived)} address-derived identifiers remain "
            "(milestone 3; --strict-naming makes this an error)"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
