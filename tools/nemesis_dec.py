#!/usr/bin/env python3
"""
Nemesis Decompressor - Python port from C/68000
Based on working C implementation in tools/nemesis_dec.c
"""


def decompress(data: bytes) -> bytes:
    """
    Decompress Nemesis-compressed tile data.

    Args:
        data: Compressed data bytes

    Returns:
        Decompressed tile data
    """
    src = memoryview(data)
    pos = 0

    # Read header: 2 bytes
    # High bit = XOR mode, lower 15 bits = number of TILES
    header = (src[pos] << 8) | src[pos + 1]
    pos += 2

    xor_mode = (header & 0x8000) != 0
    output_count = (header & 0x7FFF) * 8  # Convert tiles to 8-nybble groups

    if output_count == 0:
        return b''

    # Build code table
    code_table = [None] * 256  # Each entry: (code_length, nybble, run_length)

    while True:
        val = src[pos]
        pos += 1
        if val == 0xFF:
            break

        palette_index = val & 0x0F

        while True:
            val = src[pos]
            pos += 1

            if val >= 0x80:
                if val == 0xFF:
                    break
                palette_index = val & 0x0F
                continue

            # Parse code entry
            run_length = ((val >> 4) & 7) + 1
            code_length = val & 0x0F
            if code_length == 0:
                code_length = 8

            code_byte = src[pos]
            pos += 1

            # Fill lookup table entries
            if code_length < 8:
                base = code_byte << (8 - code_length)
                num_entries = 1 << (8 - code_length)
                for i in range(num_entries):
                    idx = base | i
                    code_table[idx] = (code_length, palette_index, run_length)
            else:
                code_table[code_byte] = (code_length, palette_index, run_length)

        if val == 0xFF:
            break

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
        nonlocal bits_remaining
        while bits_remaining < count:
            refill()
        shift = bits_remaining - count
        return (bit_buffer >> shift) & ((1 << count) - 1)

    def consume_bits(count):
        nonlocal bits_remaining
        bits_remaining -= count

    # Output state
    output = bytearray()
    nybble_buffer = 0
    nybbles_in_buffer = 0
    xor_buffer = 0

    def output_nybble(nybble):
        nonlocal nybble_buffer, nybbles_in_buffer, xor_buffer, output_count
        nybble_buffer = ((nybble_buffer << 4) | (nybble & 0xF)) & 0xFFFFFFFF
        nybbles_in_buffer += 1

        if nybbles_in_buffer == 8:
            out = nybble_buffer
            if xor_mode:
                out ^= xor_buffer
                xor_buffer = out

            output.append((out >> 24) & 0xFF)
            output.append((out >> 16) & 0xFF)
            output.append((out >> 8) & 0xFF)
            output.append(out & 0xFF)

            nybble_buffer = 0
            nybbles_in_buffer = 0
            output_count -= 1

            return output_count == 0
        return False

    # Process codes
    while output_count > 0:
        lookup = peek_bits(8)
        entry = code_table[lookup]

        if entry is not None:
            code_length, nybble, run_length = entry
            consume_bits(code_length)
            for _ in range(run_length):
                if output_nybble(nybble):
                    return bytes(output)
        elif (lookup >> 2) == 0x3F:
            # Inline mode
            consume_bits(6)
            run_length = peek_bits(3) + 1
            consume_bits(3)
            nybble = peek_bits(4)
            consume_bits(4)
            for _ in range(run_length):
                if output_nybble(nybble):
                    return bytes(output)
        else:
            consume_bits(1)

    return bytes(output)


if __name__ == '__main__':
    import sys
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} input.bin output.bin")
        sys.exit(1)

    with open(sys.argv[1], 'rb') as f:
        data = f.read()

    result = decompress(data)

    with open(sys.argv[2], 'wb') as f:
        f.write(result)

    header = (data[0] << 8) | data[1]
    tiles = header & 0x7FFF
    print(f"Decompressed {len(data)} -> {len(result)} bytes ({tiles} tiles)")
