#!/usr/bin/env python3
"""Remove generated build and analysis artifacts from this repository."""

from __future__ import annotations

import glob
import os
import shutil

# Files and directories to remove.
#
# Extracted data segments under data/ are deliberately NOT listed. They are
# regenerated only by "make split", which needs the reference ROM; deleting
# them here would break the build for anyone who no longer has the dump at
# hand. Ordinary cleaning must never destroy them.
TARGETS = [
    'fbuilt.bin',
    'flicky.p',
    'flicky.lst',
    'flicky.map',
    'flicky.asm',
    'temp.asm',
    'build',
    'language.dat',
    'Gens.cfg',
    'rename_log.txt',
]

# Glob patterns
GLOBS = [
    'flicky_backup_*.s',
    'tools/*.exe',
    'tools/*.o',
]

# Patterns to find recursively in all directories
RECURSIVE_PATTERNS = [
    'tmpclaude*',
    '__pycache__',
    'tmp',
]


def remove(path: str) -> bool:
    """Remove one file or directory. Returns True if something was removed."""
    if not os.path.exists(path):
        return False
    if os.path.isdir(path):
        shutil.rmtree(path, ignore_errors=True)
    else:
        os.remove(path)
    print(f"[INFO] removed {path}")
    return True


def main() -> int:
    removed = 0

    for target in TARGETS:
        removed += remove(target)

    for pattern in GLOBS:
        for path in glob.glob(pattern):
            removed += remove(path)

    for pattern in RECURSIVE_PATTERNS:
        for path in glob.glob(f"**/{pattern}", recursive=True):
            removed += remove(path)

    if removed:
        print(f"[OK] removed {removed} build artifact(s); extracted data left untouched")
    else:
        print("[OK] nothing to clean")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
