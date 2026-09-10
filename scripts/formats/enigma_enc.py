#!/usr/bin/env python3
"""Small optimizing Enigma encoder for editable Mega Drive tilemaps."""

from __future__ import annotations

from functools import lru_cache


class BitWriter:
    def __init__(self) -> None:
        self.bits: list[int] = []

    def write(self, value: int, count: int) -> None:
        for shift in range(count - 1, -1, -1):
            self.bits.append((value >> shift) & 1)

    def to_bytes(self) -> bytes:
        bits = list(self.bits)
        while len(bits) % 8:
            bits.append(0)
        result = bytearray()
        for offset in range(0, len(bits), 8):
            value = 0
            for bit in bits[offset:offset + 8]:
                value = (value << 1) | bit
            result.append(value)
        return bytes(result)


def words_from_bytes(data: bytes) -> list[int]:
    if len(data) % 2:
        raise ValueError("Enigma input tilemap must contain whole big-endian words")
    return [int.from_bytes(data[offset:offset + 2], "big") for offset in range(0, len(data), 2)]


def run_length(values: list[int], position: int, step: int) -> int:
    length = 1
    while (
        length < 16
        and position + length < len(values)
        and values[position + length] == (values[position] + step * length) & 0xFFFF
    ):
        length += 1
    return length


def encode(data: bytes) -> bytes:
    """Encode words with Enigma modes 0 and 4..7.

    The encoder chooses the incrementing and static header words and minimizes
    the payload bit count. Attribute flags are folded into the tile word, so
    the output uses a zero flag byte and enough tile bits for the largest word.
    """
    values = words_from_bytes(data)
    if not values:
        raise ValueError("Enigma cannot encode an empty tilemap")
    largest = max(values)
    bits_count = max(1, largest.bit_length())
    if bits_count > 16:
        raise ValueError("Enigma tile words must fit in sixteen bits")
    frequencies: dict[int, int] = {}
    for value in values:
        frequencies[value] = frequencies.get(value, 0) + 1
    static_tile = max(frequencies, key=lambda value: (frequencies[value], -value))

    best: tuple[int, int, tuple[tuple[int, int, tuple[int, ...]], ...]] | None = None
    for initial_inc in sorted(set(values)):
        @lru_cache(maxsize=None)
        def solve(position: int, inc_tile: int) -> tuple[int, tuple[tuple[int, int, tuple[int, ...]], ...]]:
            if position == len(values):
                return 7, ((7, 15, ()),)
            candidates: list[tuple[int, tuple[tuple[int, int, tuple[int, ...]], ...]]] = []

            if values[position] == inc_tile:
                length = 0
                while (
                    length < 16
                    and position + length < len(values)
                    and values[position + length] == (inc_tile + length) & 0xFFFF
                ):
                    length += 1
                for count in range(1, length + 1):
                    cost, tail = solve(position + count, (inc_tile + count) & 0xFFFF)
                    candidates.append((6 + cost, ((0, count - 1, ()),) + tail))

            for mode, step in ((4, 0), (5, 1), (6, -1)):
                maximum = run_length(values, position, step)
                for count in range(1, maximum + 1):
                    cost, tail = solve(position + count, inc_tile)
                    candidates.append(
                        (7 + bits_count + cost, ((mode, count - 1, (values[position],)),) + tail)
                    )

            for count in range(1, min(15, len(values) - position) + 1):
                cost, tail = solve(position + count, inc_tile)
                literal = tuple(values[position:position + count])
                candidates.append((7 + count * bits_count + cost, ((7, count - 1, literal),) + tail))
            return min(candidates, key=lambda item: item[0])

        cost, commands = solve(0, initial_inc)
        candidate = (cost, initial_inc, commands)
        if best is None or candidate[0] < best[0]:
            best = candidate

    assert best is not None
    _cost, inc_tile, commands = best
    writer = BitWriter()
    for mode, repeat, operands in commands:
        if mode <= 1:
            writer.write((mode << 4) | repeat, 6)
        else:
            writer.write((mode << 4) | repeat, 7)
        for value in operands:
            writer.write(value, bits_count)
    header = bytes((bits_count, 0)) + inc_tile.to_bytes(2, "big") + static_tile.to_bytes(2, "big")
    return header + writer.to_bytes()
