"""Render editable Z80 sound banks from the layout and the user's ROM."""

from __future__ import annotations

import re
from pathlib import Path
from tempfile import NamedTemporaryFile

LAYOUT = "config/z80_sound_data.layout"
BANKS_ASSET = "data/sound/data_z80_part2.bin"
BANKS_OFFSET = 12
BANKS_SIZE = 2804
RENDERED = "build/content/baseline/z80_sound_data.asm"

HEX_PLACEHOLDER = "$??"
DECIMAL_PLACEHOLDER = "?"

# What each data directive writes, in byte order: a two-byte Z80 pointer
# ("pointer", the argument naming its target) or one data byte ("byte").
# The pointers of the header macros are relative to the bank they live in.
DIRECTIVES: dict[str, tuple[str, ...]] = {
    "z80ptr": ("pointer",),
    "sfxheader": ("pointer", "byte", "byte"),
    "sfxtrack": ("byte", "byte", "pointer", "byte", "byte"),
    "musicheader": ("pointer", "byte", "byte", "byte", "byte"),
    "musicfm": ("pointer", "byte", "byte"),
    "musicpsg": ("pointer", "byte", "byte", "byte", "byte"),
}
BANKS = {
    "sfxheader": ("zSFXBank", 0x1000),
    "sfxtrack": ("zSFXBank", 0x1000),
    "musicheader": ("zMusicBank", 0x1200),
    "musicfm": ("zMusicBank", 0x1200),
    "musicpsg": ("zMusicBank", 0x1200),
}
# Where each argument of a directive sits among its written bytes.
ARGUMENT_ORDER: dict[str, tuple[int, ...]] = {
    "z80ptr": (0,),
    "sfxheader": (0, 1, 2),
    "sfxtrack": (0, 1, 2, 3, 4),
    "musicheader": (0, 1, 2, 3, 4),
    "musicfm": (0, 1, 2),
    "musicpsg": (0, 1, 2, 3, 4),
}

LINE_RE = re.compile(
    r"^(?P<head>\s*(?:(?P<label>[A-Za-z_]\w*):)?\s*)"
    r"(?P<op>dc\.b|z80ptr|sfxheader|sfxtrack|musicheader|musicfm|musicpsg)"
    r"(?P<gap>\s+)(?P<args>[^;]*?)(?P<tail>\s*(?:;.*)?)$"
)
LABEL_RE = re.compile(r"^(?P<label>[A-Za-z_]\w*):")


class SoundSourceError(ValueError):
    """The layout and the banks do not fit together."""


def _split(arguments: str) -> list[tuple[str, str, str]]:
    """Each comma-separated argument as (leading space, value, trailing space)."""
    pieces = []
    for piece in arguments.split(","):
        value = piece.strip()
        lead = piece[: len(piece) - len(piece.lstrip())]
        trail = piece[len(piece.rstrip()) :]
        pieces.append((lead, value, trail))
    return pieces


def _join(pieces: list[tuple[str, str, str]]) -> str:
    return ",".join(lead + value + trail for lead, value, trail in pieces)


def _lines(text: str) -> list[tuple[str, re.Match[str] | None]]:
    """Every line, with its data directive when it has one; macro bodies
    write nothing of their own and are left alone."""
    result = []
    in_macro = False
    for line in text.split("\n"):
        code = line.split(";", 1)[0].strip()
        if re.search(r"\bmacro\b", code):
            in_macro = True
        elif code == "endm":
            in_macro = False
            result.append((line, None))
            continue
        result.append((line, None if in_macro else LINE_RE.match(line)))
    return result


def _kinds(op: str, count: int) -> tuple[str, ...]:
    if op == "dc.b":
        return ("byte",) * count
    kinds = DIRECTIVES[op]
    if op == "z80ptr":
        if count != 3:
            raise SoundSourceError("z80ptr takes a target, its bank and the bank's Z80 address")
        return ("pointer", "bank", "base")
    if count != len(kinds):
        raise SoundSourceError(f"{op} takes {len(kinds)} arguments")
    return kinds


