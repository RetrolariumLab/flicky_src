#!/usr/bin/env python3
"""
Clean Project Script

Removes build artifacts and temporary files.
"""

import os
import shutil
import glob


# Files/folders to remove
TARGETS = [
    'data/artnem',
    'data/arteni',
    'data/artunc',
    'data/other',
    'data/sound',
    'language.dat',
    'Gens.cfg',
    'flicky.p',
    'fbuilt.bin',
    'rename_log.txt',
]

# Glob patterns
GLOBS = [
    'flicky_backup_*.s',
    'tools/*.exe',
]

# Patterns to find recursively in all directories
RECURSIVE_PATTERNS = [
    'tmpclaude*',
    '__pycache__',
    'tmp',
]


def remove_path(path):
    """Remove file or directory."""
    if os.path.isfile(path):
        os.remove(path)
        print(f"  Removed file: {path}")
        return True
    elif os.path.isdir(path):
        shutil.rmtree(path)
        print(f"  Removed dir:  {path}")
        return True
    return False


def main():
    print("Cleaning project...")
    removed = 0

    # Remove fixed targets
    for target in TARGETS:
        if os.path.exists(target):
            if remove_path(target):
                removed += 1

    # Remove glob patterns
    for pattern in GLOBS:
        for path in glob.glob(pattern, recursive=True):
            if remove_path(path):
                removed += 1

    # Remove recursive patterns
    for pattern in RECURSIVE_PATTERNS:
        # Search in all directories using **
        for path in glob.glob(f'**/{pattern}', recursive=True):
            if remove_path(path):
                removed += 1
        # Also check root directory
        for path in glob.glob(pattern):
            if os.path.exists(path) and remove_path(path):
                removed += 1

    if removed == 0:
        print("  Nothing to clean")
    else:
        print(f"\nRemoved {removed} item(s)")


if __name__ == '__main__':
    main()
