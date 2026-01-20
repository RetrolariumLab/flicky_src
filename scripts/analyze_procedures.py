#!/usr/bin/env python3
"""
ROM Procedure Analyzer (Parallel)

Analyzes which procedures affect visual output by:
1. Disabling each sub_XXXXX procedure (adding RTS at start)
2. Building modified ROM
3. Comparing screenshots with reference during TAS playback
4. Recording first frame where difference occurs

Supports parallel execution with multiple workers.
"""

import os
import sys
import re
import subprocess
import shutil
import argparse
import csv
import tempfile
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor, as_completed
from multiprocessing import Manager
import time


def find_procedures(source_file):
    """Find all sub_XXXXX procedures in the source file."""
    procedures = []
    pattern = re.compile(r'^(sub_[0-9A-Fa-f]+):')

    with open(source_file, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, 1):
            match = pattern.match(line)
            if match:
                procedures.append({
                    'name': match.group(1),
                    'line': line_num
                })

    return procedures


def load_procedures_from_file(procedures_file, source_file):
    """Load procedure names from file and find their line numbers in source."""
    procedures = []

    # Read procedure names from file (one per line)
    with open(procedures_file, 'r', encoding='utf-8') as f:
        proc_names = [line.strip() for line in f if line.strip()]

    # Find line numbers in source file
    # Support both sub_* and loc_* patterns
    pattern = re.compile(r'^((sub|loc)_[0-9A-Fa-f]+):')
    line_map = {}

    with open(source_file, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, 1):
            match = pattern.match(line)
            if match:
                line_map[match.group(1)] = line_num

    # Build procedure list with line numbers
    for name in proc_names:
        if name in line_map:
            procedures.append({
                'name': name,
                'line': line_map[name]
            })
        else:
            print(f"Warning: Procedure {name} not found in source file")

    return procedures


def disable_procedure(source_file, proc_name):
    """Add 'rts' after procedure label to disable it."""
    pattern = re.compile(rf'^({re.escape(proc_name)}:.*?)$', re.MULTILINE)

    with open(source_file, 'r', encoding='utf-8') as f:
        content = f.read()

    def replacer(match):
        return match.group(1) + '\n\trts\t; DISABLED BY ANALYZER'

    new_content = pattern.sub(replacer, content, count=1)

    with open(source_file, 'w', encoding='utf-8') as f:
        f.write(new_content)


def setup_worker_dir(project_dir, proc_name, temp_base):
    """Create isolated worker directory with project copy."""
    worker_dir = os.path.join(temp_base, proc_name)

    # Clean and recreate
    if os.path.exists(worker_dir):
        shutil.rmtree(worker_dir)
    os.makedirs(worker_dir)

    # Copy essential files
    src_file = os.path.join(project_dir, 'flicky.s')
    shutil.copy(src_file, worker_dir)

    # Copy Makefile
    shutil.copy(os.path.join(project_dir, 'Makefile'), worker_dir)

    # Copy directories (symlinks require admin on Windows)
    for dirname in ['bin', 'data', 'src', 'scripts']:
        src_path = os.path.join(project_dir, dirname)
        dst_path = os.path.join(worker_dir, dirname)
        if os.path.exists(src_path) and not os.path.exists(dst_path):
            shutil.copytree(src_path, dst_path)

    return worker_dir


def build_rom(worker_dir):
    """Build ROM using make."""
    result = subprocess.run(
        ['make', 'build'],
        cwd=worker_dir,
        capture_output=True,
        text=True
    )
    return result.returncode == 0, result.stderr


