"""Flicky project tests with one shared import root for project tools."""

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = str(ROOT / "scripts")
if SCRIPTS not in sys.path:
    sys.path.insert(0, SCRIPTS)
