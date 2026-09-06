import json
import re
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "docs" / "provenance" / "label_renames.json"
TABLE = json.loads(MANIFEST.read_text(encoding="utf-8"))

LABEL_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
EQUATE_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s+equ\b", re.IGNORECASE)
MACRO_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s+macro\b", re.IGNORECASE)


def defined_name(line: str) -> str | None:
    for pattern in (LABEL_RE, EQUATE_RE, MACRO_RE):
        match = pattern.match(line)
        if match:
            return match.group(1)
    return None


def source_symbols() -> dict[str, str]:
    """Every symbol the source defines, mapped to the file that defines it."""
    found: dict[str, str] = {}
    for path in sorted((ROOT / "src").rglob("*")):
        if path.suffix not in {".s", ".inc"}:
            continue
        relative = path.relative_to(ROOT).as_posix()
        for line in path.read_text(encoding="utf-8").split("\n"):
            name = defined_name(line)
            if name:
                found[name] = relative
    return found


class Shape(unittest.TestCase):
    def test_the_columns_are_declared(self):
        self.assertEqual(TABLE["schema_version"], 1)
        self.assertEqual(TABLE["rename_columns"], ["original", "current", "current_path"])
        self.assertEqual(TABLE["addition_columns"], ["current", "current_path"])

    def test_the_import_is_pinned_to_a_commit(self):
        source = TABLE["source"]
        self.assertRegex(source["repository_import_commit"], r"^[0-9a-f]{40}$")
        self.assertTrue(source["repository_import_path"])
        self.assertTrue(source["label_policy"])

    def test_the_counts_describe_the_table(self):
        self.assertEqual(TABLE["counts"]["renames"], len(TABLE["renames"]))
        self.assertEqual(TABLE["counts"]["project_additions"], len(TABLE["project_additions"]))
        self.assertEqual(
            TABLE["counts"]["current_labels"],
            len(TABLE["renames"]) + len(TABLE["project_additions"]),
        )

    def test_no_original_is_mapped_twice(self):
        originals = [row[0] for row in TABLE["renames"]]
        self.assertEqual(len(set(originals)), len(originals))

    def test_no_current_name_appears_twice(self):
        current = [row[1] for row in TABLE["renames"]]
        current += [row[0] for row in TABLE["project_additions"]]
        self.assertEqual(len(set(current)), len(current))


class MatchesTheImport(unittest.TestCase):
    def test_every_imported_label_is_accounted_for(self):
        commit = TABLE["source"]["repository_import_commit"]
        path = TABLE["source"]["repository_import_path"]
        result = subprocess.run(
            ["git", "show", f"{commit}:{path}"],
            cwd=ROOT, capture_output=True, text=True, check=False,
        )
        if result.returncode != 0:
            self.skipTest("the import commit is not in this checkout")

        imported = []
        for line in result.stdout.split("\n"):
            name = defined_name(line)
            if name and name not in imported:
                imported.append(name)

        self.assertEqual(TABLE["counts"]["original_labels"], len(imported))
        mapped = {row[0] for row in TABLE["renames"]}
        missing = sorted(set(imported) - mapped)
        self.assertEqual(missing, [], "imported labels with no entry in the table")


class MatchesTheSource(unittest.TestCase):
    def setUp(self):
        self.symbols = source_symbols()

    def test_the_inline_markers_are_gone(self):
        # The table replaced them. A marker coming back would mean two records
        # of the same fact, free to disagree.
        for path in sorted((ROOT / "src").rglob("*")):
            if path.suffix not in {".s", ".inc"}:
                continue
            self.assertNotIn(
                "; was:", path.read_text(encoding="utf-8"),
                f"inline provenance is back in {path.relative_to(ROOT).as_posix()}",
            )

    def test_every_mapped_name_exists_where_the_table_says(self):
        for _original, current, current_path in TABLE["renames"]:
            self.assertIn(current, self.symbols, current)
            self.assertEqual(self.symbols[current], current_path, current)
        for current, current_path in TABLE["project_additions"]:
            self.assertIn(current, self.symbols, current)
            self.assertEqual(self.symbols[current], current_path, current)

    def test_the_table_covers_the_source_exactly(self):
        # Not just "every entry exists" but "every symbol has an entry": without
        # this a new symbol could be added and never recorded.
        mapped = {row[1] for row in TABLE["renames"]}
        mapped |= {row[0] for row in TABLE["project_additions"]}
        self.assertEqual(mapped, set(self.symbols))


if __name__ == "__main__":
    unittest.main()