def run_comparison(gens_exe, rom_file, movie_file, reference_dir, diffs_dir,
                   proc_name, interval=20, max_frames=90000, max_diffs=10, max_memory_diffs=10,
                   frameskip=0, window_x=None, window_y=None, diff_color=None, memory_diffs=False):
    """Run emulator in comparison mode.

    Returns: (first_visual_diff_frame, visual_diff_count, first_memory_diff_frame, memory_diff_count)
    """
    proc_diffs_dir = os.path.join(diffs_dir, proc_name)
    if os.path.exists(proc_diffs_dir):
        for f in os.listdir(proc_diffs_dir):
            os.remove(os.path.join(proc_diffs_dir, f))
    else:
        os.makedirs(proc_diffs_dir)

    # Emulator must run from its own directory to find DLLs
    gens_dir = os.path.dirname(gens_exe)

    # Convert all paths to absolute (gens runs from its own dir)
    rom_file = os.path.abspath(rom_file)
    movie_file = os.path.abspath(movie_file)
    reference_dir = os.path.abspath(reference_dir)
    proc_diffs_dir = os.path.abspath(proc_diffs_dir)

    cmd = [
        gens_exe,
        '-rom', rom_file,
        '-play', movie_file,
        '-screenshot-interval', str(interval),
        '-reference-dir', reference_dir,
        '-screenshot-dir', proc_diffs_dir,
        '-max-frames', str(max_frames),
        '-max-diffs', str(max_diffs),
        '-max-memory-diffs', str(max_memory_diffs),
        '-turbo',
        '-frameskip', str(frameskip),
        '-nosound'
    ]

    # Add window position if specified
    if window_x is not None:
        cmd.extend(['-window-x', str(window_x)])
    if window_y is not None:
        cmd.extend(['-window-y', str(window_y)])

    # Add diff color if specified
    if diff_color:
        cmd.extend(['-diff-color', diff_color])

    # Memory diffs mode: if disabled, tell emulator not to save memory diff files
    if not memory_diffs:
        cmd.extend(['-no-memory-diffs', '1'])

    subprocess.run(cmd, capture_output=True, cwd=gens_dir)

    # Find visual diffs (PNG files, excluding _diff.png files which are visualizations)
    visual_diffs = sorted([f for f in os.listdir(proc_diffs_dir)
                          if f.endswith('.png') and not f.endswith('_diff.png')])

    # Find memory diffs (_memdiff.csv files contain actual byte differences)
    memory_diffs = sorted([f for f in os.listdir(proc_diffs_dir) if f.endswith('_memdiff.csv')])

    first_visual_diff = None
    first_memory_diff = None

    if visual_diffs:
        first_visual_diff = int(visual_diffs[0].replace('.png', ''))

    if memory_diffs:
        # Memory diff files are named XXXXXX_memdiff.csv
        first_memory_diff = int(memory_diffs[0].replace('_memdiff.csv', ''))

    # Remove directory only if empty
    if not visual_diffs and not memory_diffs:
        os.rmdir(proc_diffs_dir)

    return first_visual_diff, len(visual_diffs), first_memory_diff, len(memory_diffs)


def analyze_single_procedure(args_tuple):
    """Analyze a single procedure (worker function)."""
    (proc, project_dir, temp_base, gens_exe, movie_file,
     reference_dir, diffs_dir, interval, max_frames, max_diffs, max_memory_diffs, frameskip,
     worker_index, grid_cols, window_width, window_height, diff_color, memory_diffs) = args_tuple

    proc_name = proc['name']

    # Calculate window position based on worker index (grid layout)
    col = worker_index % grid_cols
    row = worker_index // grid_cols
    window_x = col * window_width
    window_y = row * window_height

    try:
        # Setup worker directory (unique per procedure)
        worker_dir = setup_worker_dir(project_dir, proc_name, temp_base)
        source_file = os.path.join(worker_dir, 'flicky.s')
        rom_file = os.path.join(worker_dir, 'fbuilt.bin')

        # Disable procedure
        disable_procedure(source_file, proc_name)

        # Build ROM
        success, error = build_rom(worker_dir)
        if not success:
            return {
                'procedure': proc_name,
                'line': proc['line'],
                'first_visual_frame': 'BUILD_ERROR',
                'visual_diff_count': 0,
                'first_memory_frame': '',
                'memory_diff_count': 0,
                'status': 'error'
            }

        # Run comparison (now returns both visual and memory diffs)
        first_visual, visual_count, first_memory, memory_count = run_comparison(
            gens_exe, rom_file, movie_file, reference_dir, diffs_dir,
            proc_name, interval, max_frames, max_diffs, max_memory_diffs, frameskip,
            window_x, window_y, diff_color, memory_diffs
        )

        # Determine status based on what kind of diffs were found
        if first_visual is not None and first_memory is not None:
            status = 'both'  # Both visual and memory differences
        elif first_visual is not None:
            status = 'visual'  # Only visual differences
        elif first_memory is not None:
            status = 'memory'  # Only memory differences (no visual change)
        else:
            status = 'no_change'

        return {
            'procedure': proc_name,
            'line': proc['line'],
            'first_visual_frame': first_visual if first_visual else '',
            'visual_diff_count': visual_count,
            'first_memory_frame': first_memory if first_memory else '',
            'memory_diff_count': memory_count,
            'status': status
        }

    except Exception as e:
        return {
            'procedure': proc_name,
            'line': proc['line'],
            'first_visual_frame': f'ERROR: {str(e)}',
            'visual_diff_count': 0,
            'first_memory_frame': '',
            'memory_diff_count': 0,
            'status': 'error'
        }


