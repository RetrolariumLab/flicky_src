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

# The naming vocabulary from docs/naming.md. A symbol is either owned by one of
# these subsystems, or derived from another symbol, or one of the two named
# exceptions below.
CATEGORIES = frozenset("""
    Sys Int Boot Gfx DMA Nem Eni Input Sound Text Math
    Game Level Object Sprite Anim Camera Collision Score Timer UI
    Title Guide RoundSelect Demo Bonus Ending SegaScreen
    Player Chick Cat Lizard Snake Spawner Enemy Obj
    BonusCat BonusChick StarBonus ExitDoor
    ScorePopup ChickCountPopup BonusScorePopup
    Data Ram Unused Z80
""".split())

# Hardware ports, the Z80 memory map and the VDP status bits keep the names the
# hardware gives them, in uppercase, and only in these two files.
HARDWARE_FILES = frozenset({"src/memory/hardware.inc", "src/memory/constants.inc"})
HARDWARE_NAME_RE = re.compile(r"^[A-Z][A-Z0-9_]*$")

# The cartridge header fields keep the names the Mega Drive format gives them,
# which is what every other Mega Drive disassembly calls them.
HEADER_FILE = "src/system/startup.s"
# Alignment pseudo-instructions keep instruction-like lowercase names.
MACRO_DIR = "src/macros/"
HEADER_FIELDS = frozenset({
    "CopyRights", "DomesticName", "Checksum", "Peripherials", "RomStart", "RomEnd",
    "RamStart", "RamEnd", "SramCode", "ModemCode", "Reserved", "CountryCode",
})

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
    """Every assembly source, entrypoint included: src/main.s lives under src/."""
    return sorted(Path("src").rglob("*.s")) + sorted(Path("src").rglob("*.inc"))


def owner_of(name: str, defined: set[str]) -> str | None:
    """The defined symbol a derived name hangs off, if there is one.

    A branch target is named after the procedure that contains it, and an end
    marker after the block it closes, so `Nem_PCD_WritePixel_Loop` is valid
    because `Nem_PCD_WritePixel` exists. The longest match wins, so a name
    cannot pass by accidentally sharing a first word with something else.
    """
    owner = name
    while "_" in owner:
        owner = owner.rsplit("_", 1)[0]
        if owner in defined:
            return owner
    return None


def check_vocabulary(definitions: dict[str, str]) -> list[str]:
    """Every symbol belongs to a subsystem, derives from one, or is hardware."""
    defined = set(definitions)
    errors: list[str] = []
    for name, where in sorted(definitions.items()):
        path = where.rsplit(":", 1)[0].replace("\\", "/")
        if path in HARDWARE_FILES and HARDWARE_NAME_RE.match(name):
            continue
        if path == HEADER_FILE and name in HEADER_FIELDS:
            continue
        if path.startswith(MACRO_DIR):
            # Macros are pseudo-instructions and read as such at the call site:
            # `cnop 0,4`, not `Sys_Cnop 0,4`.
            continue
        if name.split("_", 1)[0] in CATEGORIES:
            continue
        if name.startswith("j_") and name[2:] in defined:
            continue
        if owner_of(name, defined):
            continue
        errors.append(
            f"{where}: '{name}' names no subsystem and derives from no symbol; "
            "see docs/naming.md"
        )
    return errors


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

    errors.extend(check_vocabulary(definitions))

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
