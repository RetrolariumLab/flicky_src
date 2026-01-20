#!/usr/bin/env python3
"""
Extract symbols from AS assembler listing file (.lst)

Parses the listing format:
  - Code labels:  "  156/     200 :                     Reset:"
  - EQU constants: "(1)   2/       0 : =$A10008             IO_CT1_CTRL equ"

Output: Simple text format (address<tab>symbol) for use with bintrace_parser.py
"""

import re
import sys
import argparse
from collections import defaultdict

def extract_symbols(lst_path):
    """Extract symbols from AS assembler listing file."""
    symbols = {}  # address -> symbol name

    # Pattern for labels at start of line (no hex data before label)
    # Example: "     156/     200 :                     Reset:"
    # The format has fixed columns: line/addr : [spaces or hex] label:
    label_no_data_pattern = re.compile(
        r'^\s*\d+/\s*([0-9A-Fa-f]+)\s*:\s{20,}(\w+):',
        re.MULTILINE
    )

    # Pattern for labels with hex data before them
    # Example: "      94/     100 : 5345 4741 204D      CopyRights:"
    label_with_data_pattern = re.compile(
        r'^\s*\d+/\s*([0-9A-Fa-f]+)\s*:\s+(?:[0-9A-Fa-f]{2,4}\s+)+\s*(\w+):',
        re.MULTILINE
    )

    # Pattern for EQU constants: ": =$VALUE  NAME equ"
    # Example: "(1)   2/       0 : =$A10008             IO_CT1_CTRL equ"
    equ_pattern = re.compile(
        r':\s*=\$([0-9A-Fa-f]+)\s+(\w+)\s+equ',
        re.MULTILINE
    )

    print(f"Reading {lst_path}...", file=sys.stderr)

    with open(lst_path, 'r', encoding='latin-1') as f:
        content = f.read()

    # Extract labels without hex data (pure code labels)
    for match in label_no_data_pattern.finditer(content):
        addr = int(match.group(1), 16)
        name = match.group(2)
        # Prefer named labels over loc_ labels
        if addr not in symbols or symbols[addr].startswith('loc_'):
            symbols[addr] = name

    # Extract labels with hex data (data definitions)
    for match in label_with_data_pattern.finditer(content):
        addr = int(match.group(1), 16)
        name = match.group(2)
        if addr not in symbols:
            symbols[addr] = name

    # Extract EQU constants (RAM/IO addresses)
    for match in equ_pattern.finditer(content):
        addr = int(match.group(1), 16)
        name = match.group(2)
        if addr not in symbols:
            symbols[addr] = name

    return symbols

def filter_symbols(symbols, include_loc=False, include_word=False,
                   min_addr=None, max_addr=None):
    """Filter symbols based on criteria."""
    filtered = {}

    for addr, name in symbols.items():
        # Address range filter
        if min_addr is not None and addr < min_addr:
            continue
        if max_addr is not None and addr > max_addr:
            continue

        # Name filters
        if not include_loc and name.startswith('loc_'):
            continue
        if not include_word and (name.startswith('word_') or
                                  name.startswith('byte_') or
                                  name.startswith('dword_') or
                                  name.startswith('unk_')):
            continue

        filtered[addr] = name

    return filtered

def main():
    parser = argparse.ArgumentParser(
        description='Extract symbols from AS assembler listing file'
    )
    parser.add_argument('lst_file', help='Input .lst file')
    parser.add_argument('-o', '--output', help='Output file (default: stdout)')
    parser.add_argument('--include-loc', action='store_true',
                       help='Include loc_XXX labels')
    parser.add_argument('--include-generic', action='store_true',
                       help='Include word_/byte_/dword_ labels')
    parser.add_argument('--rom-only', action='store_true',
                       help='Only ROM addresses (0x000000-0x3FFFFF)')
    parser.add_argument('--ram-only', action='store_true',
                       help='Only RAM addresses (0xFF0000-0xFFFFFF)')
    parser.add_argument('--all', action='store_true',
                       help='Include all symbols (no filtering)')
    parser.add_argument('--stats', action='store_true',
                       help='Print statistics')
    parser.add_argument('--json', action='store_true',
                       help='Output as JSON')

    args = parser.parse_args()

    # Extract all symbols
    symbols = extract_symbols(args.lst_file)

    # Apply filters
    if args.all:
        filtered = symbols
    else:
        min_addr = None
        max_addr = None

        if args.rom_only:
            min_addr = 0
            max_addr = 0x3FFFFF
        elif args.ram_only:
            min_addr = 0xFF0000
            max_addr = 0xFFFFFF

        filtered = filter_symbols(
            symbols,
            include_loc=args.include_loc,
            include_word=args.include_generic,
            min_addr=min_addr,
            max_addr=max_addr
        )

    # Statistics
    if args.stats:
        print(f"Total symbols: {len(symbols)}", file=sys.stderr)
        print(f"Filtered symbols: {len(filtered)}", file=sys.stderr)

        # Count by type
        counts = defaultdict(int)
        for name in filtered.values():
            if name.startswith('loc_'):
                counts['loc_'] += 1
            elif name.startswith('sub_'):
                counts['sub_'] += 1
            elif name.startswith('word_'):
                counts['word_'] += 1
            elif name.startswith('byte_'):
                counts['byte_'] += 1
            elif name.startswith('dword_'):
                counts['dword_'] += 1
            elif '_' in name:
                prefix = name.split('_')[0] + '_'
                counts[prefix] += 1
            else:
                counts['named'] += 1

        print("\nSymbol types:", file=sys.stderr)
        for prefix, count in sorted(counts.items(), key=lambda x: -x[1]):
            print(f"  {prefix}: {count}", file=sys.stderr)

    # Output
    out = open(args.output, 'w') if args.output else sys.stdout

    if args.json:
        import json
        # Output as hex strings for JSON
        json_data = {f"0x{addr:06X}": name for addr, name in sorted(filtered.items())}
        json.dump(json_data, out, indent=2)
    else:
        # Simple format: address<tab>symbol
        for addr, name in sorted(filtered.items()):
            out.write(f"{addr:08X}\t{name}\n")

    if args.output:
        out.close()
        print(f"Written {len(filtered)} symbols to {args.output}", file=sys.stderr)

if __name__ == '__main__':
    main()