def analyze_procedures(args):
    """Main analysis loop with parallel execution."""
    project_dir = str(Path(args.project_dir).resolve())

    # Check procedures file first (required)
    if not args.procedures_file:
        print("Error: --procedures-file is required")
        print("")
        print("To generate a list of unanalyzed procedures, run:")
        print("  make find-unanalyzed")
        print("")
        print("This will create unanalyzed_procedures.txt with procedures that need analysis.")
        return 1

    procedures_file = os.path.join(project_dir, args.procedures_file)
    if not os.path.exists(procedures_file):
        print(f"Error: Procedures file not found: {procedures_file}")
        print("")
        print("To generate a list of unanalyzed procedures, run:")
        print("  make find-unanalyzed")
        return 1

    # Build other paths
    source_file = os.path.join(project_dir, args.source)
    movie_file = os.path.join(project_dir, args.movie)
    reference_dir = os.path.join(project_dir, args.reference)
    diffs_dir = os.path.join(project_dir, args.diffs)
    gens_exe = os.path.join(project_dir, args.gens)
    results_file = os.path.join(project_dir, args.output)

    # Verify paths
    if not os.path.exists(source_file):
        print(f"Error: Source file not found: {source_file}")
        return 1
    if not os.path.exists(reference_dir):
        print(f"Error: Reference directory not found: {reference_dir}")
        return 1
    if not os.path.exists(gens_exe):
        print(f"Error: Emulator not found: {gens_exe}")
        return 1
    if not os.path.exists(movie_file):
        print(f"Error: Movie file not found: {movie_file}")
        return 1

    # Load procedures from file
    print(f"Loading procedures from {args.procedures_file}...")
    procedures = load_procedures_from_file(procedures_file, source_file)
    print(f"Loaded {len(procedures)} procedures from file")

    if args.limit:
        procedures = procedures[:args.limit]
        print(f"Limited to first {args.limit} procedures")

    if args.start_from:
        start_idx = 0
        for i, proc in enumerate(procedures):
            if proc['name'] == args.start_from:
                start_idx = i
                break
        procedures = procedures[start_idx:]
        print(f"Starting from {args.start_from} ({len(procedures)} remaining)")

    # Create directories
    os.makedirs(diffs_dir, exist_ok=True)

    # Create temp directory for workers
    temp_base = os.path.join(project_dir, 'tmp', 'analyze_workers')
    if os.path.exists(temp_base):
        shutil.rmtree(temp_base)
    os.makedirs(temp_base)

    # Grid layout for window positioning
    grid_cols = args.grid_cols
    window_width = 320
    window_height = 240

    print(f"\nAnalyzing {len(procedures)} procedures with {args.workers} workers...")
    print(f"Window grid: {grid_cols} columns, {window_width}x{window_height} per window")
    print(f"Memory diffs: {'ENABLED' if args.memory_diffs else 'DISABLED (visual-only)'}")
    print("=" * 60)

    # Prepare tasks with worker index for window positioning
    tasks = []
    for i, proc in enumerate(procedures):
        worker_index = i % args.workers  # Cycle through worker slots
        tasks.append((
            proc, project_dir, temp_base, gens_exe, movie_file,
            reference_dir, diffs_dir, args.interval, args.max_frames, args.max_diffs,
            args.max_memory_diffs, args.frameskip,
            worker_index, grid_cols, window_width, window_height, args.diff_color,
            args.memory_diffs
        ))

    # Run in parallel
    results = []
    completed = 0
    start_time = time.time()

    with ProcessPoolExecutor(max_workers=args.workers) as executor:
        futures = {executor.submit(analyze_single_procedure, task): task[0] for task in tasks}

        for future in as_completed(futures):
            proc = futures[future]
            result = future.result()
            results.append(result)
            completed += 1

            # Progress output
            # V=visual, M=memory only, B=both, E=error, .=no change
            status_map = {'visual': 'V', 'memory': 'M', 'both': 'B', 'error': 'E', 'no_change': '.'}
            status_char = status_map.get(result['status'], '?')
            elapsed = time.time() - start_time
            rate = completed / elapsed if elapsed > 0 else 0
            eta = (len(procedures) - completed) / rate if rate > 0 else 0

            print(f"\r[{completed}/{len(procedures)}] {status_char} {result['procedure']:<20} "
                  f"({rate:.1f}/s, ETA: {eta/60:.0f}m)      ", end='', flush=True)

    print("\n" + "=" * 60)

    # Cleanup temp directories
    print("Cleaning up temporary files...")
    shutil.rmtree(temp_base, ignore_errors=True)

    # Sort results by line number
    results.sort(key=lambda x: x['line'] if isinstance(x['line'], int) else 0)

    # Save results
    print(f"Saving results to {results_file}...")
    with open(results_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'procedure', 'line', 'first_visual_frame', 'visual_diff_count',
            'first_memory_frame', 'memory_diff_count', 'status'
        ])
        writer.writeheader()
        writer.writerows(results)

    # Summary
    visual_count = sum(1 for r in results if r['status'] == 'visual')
    memory_count = sum(1 for r in results if r['status'] == 'memory')
    both_count = sum(1 for r in results if r['status'] == 'both')
    no_change_count = sum(1 for r in results if r['status'] == 'no_change')
    error_count = sum(1 for r in results if r['status'] == 'error')
    elapsed = time.time() - start_time

    print(f"\nSummary:")
    print(f"  Visual only:   {visual_count}")
    print(f"  Memory only:   {memory_count}")
    print(f"  Both:          {both_count}")
    print(f"  No change:     {no_change_count}")
    print(f"  Errors:        {error_count}")
    print(f"  Total:         {len(results)}")
    print(f"  Time:          {elapsed/60:.1f} minutes")

    return 0


