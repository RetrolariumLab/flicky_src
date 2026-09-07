#!/usr/bin/env python3
"""Nemesis re-compressor: rebuild a stream using the original's own code table."""

from __future__ import annotations


def parse_header(data: bytes) -> tuple[int, bool, dict[tuple[int, int], tuple[int, int]], int]:
    """Return (tile count, xor mode, {(nybble, run): (code, bits)}, header size).

    The code table is part of the compressed stream, so re-encoding does not
    have to invent one. Reusing it removes the only genuinely lossy decision in
    the format and leaves the run splitting as the one thing to reproduce.
    """
    header = (data[0] << 8) | data[1]
    xor_mode = (header & 0x8000) != 0
    tiles = header & 0x7FFF

    pos = 2
    codes: dict[tuple[int, int], tuple[int, int]] = {}
    while True:
        value = data[pos]
        pos += 1
        if value == 0xFF:
            break
        palette_index = value & 0x0F
        while True:
            value = data[pos]
            pos += 1
            if value >= 0x80:
                if value == 0xFF:
                    break
                palette_index = value & 0x0F
                continue
            run_length = ((value >> 4) & 7) + 1
            code_length = value & 0x0F or 8
            code_byte = data[pos]
            pos += 1
            codes.setdefault((palette_index, run_length), (code_byte, code_length))
        if value == 0xFF:
            break
    return tiles, xor_mode, codes, pos


def to_nybbles(plain: bytes, xor_mode: bool) -> list[int]:
    """Undo the XOR chaining and flatten the tile data into nybbles."""
    nybbles: list[int] = []
    previous = 0
    for offset in range(0, len(plain), 4):
        word = int.from_bytes(plain[offset:offset + 4], "big")
        stored = word
        if xor_mode:
            stored = word ^ previous
            previous = word
        for shift in range(28, -1, -4):
            nybbles.append((stored >> shift) & 0xF)
    return nybbles


class BitWriter:
    def __init__(self) -> None:
        self.bits: list[int] = []

    def write(self, value: int, count: int) -> None:
        for shift in range(count - 1, -1, -1):
            self.bits.append((value >> shift) & 1)

    def to_bytes(self, pad: int) -> bytes:
        bits = list(self.bits)
        while len(bits) % 8:
            bits.append(pad)
        out = bytearray()
        for offset in range(0, len(bits), 8):
            byte = 0
            for bit in bits[offset:offset + 8]:
                byte = (byte << 1) | bit
            out.append(byte)
        return bytes(out)


def compress(plain: bytes, reference: bytes) -> bytes:
    """Re-encode `plain` using the code table carried by `reference`."""
    tiles, xor_mode, codes, header_size = parse_header(reference)
    nybbles = to_nybbles(plain, xor_mode)

    total = len(nybbles)
    costs = [0] * (total + 1)
    choices: list[tuple[int, tuple[int, int] | None]] = [(0, None)] * total
    for index in range(total - 1, -1, -1):
        nybble = nybbles[index]
        maximum = 1
        while (
            maximum < 8
            and index + maximum < total
            and nybbles[index + maximum] == nybble
        ):
            maximum += 1
        candidates: list[tuple[int, int, tuple[int, int] | None]] = []
        for run in range(1, maximum + 1):
            if (nybble, run) in codes:
                _code, bits = codes[(nybble, run)]
                candidates.append((bits + costs[index + run], -run, (nybble, run)))
            # Inline mode is always available and costs 6+3+4 bits.
            candidates.append((13 + costs[index + run], -run, None))
        cost, negative_run, choice = min(candidates)
        run = -negative_run
        costs[index] = cost
        choices[index] = (run, choice)

    writer = BitWriter()
    index = 0
    while index < total:
        run, choice = choices[index]
        nybble = nybbles[index]
        if choice is None:
            writer.write(0x3F, 6)
            writer.write(run - 1, 3)
            writer.write(nybble, 4)
        else:
            code, bits = codes[choice]
            writer.write(code, bits)
        index += run

    # The original pads the final byte with set bits.
    return reference[:header_size] + writer.to_bytes(1)


if __name__ == "__main__":
    import pathlib
    import sys

    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} plain.bin reference.nem [out.nem]")
        raise SystemExit(1)
    plain = pathlib.Path(sys.argv[1]).read_bytes()
    reference = pathlib.Path(sys.argv[2]).read_bytes()
    result = compress(plain, reference)
    if len(sys.argv) > 3:
        pathlib.Path(sys.argv[3]).write_bytes(result)
    print(f"{len(plain)} -> {len(result)} bytes")
