import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

from validation import lint_project  # noqa: E402


class EvidenceTags(unittest.TestCase):
    def test_a_tag_with_an_identifier_is_matched(self):
        match = lint_project.EVIDENCE_TAG_RE.search("; !(UNKNOWN) RAM-001 never read")
        self.assertEqual(match.group(1), "UNKNOWN")
        self.assertEqual(match.group(3), "RAM-001")

    def test_observed_needs_no_identifier(self):
        match = lint_project.EVIDENCE_TAG_RE.search("; !(OBS) confirmed in a trace")
        self.assertEqual(match.group(1), "OBS")
        self.assertIsNone(match.group(3))

    def test_every_approved_tag_is_recognised(self):
        for tag in lint_project.APPROVED_TAGS:
            self.assertIsNotNone(lint_project.EVIDENCE_TAG_RE.search(f"!({tag}) RAM-001"), tag)


class CodeSpans(unittest.TestCase):
    def test_a_quoted_tag_is_blanked_out(self):
        # The roadmap documents the vocabulary; that is not a use of a tag.
        stripped = lint_project.strip_code_spans("| `!(UNKNOWN)` | Not yet understood |")
        self.assertNotIn("!(UNKNOWN)", stripped)

    def test_an_unquoted_tag_survives(self):
        line = "; !(UNKNOWN) RAM-001 written and never read"
        self.assertEqual(lint_project.strip_code_spans(line), line)

    def test_column_positions_are_preserved(self):
        line = "before `code` after"
        self.assertEqual(len(lint_project.strip_code_spans(line)), len(line))


class PayloadPolicy(unittest.TestCase):
    def test_extracted_data_is_rejected(self):
        errors: list[str] = []
        lint_project.check_payload_policy([Path("data/artnem/data_LevelTiles.bin")], errors)
        self.assertEqual(len(errors), 1)

    def test_a_movie_is_allowed(self):
        errors: list[str] = []
        lint_project.check_payload_policy([Path("movies/flicky_longplay.gmv")], errors)
        self.assertEqual(errors, [])

    def test_the_vendored_toolchain_is_allowed(self):
        errors: list[str] = []
        lint_project.check_payload_policy([Path("bin/windows_i386/asw.exe")], errors)
        self.assertEqual(errors, [])


class DocumentationCorpus(unittest.TestCase):
    def check(self, documents: dict[str, str]) -> list[str]:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            texts: dict[Path, str] = {}
            for relative, text in documents.items():
                path = Path(relative)
                absolute = root / path
                absolute.parent.mkdir(parents=True, exist_ok=True)
                absolute.write_text(text, encoding="utf-8")
                texts[path] = text
            errors: list[str] = []
            lint_project.check_documentation_corpus(root, list(texts), texts, errors)
            return errors

    def test_orphaned_markdown_is_rejected(self):
        errors = self.check(
            {
                "README.md": "[Index](docs/index.md)\n",
                "docs/index.md": "# Index\n",
                "docs/orphan.md": "# Orphan\n",
            }
        )
        self.assertTrue(any("not reachable" in error for error in errors), errors)

    def test_flat_repeated_prefix_cluster_is_rejected(self):
        errors = self.check(
            {
                "README.md": "[Index](docs/index.md)\n",
                "docs/index.md": "[A](enemy_cat.md) [B](enemy_lizard.md) [C](enemy_snake.md)\n",
                "docs/enemy_cat.md": "# Cat\n",
                "docs/enemy_lizard.md": "# Lizard\n",
                "docs/enemy_snake.md": "# Snake\n",
            }
        )
        self.assertTrue(any("prefix 'enemy'" in error for error in errors), errors)

    def test_oversized_document_is_rejected_for_review(self):
        errors = self.check(
            {
                "README.md": "[Index](docs/index.md)\n",
                "docs/index.md": "# Index\n" + "line\n" * 600,
            }
        )
        self.assertTrue(any("documentation review limit" in error for error in errors), errors)


class DocumentedPrefixExceptions(unittest.TestCase):
    def test_source_documents_are_an_acknowledged_mixed_purpose_cluster(self):
        self.assertIn(
            (Path("docs"), "source"), lint_project.DOCUMENT_PREFIX_EXCEPTIONS
        )


class ProjectIsClean(unittest.TestCase):
    def test_new_release_files_are_part_of_the_lint_surface(self):
        files = lint_project.tracked_files()
        self.assertIn(Path("mk/validation.mk"), files)

    def test_the_repository_passes_its_own_check(self):
        result = subprocess.run(
            [sys.executable, str(ROOT / "scripts" / "run.py"), "validation.lint_project"],
            cwd=ROOT, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
