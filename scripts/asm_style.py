#!/usr/bin/env python3
"""Check or normalize the project's AS assembly style."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# Operands begin at column 17, i.e. after 16 leading spaces.
OPERAND_COLUMN = 16

LABEL_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):(.*)$")
STATEMENT_RE = re.compile(r"^(\s*)(\S+)(.*)$")
INLINE_COMMENT_RE = re.compile(r"^(.*?\S)(\s+)(;.*)$")
BLOCK_OPEN_RE = re.compile(r"^\s*\S+\s+macro\b", re.IGNORECASE)
# Directives that consume the label field: the name in front of them defines a
# symbol and must stay at column zero, even though what follows reads like a
# mnemonic.
LABEL_FIELD_RE = re.compile(
    r"^\s*([A-Za-z_][A-Za-z0-9_]*)(\s+(?:equ|macro|set|function|struct)\b.*)$",
    re.IGNORECASE,
)
BLOCK_CLOSE_RE = re.compile(r"^\s*endm\b", re.IGNORECASE)


class Issue:
    def __init__(self, path: Path, line: int, kind: str, detail: str) -> None:
        self.path = path
        self.line = line
        self.kind = kind
        self.detail = detail

    def __str__(self) -> str:
        return f"{self.path}:{self.line}: {self.kind}: {self.detail}"


def split_comment(text: str) -> tuple[str, str]:
    """Split a line into (code, comment), respecting quoted strings."""
    in_string = False
    for index, char in enumerate(text):
        if char == '"':
            in_string = not in_string
        elif char == ";" and not in_string:
            return text[:index], text[index:]
    return text, ""


def normalize_line(line: str, depth: int) -> str:
    """Return the canonical form of one source line."""
    line = line.replace("\t", " ").rstrip()
    if not line.strip():
        return ""

    code, comment = split_comment(line)
    stripped = code.strip()

    if stripped.startswith(";") or not stripped:
        # A whole-line comment keeps its own indentation.
        return line.rstrip()

    indent = OPERAND_COLUMN + 4 * depth

    field_match = LABEL_FIELD_RE.match(line)
    if field_match:
        # "NAME equ value" and "NAME macro args" define NAME in the label
        # field, so the name stays at column zero even though what follows
        # reads like a mnemonic.
        name, rest = field_match.group(1), field_match.group(2)
        rest_code, rest_comment = split_comment(rest)
        head = name.ljust(indent) + collapse_operand_spacing(rest_code.strip())
        if rest_comment:
            head = f"{head.rstrip()}  {rest_comment.strip()}"
        return head.rstrip()

    label_match = LABEL_RE.match(line)
    if label_match:
        name, rest = label_match.group(1), label_match.group(2)
        rest_code, rest_comment = split_comment(rest)
        body = collapse_operand_spacing(rest_code.strip())
        head = f"{name}:"
        if body:
            head = head.ljust(indent) + body
        if rest_comment:
            head = f"{head}  {rest_comment.strip()}"
        return head.rstrip()

    body = collapse_operand_spacing(stripped)
    result = " " * indent + body
    if comment:
        result = f"{result}  {comment.strip()}"
    return result.rstrip()


def collapse_operand_spacing(code: str) -> str:
    """Align the operand field at column 8 of the statement.

    Only the gap between the mnemonic and the operand is touched. The operand
    text itself is copied verbatim, because collapsing whitespace inside it
    would rewrite quoted strings such as the ROM header and silently change
    the assembled bytes.
    """
    match = STATEMENT_RE.match(code)
    if not match:
        return code
    mnemonic, rest = match.group(2), match.group(3).lstrip()
    if not rest:
        return mnemonic
    return f"{mnemonic.ljust(7)} {rest}" if len(mnemonic) < 8 else f"{mnemonic} {rest}"


def check_text(path: Path, text: str, issues: list[Issue]) -> None:
    if "\r" in text:
        issues.append(Issue(path, 0, "line-ending", "file contains CR; use LF only"))
    if text and not text.endswith("\n"):
        issues.append(Issue(path, 0, "final-newline", "file does not end with a newline"))
    if text.endswith("\n\n"):
        issues.append(Issue(path, 0, "final-newline", "file ends with more than one newline"))


def check_lines(path: Path, lines: list[str], issues: list[Issue]) -> None:
    depth = 0
    previous_blank = False
    for number, line in enumerate(lines, 1):
        if "\t" in line:
            issues.append(Issue(path, number, "tab", "tab character; use spaces"))
        if line != line.rstrip():
            issues.append(Issue(path, number, "trailing-space", "trailing whitespace"))
        if not any(0x20 <= ord(c) <= 0x7E for c in line) and line.strip():
            issues.append(Issue(path, number, "charset", "no printable ASCII content"))
        for char in line:
            if ord(char) > 0x7E or (ord(char) < 0x20 and char != "\t"):
                issues.append(
                    Issue(path, number, "charset", "non-ASCII character; rewrite in English")
                )
                break

        if not line.strip():
            if previous_blank:
                issues.append(Issue(path, number, "blank-run", "more than one blank line"))
            if number == 1:
                issues.append(Issue(path, number, "leading-blank", "file starts with a blank line"))
            previous_blank = True
            continue
        previous_blank = False

        if BLOCK_CLOSE_RE.match(line):
            depth = max(0, depth - 1)

        expected = normalize_line(line, depth)
        if line.rstrip() != expected:
            issues.append(Issue(path, number, "layout", f"expected: {expected!r}"))

        if BLOCK_OPEN_RE.match(line):
            depth += 1

        comment_match = INLINE_COMMENT_RE.match(line.rstrip())
        if comment_match and len(comment_match.group(2)) != 2:
            issues.append(
                Issue(path, number, "comment-space", "use exactly two spaces before an inline comment")
            )
        code, comment = split_comment(line)
        if comment.startswith(";") and len(comment) > 1 and comment[1] not in " ;-=":
            issues.append(Issue(path, number, "comment-space", "use one space after ';'"))


def normalize_file(text: str) -> str:
    lines = text.split("\n")
    if lines and lines[-1] == "":
        lines.pop()

    depth = 0
    output: list[str] = []
    for line in lines:
        if BLOCK_CLOSE_RE.match(line):
            depth = max(0, depth - 1)
        normalized = normalize_line(line, depth)
        if BLOCK_OPEN_RE.match(line):
            depth += 1
        if not normalized and output and not output[-1]:
            continue  # collapse blank runs
        if not normalized and not output:
            continue  # drop leading blanks
        output.append(normalized)

    while output and not output[-1]:
        output.pop()
    return "\n".join(output) + "\n"


def source_files(roots: list[Path]) -> list[Path]:
    files: list[Path] = []
    for root in roots:
        if root.is_file():
            files.append(root)
            continue
        for suffix in ("*.s", "*.inc"):
            files.extend(sorted(root.rglob(suffix)))
    return files


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", default=["src", "flicky.s"], help="Files or directories")
    parser.add_argument("--fix", action="store_true", help="Rewrite files into the canonical form")
    args = parser.parse_args()

    files = source_files([Path(p) for p in args.paths])
    if not files:
        print("[ERROR] no assembly sources found", file=sys.stderr)
        return 1

    if args.fix:
        changed = 0
        for path in files:
            text = path.read_text(encoding="utf-8")
            normalized = normalize_file(text.replace("\r\n", "\n"))
            if normalized != text:
                path.write_text(normalized, encoding="utf-8", newline="")
                print(f"[INFO] formatted {path}")
                changed += 1
        print(f"[OK] formatted {changed} of {len(files)} file(s)")
        return 0

    issues: list[Issue] = []
    for path in files:
        text = path.read_text(encoding="utf-8")
        check_text(path, text, issues)
        lines = text.split("\n")
        if lines and lines[-1] == "":
            lines.pop()
        check_lines(path, lines, issues)

    if issues:
        for issue in issues[:60]:
            print(f"[ERROR] {issue}", file=sys.stderr)
        if len(issues) > 60:
            print(f"[ERROR] ... and {len(issues) - 60} more", file=sys.stderr)
        print(f"[FAIL] {len(issues)} style issue(s) in {len(files)} file(s)", file=sys.stderr)
        return 1

    print(f"[OK] assembly style clean in {len(files)} file(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
