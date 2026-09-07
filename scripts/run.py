#!/usr/bin/env python3
"""Run a categorized project tool with a stable repository-local import path."""

from __future__ import annotations

import runpy
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) < 2 or "." not in sys.argv[1]:
        raise SystemExit("usage: python scripts/run.py <category.module> [arguments ...]")

    scripts_dir = Path(__file__).resolve().parent
    sys.path.insert(0, str(scripts_dir))
    module = sys.argv[1]
    sys.argv = [f"{module}.py", *sys.argv[2:]]
    runpy.run_module(module, run_name="__main__")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
