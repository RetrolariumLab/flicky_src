#!/usr/bin/env python3
"""
Initialize Flicky project from original ROM.

Steps:
1. Check original ROM exists
2. Extract data segments from original ROM
3. Build ROM from source
4. Create reference ROM (copy of first build)
"""

import os
import sys
import shutil
import argparse
import subprocess


def main():
    parser = argparse.ArgumentParser(description='Initialize Flicky project')
    parser.add_argument('--orig-rom', required=True, help='Original ROM file')
    parser.add_argument('--ref-rom', required=True, help='Reference ROM file (output)')
    parser.add_argument('--data-dir', required=True, help='Data directory')
    parser.add_argument('--data-addrs', required=True, help='Data addresses file')
    parser.add_argument('--source', required=True, help='Assembly source file')
    parser.add_argument('--output', required=True, help='Output ROM file')
    parser.add_argument('--as-bin', required=True, help='AS assembler binary')
    parser.add_argument('--p2bin', required=True, help='P2BIN converter')
    parser.add_argument('--as-args', default='', help='AS assembler arguments')

    args = parser.parse_args()

    # Step 1: Check original ROM exists
    if not os.path.exists(args.orig_rom):
        print()
        print('ERROR: Original ROM not found!')
        print()
        print('Please place the original ROM file in the project root:')
        print(f'  {args.orig_rom}')
        print()
        return 1

    print('=== Initializing project ===')
    print()

    # Step 2: Extract data segments
    print('Step 1: Extracting data from original ROM...')
    scripts_dir = os.path.dirname(os.path.abspath(__file__))
    split_script = os.path.join(scripts_dir, 'split_data_from_rom.py')

    result = subprocess.run([
        sys.executable, split_script,
        '--rom-file', args.orig_rom,
        '--output', args.data_dir,
        '--addrs', args.data_addrs
    ])

    if result.returncode != 0:
        print('ERROR: Failed to extract data!')
        return 1
    print()

    # Step 3: Build ROM from source
    print('Step 2: Building ROM from source...')
    build_script = os.path.join(scripts_dir, 'build_rom.py')

    result = subprocess.run([
        sys.executable, build_script,
        '--source', args.source,
        '--output', args.output,
        '--as-bin', args.as_bin,
        '--p2bin', args.p2bin,
        '--as-args', args.as_args
    ])

    if result.returncode != 0:
        print('ERROR: Failed to build ROM!')
        return 1
    print()

    # Step 4: Create reference ROM (copy of first build)
    print('Step 3: Creating reference ROM...')
    shutil.copy2(args.output, args.ref_rom)
    print(f'  {args.output} -> {args.ref_rom}')
    print()

    print('=== Project initialized successfully! ===')
    print()
    print('Reference ROM created. You can now:')
    print('  make build   - Build ROM from source')
    print('  make compare - Compare with reference')
    return 0


if __name__ == '__main__':
    sys.exit(main())
