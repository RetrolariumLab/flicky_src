#!/usr/bin/env python3
"""
Extract binary data segments from Flicky ROM.

Reads data_addrs.txt with format:
    name,start,end
    sega_tiles,0x51A,0x856

Creates data/data_{name}.bin for each entry.
"""

import os
import sys
import argparse


def main():
    parser = argparse.ArgumentParser(description='Extract binary data from Flicky ROM')
    parser.add_argument('-f', '--rom-file', required=True,
                        help='Original ROM file')
    parser.add_argument('-o', '--output', default='data',
                        help='Output directory (default: data)')
    parser.add_argument('-a', '--addrs', default='data/data_addrs.txt',
                        help='Addresses file (default: data/data_addrs.txt)')

    args = parser.parse_args()

    # Check if ROM file exists
    if not os.path.exists(args.rom_file):
        print(f'Error: ROM file "{args.rom_file}" not found!')
        return 1

    # Check if addresses file exists
    if not os.path.exists(args.addrs):
        print(f'Error: Addresses file "{args.addrs}" not found!')
        return 1

    # Create output directory if needed
    os.makedirs(args.output, exist_ok=True)

    # Load ROM data
    print(f'Loading ROM: {args.rom_file}')
    with open(args.rom_file, 'rb') as f:
        rom_data = f.read()
    print(f'ROM size: 0x{len(rom_data):X} ({len(rom_data)} bytes)')

    # Parse addresses file
    print(f'Loading addresses from: {args.addrs}')
    entries = []
    with open(args.addrs, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = line.split(',')
            if len(parts) != 3:
                print(f'Warning: invalid line: {line}')
                continue
            name = parts[0].strip()
            start = int(parts[1].strip(), 16)
            end = int(parts[2].strip(), 16)
            entries.append((name, start, end))

    print(f'Found {len(entries)} entries to extract\n')

    # Extract all segments
    success_count = 0
    for name, start, end in entries:
        size = end - start
        output_file = os.path.join(args.output, f'data_{name}.bin')

        if start >= len(rom_data) or end > len(rom_data):
            print(f'Error: {name} address out of range (0x{start:X}-0x{end:X})')
            continue

        data = rom_data[start:end]
        with open(output_file, 'wb') as f:
            f.write(data)

        print(f'{name}: 0x{start:X}-0x{end:X} ({size} bytes) -> {output_file}')
        success_count += 1

    print(f'\nExtracted {success_count}/{len(entries)} segments')
    return 0 if success_count == len(entries) else 1


if __name__ == '__main__':
    sys.exit(main())
