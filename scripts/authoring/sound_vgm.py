#!/usr/bin/env python3
"""Write Flicky offline-sequencer register logs as VGM 1.50 files."""

from __future__ import annotations

import struct
from pathlib import Path

from authoring.sound_sequencer import RenderResult, SN76489_CLOCK, YM2612_CLOCK


VGM_HEADER_SIZE = 0x100


def _wait(output: bytearray, samples: int) -> None:
    while samples:
        amount = min(samples, 0xFFFF)
        if amount <= 16:
            output.append(0x70 + amount - 1)
        else:
            output.extend((0x61, amount & 0xFF, amount >> 8))
        samples -= amount


def encode_vgm(result: RenderResult) -> bytes:
    header = bytearray(VGM_HEADER_SIZE)
    header[0:4] = b"Vgm "
    struct.pack_into("<I", header, 0x08, 0x00000150)
    struct.pack_into("<I", header, 0x0C, SN76489_CLOCK)
    struct.pack_into("<I", header, 0x18, result.total_samples)
    struct.pack_into("<I", header, 0x24, 60)
    struct.pack_into("<I", header, 0x2C, YM2612_CLOCK)
    struct.pack_into("<I", header, 0x34, VGM_HEADER_SIZE - 0x34)

    commands = bytearray()
    cursor = 0
    for write in sorted(result.writes, key=lambda item: item.sample):
        if write.sample < cursor:
            raise ValueError("chip writes are not ordered by sample")
        _wait(commands, write.sample - cursor)
        cursor = write.sample
        if write.chip == "ym2612":
            commands.extend((0x53 if write.port else 0x52, write.address, write.value))
        elif write.chip == "sn76489":
            commands.extend((0x50, write.value))
        else:
            raise ValueError(f"unsupported VGM chip: {write.chip}")
    _wait(commands, max(0, result.total_samples - cursor))
    commands.append(0x66)
    output = header + commands
    struct.pack_into("<I", output, 0x04, len(output) - 4)
    return bytes(output)


def write_vgm(result: RenderResult, path: Path) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(encode_vgm(result))
    return path
