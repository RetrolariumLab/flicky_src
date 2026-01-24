#!/usr/bin/env python3
"""
Decompress Nemesis and Enigma compressed data from Flicky ROM.

Uses Python decompressor modules:
- tools/nemesis_dec.py for Nemesis compression
- tools/enigma_dec.py for Enigma compression
"""

import os
import sys
import argparse
from pathlib import Path

# Add tools directory to path for imports
TOOLS_DIR = Path(__file__).parent.parent / 'tools'
sys.path.insert(0, str(TOOLS_DIR))

import nemesis_dec
import enigma_dec


def decompress_nemesis(input_file: Path, output_file: Path) -> tuple:
    """
    Decompress Nemesis file.
    Returns (success, message).
    """
    try:
        with open(input_file, 'rb') as f:
            data = f.read()

        result = nemesis_dec.decompress(data)

        with open(output_file, 'wb') as f:
            f.write(result)

        header = (data[0] << 8) | data[1]
        tiles = header & 0x7FFF
        msg = f"Decompressed {len(data)} -> {len(result)} bytes ({tiles} tiles)"
        return True, msg
    except Exception as e:
        return False, str(e)


def decompress_enigma(input_file: Path, output_file: Path, base_tile: int = 0) -> tuple:
    """
    Decompress Enigma file.
    Returns (success, message).
    """
    try:
        with open(input_file, 'rb') as f:
            data = f.read()

        result = enigma_dec.decompress(data, base_tile)

        with open(output_file, 'wb') as f:
            f.write(result)

        msg = f"Decompressed {len(data)} -> {len(result)} bytes"
        return True, msg
    except Exception as e:
        return False, str(e)


def process_compressed_files(data_dir: Path, subdir: str, decompress_func,
                             verbose: bool = False, **kwargs):
    """
    Process all compressed files in a subdirectory.

    Args:
        data_dir: Base data directory
        subdir: Subdirectory name (e.g., 'artnem', 'arteni')
        decompress_func: Decompression function to use
        verbose: Show detailed output
        **kwargs: Extra arguments to pass to decompress_func

    Returns:
        (success_count, total_count)
    """
    compress_dir = data_dir / subdir
    if not compress_dir.exists():
        print(f"  Directory not found: {compress_dir}")
        return 0, 0

    output_dir = compress_dir / 'uncompressed'
    output_dir.mkdir(exist_ok=True)

    bin_files = list(compress_dir.glob('*.bin'))
    if not bin_files:
        return 0, 0

    success = 0
    for bin_file in sorted(bin_files):
        output_file = output_dir / bin_file.name
        ok, msg = decompress_func(bin_file, output_file, **kwargs)

        if ok:
            success += 1
            if verbose:
                print(f"    {bin_file.name}: {msg}")
        else:
            if verbose:
                print(f"    {bin_file.name}: FAILED - {msg}")

    return success, len(bin_files)


def main():
    parser = argparse.ArgumentParser(
        description='Decompress Nemesis and Enigma data from Flicky ROM'
    )
    parser.add_argument(
        '--data-dir', default='data',
        help='Data directory (default: data)'
    )
    parser.add_argument(
        '-v', '--verbose', action='store_true',
        help='Show detailed output'
    )

    args = parser.parse_args()
    data_dir = Path(args.data_dir)

    if not data_dir.exists():
        print(f'Error: Data directory not found: {data_dir}')
        return 1

    total_success = 0
    total_files = 0

    # Process Nemesis files
    print(f'Processing Nemesis files in {data_dir}/artnem/')
    success, total = process_compressed_files(
        data_dir, 'artnem', decompress_nemesis, args.verbose
    )
    total_success += success
    total_files += total
    print(f'  {success}/{total} files decompressed')
    if success > 0:
        print(f'  -> saved to artnem/uncompressed/')
    print()

    # Process Enigma files
    print(f'Processing Enigma files in {data_dir}/arteni/')
    success, total = process_compressed_files(
        data_dir, 'arteni', decompress_enigma, args.verbose, base_tile=0
    )
    total_success += success
    total_files += total
    print(f'  {success}/{total} files decompressed')
    if success > 0:
        print(f'  -> saved to arteni/uncompressed/')
    print()

    # Summary
    print('=' * 50)
    print(f'Total: {total_success}/{total_files} files decompressed')

    return 0


if __name__ == '__main__':
    sys.exit(main())