def _size(op: str, count: int) -> int:
    return sum(2 if kind == "pointer" else 1 if kind == "byte" else 0 for kind in _kinds(op, count))


def _labels(text: str) -> dict[str, int]:
    """The offset of every label from the start of the banks."""
    labels: dict[str, int] = {}
    offset = 0
    for line, match in _lines(text):
        label = LABEL_RE.match(line)
        if label:
            labels[label.group("label")] = offset
        if match:
            offset += _size(match.group("op"), len(_split(match.group("args"))))
    return labels


def render(layout_text: str, banks: bytes) -> str:
    """The banks assembly: the layout with its placeholders filled from `banks`."""
    labels = _labels(layout_text)
    out = []
    offset = 0
    for line, match in _lines(layout_text):
        if not match:
            out.append(line)
            continue
        op = match.group("op")
        pieces = _split(match.group("args"))
        kinds = _kinds(op, len(pieces))
        size = _size(op, len(pieces))
        if offset + size > len(banks):
            raise SoundSourceError("the banks end before the layout does")
        written = banks[offset : offset + size]
        position = 0
        filled = list(pieces)
        if op == "z80ptr":
            bank, base = pieces[1][1], pieces[2][1]
            bank_base = (bank, int(base[1:], 16) if base.startswith("$") else int(base, 0))
        else:
            bank_base = BANKS.get(op, ("", 0))
        for index in ARGUMENT_ORDER.get(op, range(len(pieces))):
            lead, value, trail = pieces[index]
            kind = kinds[index]
            if kind == "pointer":
                target = written[position] | written[position + 1] << 8
                bank, base = bank_base
                if value not in labels or bank not in labels:
                    raise SoundSourceError(f"unknown label in {line.strip()}")
                if target != (base + labels[value] - labels[bank]) & 0xFFFF:
                    raise SoundSourceError(f"the banks' pointer at {offset + position:#x} is not {value}")
                position += 2
            elif kind == "byte":
                byte = written[position]
                if value == HEX_PLACEHOLDER:
                    value = f"${byte:02X}"
                elif value == DECIMAL_PLACEHOLDER:
                    value = str(byte)
                else:
                    raise SoundSourceError(f"the layout holds a data value: {line.strip()}")
                filled[index] = (lead, value, trail)
                position += 1
        offset += size
        out.append(match.group("head") + op + match.group("gap") + _join(filled) + match.group("tail"))
    if offset != len(banks):
        raise SoundSourceError(f"the layout covers {offset} bytes of the {len(banks)}-byte banks")
    return "\n".join(out)


def banks_from_asset(root: Path) -> bytes:
    try:
        data = (root / BANKS_ASSET).read_bytes()
    except FileNotFoundError as error:
        raise SoundSourceError(f"{BANKS_ASSET} is missing; run make split") from error
    banks = data[BANKS_OFFSET : BANKS_OFFSET + BANKS_SIZE]
    if len(banks) != BANKS_SIZE:
        raise SoundSourceError(f"{BANKS_ASSET} is too short for the sound banks")
    return banks


def baseline_path(root: Path) -> Path:
    """Prepare the unedited Studio source without touching its editable copy."""
    text = render((root / LAYOUT).read_text(encoding="utf-8"), banks_from_asset(root))
    rendered = root / RENDERED
    if rendered.is_file() and rendered.read_text(encoding="utf-8") == text:
        return rendered

    rendered.parent.mkdir(parents=True, exist_ok=True)
    with NamedTemporaryFile(
        mode="w", encoding="utf-8", newline="\n", dir=rendered.parent, delete=False
    ) as handle:
        temporary = Path(handle.name)
        try:
            handle.write(text)
            handle.close()
            temporary.replace(rendered)
        finally:
            temporary.unlink(missing_ok=True)
    return rendered
