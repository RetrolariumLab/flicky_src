#!/usr/bin/env python3
"""Read work RAM out of a Gens `.genstate` dump.

The format is written by `src/state_dump.cpp` in the sibling gens_automation
checkout: an eight byte "GENSTATE" magic and a little-endian version at the
start of a 64 byte header, then a table of 16 byte section entries
(id, offset, size, flags) terminated by a zeroed entry.

Only section 1 matters here. It is 64 KiB copied straight out of Gens'
`Ram_68k`, and Starscream holds 68000 work RAM as host-endian 16 bit words, so
the two bytes of every word are swapped relative to the 68000's own big-endian
view. `read` undoes that; reading the dump without undoing it silently returns
the neighbouring byte, which looks like plausible data rather than an error.
"""

from __future__ import annotations

import struct
from pathlib import Path

MAGIC = b"GENSTATE"
HEADER_SIZE = 64
SECTION_ENTRY = struct.Struct("<IIII")
SECTION_M68K_RAM = 0x01

WORK_RAM_BASE = 0xFF0000
WORK_RAM_SIZE = 64 * 1024


class DumpError(Exception):
    """The file is not a state dump this reader understands."""


def sections(data: bytes) -> dict[int, tuple[int, int]]:
    """Map each section id to its (offset, size)."""
    if not data.startswith(MAGIC):
        raise DumpError("not a GENSTATE dump")
    version = struct.unpack_from("<I", data, len(MAGIC))[0]
    if version != 1:
        raise DumpError(f"unsupported dump version {version}")

    found: dict[int, tuple[int, int]] = {}
    pos = HEADER_SIZE
    while pos + SECTION_ENTRY.size <= len(data):
        ident, offset, size, _flags = SECTION_ENTRY.unpack_from(data, pos)
        if ident == 0 and offset == 0:
            break
        if offset + size > len(data):
            raise DumpError(f"section {ident:#04x} runs past the end of the file")
        found[ident] = (offset, size)
        pos += SECTION_ENTRY.size
    return found


def work_ram(path: Path) -> bytes:
    """Return the 64 KiB of 68000 work RAM, still in Gens' swapped order."""
    data = path.read_bytes()
    table = sections(data)
    if SECTION_M68K_RAM not in table:
        raise DumpError(f"{path} carries no work RAM section")
    offset, size = table[SECTION_M68K_RAM]
    if size != WORK_RAM_SIZE:
        raise DumpError(f"work RAM is {size} bytes, expected {WORK_RAM_SIZE}")
    return data[offset:offset + size]


def read(ram: bytes, address: int, size: int) -> int:
    """Read `size` bytes at a 68000 address as the 68000 would see them."""
    if not WORK_RAM_BASE <= address <= 0xFFFFFF:
        raise DumpError(f"${address:06X} is outside work RAM")
    if address + size - 1 > 0xFFFFFF:
        raise DumpError(f"${address:06X}+{size} runs past the end of work RAM")
    offset = address & 0xFFFF
    # `^ 1` is the byte swap: it exchanges the two halves of each 16 bit word.
    return int.from_bytes(bytes(ram[(offset + i) ^ 1] for i in range(size)), "big")