def main():
    parser = argparse.ArgumentParser(description='Analyze ROM procedures for visual impact')
    parser.add_argument('--project-dir', default='.', help='Project directory')
    parser.add_argument('--source', default='flicky.s', help='Source file')
    parser.add_argument('--rom', default='fbuilt.bin', help='Built ROM file')
    parser.add_argument('--movie', default='movies/flicky_longplay.gmv', help='TAS movie file')
    parser.add_argument('--reference', default='reference', help='Reference screenshots directory')
    parser.add_argument('--diffs', default='diffs', help='Diffs output directory')
    parser.add_argument('--gens', default='gens-rerecording/Gens-rr/Output/Gens.exe', help='Gens emulator path')
    parser.add_argument('--output', default='analysis_results.csv', help='Output CSV file')
    parser.add_argument('--interval', type=int, default=20, help='Screenshot interval')
    parser.add_argument('--max-frames', type=int, default=0, help='Max frames to analyze (0 = no limit, play until movie ends)')
    parser.add_argument('--max-diffs', type=int, default=10, help='Stop after N visual diffs per procedure')
    parser.add_argument('--max-memory-diffs', type=int, default=10, help='Stop after N memory diffs per procedure')
    parser.add_argument('--frameskip', type=int, default=0, help='Frame skip for faster analysis')
    parser.add_argument('--grid-cols', type=int, default=8, help='Number of columns in window grid')
    parser.add_argument('--diff-color', default='pink', help='Color for diff highlighting (pink, red, green, blue, yellow, cyan, white, orange)')
    parser.add_argument('--procedures-file', help='File with list of procedures to analyze (one per line)')
    parser.add_argument('--limit', type=int, help='Limit number of procedures to analyze')
    parser.add_argument('--start-from', help='Start from specific procedure name')
    parser.add_argument('--workers', '-j', type=int, default=4, help='Number of parallel workers')
    parser.add_argument('--memory-diffs', action='store_true', default=False,
                       help='Enable memory diff saving (default: visual-only mode)')

    args = parser.parse_args()
    return analyze_procedures(args)


if __name__ == '__main__':
    sys.exit(main())
