#!/usr/bin/env python3
"""
Enigma Decompressor - Python port from C/68000
Based on working C implementation in tools/enigma_dec.c
"""


def decompress(data: bytes, base_tile: int = 0) -> bytes:
    """
    Decompress Enigma-compressed tilemap data.

    Args:
        data: Compressed data bytes
        base_tile: Base tile value to add to all tiles

    Returns:
        Decompressed tilemap data (big-endian words)
    """
    src = memoryview(data)
    pos = 0

    # Read header
    bits_count = src[pos]
    if bits_count >= 0x80:
        bits_count = bits_count - 0x100  # Sign extend
    pos += 1

    flags_byte = src[pos]
    if flags_byte >= 0x80:
        flags_byte = flags_byte - 0x100  # Sign extend
    pos += 1

    # Convert flags: ror.l #1, ror.w #1
    flags = flags_byte & 0xFFFFFFFF
    # ror.l #1
    flags = ((flags >> 1) | ((flags & 1) << 31)) & 0xFFFFFFFF
    # ror.w #1 (only low word)
    low = flags & 0xFFFF
    low = ((low >> 1) | ((low & 1) << 15)) & 0xFFFF
    flags = (flags & 0xFFFF0000) | low

    # Read inc_tile and static_tile (big-endian)
    inc_tile = ((src[pos] << 8) | src[pos + 1]) + base_tile
    pos += 2
    static_tile = ((src[pos] << 8) | src[pos + 1]) + base_tile
    pos += 2

    # Initialize bit buffer
    bit_buffer = (src[pos] << 8) | src[pos + 1]
    pos += 2
    bits_remaining = 16

    def refill():
        nonlocal bit_buffer, bits_remaining, pos
        if pos < len(src):
            bit_buffer = ((bit_buffer << 8) | src[pos]) & 0xFFFFFF
            pos += 1
        else:
            bit_buffer = (bit_buffer << 8) & 0xFFFFFF
        bits_remaining += 8

    def peek_bits(count):
        while bits_remaining < count:
            refill()
        shift = bits_remaining - count
        return (bit_buffer >> shift) & ((1 << count) - 1)

    def consume_bits(count):
        nonlocal bits_remaining
        bits_remaining -= count

    def get_bits(count):
        val = peek_bits(count)
        consume_bits(count)
        return val

    # Bit masks table
    bit_masks = [0] + [(1 << i) - 1 for i in range(1, 17)]

    def decode_tile():
        nonlocal bits_remaining, bit_buffer, pos
        tile = base_tile

        # Check vflip flag (bit 31)
        if flags & 0x80000000:
            bits_remaining -= 1
            if bit_buffer & (1 << bits_remaining):
                tile |= 0x1000

        # Check hflip flag (bit 15)
        if flags & 0x8000:
            bits_remaining -= 1
            if bit_buffer & (1 << bits_remaining):
                tile |= 0x0800

        # Read tile bits
        bits = bits_count
        if bits == 0:
            return tile

        if bits < 0:
            bits = -bits

        shift = bits_remaining - bits

        if shift > 0:
            val = (bit_buffer >> shift) & bit_masks[bits]
            tile += val
            consume_bits(bits)
        elif shift == 0:
            val = bit_buffer & bit_masks[bits]
            tile += val
            # Read new code word
            bit_buffer = (src[pos] << 8) | src[pos + 1]
            pos += 2
            bits_remaining = 16
        else:
            need = -shift
            val = bit_buffer << need
            next_byte = src[pos] if pos < len(src) else 0
            val |= (next_byte >> (8 - need)) & bit_masks[need]
            val &= bit_masks[bits]
            tile += val
            bits_remaining = 16 + shift
            bit_buffer = (src[pos] << 8) | src[pos + 1]
            pos += 2

        return tile

    output = bytearray()

    while True:
        code = get_bits(7)
        repeat = code
        bits_used = 7

        if code < 0x40:
            bits_used = 6
            repeat >>= 1
            # Put back 1 bit
            bits_remaining += 1

        # Consume the bits we actually used (already consumed 7, adjust if 6)
        if bits_used == 6:
            pass  # Already adjusted above

        mode = (repeat >> 4) & 0x07
        repeat = repeat & 0x0F

        if mode == 0 or mode == 1:
            # Write incrementing from inc_tile
            for _ in range(repeat + 1):
                output.append((inc_tile >> 8) & 0xFF)
                output.append(inc_tile & 0xFF)
                inc_tile = (inc_tile + 1) & 0xFFFF

        elif mode == 2 or mode == 3:
            # Write static_tile repeated
            for _ in range(repeat + 1):
                output.append((static_tile >> 8) & 0xFF)
                output.append(static_tile & 0xFF)

        elif mode == 4:
            # Decode tile and write repeated
            tile = decode_tile()
            for _ in range(repeat + 1):
                output.append((tile >> 8) & 0xFF)
                output.append(tile & 0xFF)

        elif mode == 5:
            # Decode tile and write incrementing
            tile = decode_tile()
            for _ in range(repeat + 1):
                output.append((tile >> 8) & 0xFF)
                output.append(tile & 0xFF)
                tile = (tile + 1) & 0xFFFF

        elif mode == 6:
            # Decode tile and write decrementing
            tile = decode_tile()
            for _ in range(repeat + 1):
                output.append((tile >> 8) & 0xFF)
                output.append(tile & 0xFF)
                tile = (tile - 1) & 0xFFFF

        elif mode == 7:
            if repeat == 0x0F:
                # End marker
                break
            # Decode tiles inline
            for _ in range(repeat + 1):
                tile = decode_tile()
                output.append((tile >> 8) & 0xFF)
                output.append(tile & 0xFF)

    return bytes(output)


if __name__ == '__main__':
    import sys
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} input.bin output.bin [base_tile]")
        sys.exit(1)

    with open(sys.argv[1], 'rb') as f:
        data = f.read()

    base = int(sys.argv[3], 0) if len(sys.argv) > 3 else 0
    result = decompress(data, base)

    with open(sys.argv[2], 'wb') as f:
        f.write(result)

    print(f"Decompressed {len(data)} -> {len(result)} bytes")
