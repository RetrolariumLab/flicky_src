#!/usr/bin/env python3
"""Prepare the emulator checkout at the exact revision in the toolchain manifest."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path
from typing import Any


class CheckoutError(RuntimeError):
    """Report a checkout that cannot safely produce the approved emulator."""


def run_git(*arguments: str, cwd: Path | None = None) -> str:
    """Run Git and return stripped stdout with a useful failure message."""
    result = subprocess.run(
        ["git", *arguments], cwd=cwd, capture_output=True, text=True
    )
    if result.returncode:
        detail = result.stderr.strip() or result.stdout.strip()
        raise CheckoutError(f"git {' '.join(arguments)} failed: {detail}")
    return result.stdout.strip()


def component_from_manifest(config: Path, identifier: str) -> dict[str, Any]:
    """Load one source-built component and validate its immutable source identity."""
    manifest = json.loads(config.read_text(encoding="utf-8"))
    component = next(
        (item for item in manifest.get("components", []) if item.get("id") == identifier),
        None,
    )
    if component is None:
        raise CheckoutError(f"toolchain component {identifier!r} is not declared")
    source = component.get("source")
    commit = component.get("source_commit")
    if not isinstance(source, str) or not source:
        raise CheckoutError(f"{identifier}: source URL is not declared")
    if not isinstance(commit, str) or len(commit) != 40 or any(
        character not in "0123456789abcdef" for character in commit
    ):
        raise CheckoutError(f"{identifier}: source_commit must be a full Git object id")
    return component


def normalized_source(value: str) -> str:
    """Normalize URLs and local test paths for an origin comparison."""
    value = value.rstrip("/")
    if "://" in value or value.startswith("git@"):
        return value.removesuffix(".git").casefold()
    return str(Path(value).resolve()).rstrip("\\/").casefold()


def validate_checkout(checkout: Path, component: dict[str, Any]) -> None:
    """Reject checkouts whose origin, revision, or tracked files differ."""
    if not (checkout / ".git").exists():
        raise CheckoutError(f"{checkout} exists but is not a Git checkout")

    origin = run_git("config", "--get", "remote.origin.url", cwd=checkout)
    if normalized_source(origin) != normalized_source(component["source"]):
        raise CheckoutError(
            f"{checkout}: origin is {origin!r}, expected {component['source']!r}"
        )

    actual = run_git("rev-parse", "HEAD", cwd=checkout)
    wanted = component["source_commit"]
    if actual != wanted:
        raise CheckoutError(
            f"{checkout}: HEAD is {actual}, expected pinned commit {wanted}"
        )

    dirty = run_git("status", "--porcelain", "--untracked-files=no", cwd=checkout)
    if dirty:
        raise CheckoutError(f"{checkout}: tracked files differ from the pinned commit")


def prepare_checkout(config: Path, checkout: Path, identifier: str = "emulator") -> str:
    """Clone a missing checkout at its pin or validate an existing checkout."""
    component = component_from_manifest(config, identifier)
    checkout = checkout.resolve()
    if not checkout.exists():
        checkout.parent.mkdir(parents=True, exist_ok=True)
        run_git("clone", "--no-checkout", component["source"], str(checkout))
        run_git("checkout", "--detach", component["source_commit"], cwd=checkout)
    validate_checkout(checkout, component)
    return component["source_commit"]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=Path("config/toolchain.json"))
    parser.add_argument("--checkout", type=Path, required=True)
    parser.add_argument("--component", default="emulator")
    args = parser.parse_args()

    try:
        commit = prepare_checkout(args.config, args.checkout, args.component)
    except (CheckoutError, OSError, json.JSONDecodeError) as error:
        print(f"[ERROR] {error}")
        return 1
    print(f"[OK] {args.component} checkout is pinned at {commit}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
