#!/usr/bin/env python3
"""Check or normalize the project's AS assembly style.

The layout is the Mega Drive disassembly convention rather than the ca65 one
the NES projects in this family use: labels at column zero, the mnemonic field
at column 16, the operand at column 24 and inline comments at column 56.
Mnemonics stay lowercase, which is what AS emits and what every Sonic
disassembly uses.

Everything this script changes is whitespace or comment text, so a formatted
file has to assemble to the same bytes. `make format` runs `make lint`
afterwards and `make verify` remains the gate: if a reformat moves a byte, the
formatter is wrong, not the source.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

# The mnemonic field starts here; the operand follows 8 columns later.
MNEMONIC_COLUMN = 16
MNEMONIC_FIELD = 8
# Inline comments line up here. A line whose code reaches this column keeps two
# spaces instead and simply sticks out: the alternative is pushing every other
# comment in the file to follow the longest data table row.
COMMENT_COLUMN = 56
# A label that carries a directive steps to the next tab stop, so the directive
# column stays on 16, 24, 32 rather than landing wherever the name happens to end.
LABEL_TAB = 8
# Whole-line comments are indented in multiples of this.
COMMENT_INDENT_STEP = 4

LABEL_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):(.*)$")
STATEMENT_RE = re.compile(r"^(\s*)(\S+)(.*)$")
INLINE_COMMENT_RE = re.compile(r"^(.*?\S)(\s+)(;.*)$")
BLOCK_OPEN_RE = re.compile(r"^\s*\S+\s+macro\b", re.IGNORECASE)
BLOCK_CLOSE_RE = re.compile(r"^\s*endm\b", re.IGNORECASE)
# "NAME equ value" and "NAME macro args" define NAME in the label field, so the
# name stays at column zero even though what follows reads like a mnemonic.
LABEL_FIELD_RE = re.compile(
    r"^([A-Za-z_][A-Za-z0-9_]*)(\s+(?:equ|set|macro)\b.*)$", re.IGNORECASE
)


@dataclass(frozen=True)
class Issue:
    path: Path
    line: int
    code: str
    message: str

    def render(self) -> str:
        where = f"{self.path.as_posix()}:{self.line}" if self.line else self.path.as_posix()
        return f"{where}: [{self.code}] {self.message}"


def split_comment(text: str) -> tuple[str, str]:
    """Split a line into (code, comment), respecting quoted strings.

    One line in the source is `dc.b "; 250 PTS.=      PTS.",0`. Splitting on the
    first semicolon would turn its string literal into a comment and change the
    assembled bytes.
    """
    in_string = False
    for index, char in enumerate(text):
        if char == '"':
            in_string = not in_string
        elif char == ";" and not in_string:
            return text[:index], text[index:]
    return text, ""


def normalize_comment(comment: str) -> str:
    """One space after the semicolon, no trailing period.

    Runs of semicolons and dashes are banner lines, so they are left alone.
    """
    body = comment[1:]
    if body[:1] in {";", "-", "="}:
        return comment.rstrip()
    text = body.strip().rstrip(".")
    return f"; {text}" if text else ";"


def place_comment(code: str, comment: str) -> str:
    """Put an inline comment at the shared column, or two spaces out."""
    if not comment:
        return code.rstrip()
    code = code.rstrip()
    if not code:
        return comment
    gap = COMMENT_COLUMN - len(code)
    return code + (" " * gap if gap >= 2 else "  ") + comment


def pad_label(head: str, column: int) -> str:
    """Pad a label so what follows starts at `column`."""
    return head.ljust(column) if len(head) < column else head + " "


def tab_stop(width: int, minimum: int) -> int:
    """The first tab stop at or after `minimum` that clears `width`."""
    column = minimum
    while column < width + 1:
        column += LABEL_TAB
    return column


def label_head(line: str) -> str | None:
    """The label field of a line that also carries a statement, else None.

    Only these lines take part in column alignment. A label alone on its line
    has nothing to align, and a plain instruction has no label field.
    """
    code, _ = split_comment(line.replace("\t", " ").rstrip())
    if not code.strip() or code[:1].isspace():
        return None
    field_match = LABEL_FIELD_RE.match(code)
    if field_match:
        return field_match.group(1)
    label_match = LABEL_RE.match(code)
    if label_match and label_match.group(2).strip():
        return f"{label_match.group(1)}:"
    return None


def is_bare_label(line: str) -> bool:
    """A label alone on its line, with nothing after the colon."""
    code, _ = split_comment(line.replace("\t", " ").rstrip())
    match = LABEL_RE.match(code)
    return bool(match) and not match.group(2).strip()


def label_columns(lines: list[str], minimum: int) -> list[int]:
    """Give every run of consecutive label lines one shared column.

    An equate table is a table: `ram.inc` reads as one when its 194 values line
    up and as noise when the column steps between 16 and 24 line by line.

    A bare label is transparent rather than a separator, because `art.s`
    alternates `Name: binclude ...` with `Name_End:` and treating the end
    markers as breaks would leave every include in a run of its own. A blank
    line, a comment or an instruction does separate two runs: those mark a
    change of context, and a long data label should not drag an unrelated
    table to the right.
    """
    columns = [minimum] * len(lines)
    members: list[int] = []

    def flush() -> None:
        nonlocal members
        if members:
            shared = tab_stop(max(len(label_head(lines[i])) for i in members), minimum)
            for index in members:
                columns[index] = shared
        members = []

    for index, line in enumerate(lines):
        if label_head(line) is not None:
            members.append(index)
        elif not is_bare_label(line):
            flush()
    flush()
    return columns


def collapse_operand_spacing(code: str) -> str:
    """Align the operand field within the statement.

    Only the gap between the mnemonic and the operand is touched. The operand
    text itself is copied verbatim, because collapsing whitespace inside it
    would rewrite quoted strings such as the ROM header and silently change the
    assembled bytes.
    """
    match = STATEMENT_RE.match(code)
    if not match:
        return code
    mnemonic, rest = match.group(2), match.group(3).lstrip()
    if not rest:
        return mnemonic
    if len(mnemonic) < MNEMONIC_FIELD:
        return f"{mnemonic.ljust(MNEMONIC_FIELD - 1)} {rest}"
    return f"{mnemonic} {rest}"


def normalize_line(line: str, depth: int, column: int | None = None) -> str:
    """Return the canonical form of one source line.

    `column` is where this line's label field ends, shared across a run of
    consecutive label lines; without one the line uses its own tab stop.
    """
    line = line.replace("\t", " ").rstrip()
    if not line.strip():
        return ""

    code, comment = split_comment(line)
    stripped = code.strip()
    comment = normalize_comment(comment) if comment else ""

    if not stripped:
        # A whole-line comment: indent to a multiple of the comment step.
        indent = len(code) - len(code.lstrip(" "))
        indent = round(indent / COMMENT_INDENT_STEP) * COMMENT_INDENT_STEP
        return " " * indent + comment

    indent = MNEMONIC_COLUMN + COMMENT_INDENT_STEP * depth

    field_match = LABEL_FIELD_RE.match(code)
    if field_match:
        name, rest = field_match.group(1), field_match.group(2)
        stop = column if column is not None else tab_stop(len(name), indent)
        head = pad_label(name, stop) + collapse_operand_spacing(rest.strip())
        return place_comment(head, comment)

    label_match = LABEL_RE.match(code)
    if label_match:
        name, rest = label_match.group(1), label_match.group(2)
        body = collapse_operand_spacing(rest.strip())
        head = f"{name}:"
        if body:
            stop = column if column is not None else tab_stop(len(head), indent)
            head = pad_label(head, stop) + body
        return place_comment(head, comment)

    return place_comment(" " * indent + collapse_operand_spacing(stripped), comment)


def check_text(path: Path, text: str, issues: list[Issue]) -> None:
    if "\r" in text:
        issues.append(Issue(path, 0, "line-ending", "file contains CR; use LF only"))
    if text and not text.endswith("\n"):
        issues.append(Issue(path, 0, "final-newline", "file does not end with a newline"))
    if text.endswith("\n\n"):
        issues.append(Issue(path, 0, "final-newline", "file ends with more than one newline"))


def check_lines(path: Path, lines: list[str], issues: list[Issue]) -> None:
    columns = label_columns(lines, MNEMONIC_COLUMN)
    depth = 0
    previous_blank = False
    for number, line in enumerate(lines, 1):
        if "\t" in line:
            issues.append(Issue(path, number, "tab", "tab character; use spaces"))
        if line != line.rstrip():
            issues.append(Issue(path, number, "trailing-space", "trailing whitespace"))
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

        code, comment = split_comment(line.rstrip())
        if comment:
            body = comment[1:]
            banner = body[:1] in {";", "-", "="}
            if not banner:
                if body and not body.startswith(" "):
                    issues.append(Issue(path, number, "comment-space", "use one space after ';'"))
                if body.startswith("  "):
                    issues.append(
                        Issue(path, number, "comment-space", "use exactly one space after ';'")
                    )
                if body.strip().endswith("."):
                    issues.append(
                        Issue(path, number, "comment-period", "drop the period ending a comment")
                    )
            if not code.strip():
                indent = len(code) - len(code.lstrip(" "))
                if indent % COMMENT_INDENT_STEP:
                    issues.append(
                        Issue(
                            path, number, "comment-indent",
                            f"indent whole-line comments in multiples of {COMMENT_INDENT_STEP}",
                        )
                    )
            else:
                inline = INLINE_COMMENT_RE.match(line.rstrip())
                if inline:
                    column = len(inline.group(1))
                    gap = len(inline.group(2))
                    wanted = COMMENT_COLUMN - column
                    if (wanted >= 2 and gap != wanted) or (wanted < 2 and gap != 2):
                        issues.append(
                            Issue(
                                path, number, "comment-column",
                                f"inline comments start at column {COMMENT_COLUMN}, "
                                f"or two spaces out when the code reaches it",
                            )
                        )

        expected = normalize_line(line, depth, columns[number - 1])
        if line.rstrip() != expected:
            issues.append(Issue(path, number, "layout", f"expected: {expected!r}"))

        if BLOCK_OPEN_RE.match(line):
            depth += 1


def normalize_file(text: str) -> str:
    lines = text.split("\n")
    if lines and lines[-1] == "":
        lines.pop()

    columns = label_columns(lines, MNEMONIC_COLUMN)
    output: list[str] = []
    depth = 0
    previous_blank = False
    for index, line in enumerate(lines):
        if BLOCK_CLOSE_RE.match(line):
            depth = max(0, depth - 1)
        normalized = normalize_line(line, depth, columns[index])
        if BLOCK_OPEN_RE.match(line):
            depth += 1

        if not normalized:
            if previous_blank or not output:
                continue
            previous_blank = True
            output.append("")
            continue
        previous_blank = False
        output.append(normalized)

    while output and not output[-1]:
        output.pop()
    return "\n".join(output) + "\n" if output else ""


def source_files(roots: list[Path]) -> list[Path]:
    files: set[Path] = set()
    for root in roots:
        if root.is_dir():
            files.update(root.rglob("*.s"))
            files.update(root.rglob("*.inc"))
        elif root.suffix in {".s", ".inc"}:
            files.add(root)
    return sorted(files, key=lambda item: item.as_posix().lower())


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path, default=[Path("flicky.s"), Path("src")])
    parser.add_argument("--fix", action="store_true", help="normalize files before checking")
    args = parser.parse_args()

    files = source_files(args.paths)
    if not files:
        print("[ERROR] no .s or .inc sources found", file=sys.stderr)
        return 1

    changed = 0
    if args.fix:
        for path in files:
            original = path.read_text(encoding="utf-8")
            normalized = normalize_file(original)
            if normalized != original:
                path.write_text(normalized, encoding="utf-8", newline="\n")
                changed += 1

    issues: list[Issue] = []
    for path in files:
        text = path.read_text(encoding="utf-8")
        check_text(path, text, issues)
        check_lines(path, text.split("\n"), issues)

    if issues:
        for issue in issues[:200]:
            print(issue.render(), file=sys.stderr)
        if len(issues) > 200:
            print(f"[ERROR] ... and {len(issues) - 200} more", file=sys.stderr)
        print(f"[FAIL] assembly style: {len(issues)} issue(s)", file=sys.stderr)
        return 1

    action = f"formatted {changed} and checked" if args.fix else "checked"
    print(f"[OK] assembly style {action} {len(files)} file(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
