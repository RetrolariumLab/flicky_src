#!/usr/bin/env python3
"""
Extract binary data addresses from Flicky listing file.

Parses flicky.lst to find all binclude directives and generates
data_addrs.txt with format: name,start,end,subdir

Categories:
- artnem/   : Nemesis-compressed tiles
- arteni/   : Enigma-compressed tilemaps
- artunc/   : Uncompressed tiles and sprites
- mappings/ : Tile mappings
- sound/    : PCM samples and sound data (Z80)
- other/    : Other data (tables, palettes)
"""

import os
import re
import sys
import argparse


def classify_data(name: str) -> str:
    """Classify data segment into category based on name patterns."""
    name_lower = name.lower()

    # Sound/Z80 data
    if any(p in name_lower for p in ['z80', 'sound', 'pcm', 'music', 'sfx', 'dac']):
        return 'sound'

    # Mappings
    if any(p in name_lower for p in ['map', 'mapping', 'layout']):
        return 'mappings'

    # Nemesis-compressed tiles (known from code analysis)
    # These are decompressed via Nem_Decomp in flicky.s
    nemesis_compressed = [
        'LevelTiles',
        'SpritesTiles',
        'ScoresTiles',
        'FlickyLogoTiles',
        'ExitTiles',
        'SegaTiles',
    ]
    if name in nemesis_compressed:
        return 'artnem'

    # Enigma-compressed tilemaps
    if 'enigma' in name_lower:
        return 'arteni'

    # Uncompressed tiles and sprites (1BPP fonts, sega logo)
    if any(p in name_lower for p in ['tiles', 'sprite', 'art', 'gfx', 'graphics', 'logo', '1bpp']):
        return 'artunc'

    # Everything else
    return 'other'


def main():
    parser = argparse.ArgumentParser(
        description='Extract binary data addresses from Flicky listing'
    )
    parser.add_argument(
        'listing',
        nargs='?',
        default='flicky.lst',
        help='Listing file (default: flicky.lst)'
    )
    parser.add_argument(
        '--data-dir',
        default='data',
        help='Data directory to check file sizes'
    )
    parser.add_argument(
        '-o', '--output',
        default='data/data_addrs.txt',
        help='Output addresses file (default: data/data_addrs.txt)'
    )
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Verbose output'
    )

    args = parser.parse_args()

    if not os.path.exists(args.listing):
        print(f'Error: Listing file "{args.listing}" not found!')
        return 1

    # Pattern to match binclude lines in listing
    # Format: "   line/  addr :    label: binclude "path""
    pattern = re.compile(r'^\s*\d+/\s*([0-9A-Fa-f]+)\s*:\s*(\w+):\s*binclude\s+"([^"]+)"')

    entries = []

    print(f'Parsing {args.listing}...')
    with open(args.listing, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            match = pattern.match(line)
            if match:
                listing_addr = match.group(1)
                label = match.group(2)
                filepath = match.group(3)

                # Extract address from label name (e.g., byte_11A644 -> 11A644)
                # For labels with hex address suffix, use that address
                # For other labels, use listing address
                addr_match = re.search(r'_([0-9A-Fa-f]{5,6})$', label)
                if addr_match:
                    addr_hex = addr_match.group(1)
                else:
                    addr_hex = listing_addr

                # Get filename without path and extension
                filename = os.path.basename(filepath)
                name = os.path.splitext(filename)[0]

                # Remove data_ prefix if present
                if name.startswith('data_'):
                    name = name[5:]

                start_addr = int(addr_hex, 16)

                # Get file size to calculate end address
                full_path = os.path.join(os.path.dirname(args.listing), filepath)
                if os.path.exists(full_path):
                    size = os.path.getsize(full_path)
                    end_addr = start_addr + size
                elif os.path.exists(filepath):
                    size = os.path.getsize(filepath)
                    end_addr = start_addr + size
                else:
                    print(f'  Warning: File not found: {filepath}')
                    continue

                subdir = classify_data(name)
                entries.append((name, start_addr, end_addr, subdir))

    # Sort by start address
    entries.sort(key=lambda x: x[1])

    # Count by category
    categories = {}
    for name, start, end, subdir in entries:
        categories[subdir] = categories.get(subdir, 0) + 1

    print(f'\nFound {len(entries)} entries:')
    for cat, count in sorted(categories.items()):
        print(f'  {cat}/: {count}')

    # Write output
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    with open(args.output, 'w') as f:
        f.write('# Flicky ROM binary data segments\n')
        f.write('# Format: name,start,end,subdir\n')
        f.write(f'# Generated from {os.path.basename(args.listing)}\n')
        f.write('#\n')
        f.write('# Categories:\n')
        f.write('#   artnem/   - Nemesis-compressed tiles\n')
        f.write('#   arteni/   - Enigma-compressed tilemaps\n')
        f.write('#   artunc/   - Uncompressed tiles and sprites\n')
        f.write('#   mappings/ - Tile mappings\n')
        f.write('#   sound/    - PCM samples and sound data (Z80)\n')
        f.write('#   other/    - Other data (tables, palettes)\n')
        f.write('\n')

        for name, start, end, subdir in entries:
            f.write(f'{name},0x{start:X},0x{end:X},{subdir}\n')
            if args.verbose:
                size = end - start
                print(f'  {name}: 0x{start:X}-0x{end:X} ({size} bytes) -> {subdir}/')

    print(f'\nWritten to: {args.output}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
