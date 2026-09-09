import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

from validation import source_2_audit  # noqa: E402


class Source2Audit(unittest.TestCase):
    def setUp(self):
        self.path = ROOT / "config/source_reconstruction_2_0.json"
        self.manifest = json.loads(self.path.read_text(encoding="utf-8"))

    def validate_copy(self, document: dict, require_ready: bool = False) -> list[str]:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "source_2.json"
            path.write_text(json.dumps(document), encoding="utf-8")
            return source_2_audit.validate_source_2(ROOT, path, require_ready)

    def test_project_contract_is_valid_tag_ready_state(self):
        self.assertEqual(source_2_audit.validate_source_2(ROOT, self.path), [])
        self.assertEqual(
            source_2_audit.validate_source_2(
                ROOT, self.path, require_ready=True
            ),
            [],
        )

    def test_development_manifest_fails_ready_audit(self):
        document = json.loads(json.dumps(self.manifest))
        document["status"] = "development"
        errors = self.validate_copy(document, True)
        self.assertIn("Source Reconstruction 2.0 manifest is not tag-ready", errors)

    def test_public_schema_version_is_checked(self):
        document = json.loads(json.dumps(self.manifest))
        document["schema_version"] = 2
        errors = self.validate_copy(document)
        self.assertTrue(any("schema_version is" in error for error in errors), errors)

    def test_review_metadata_is_not_part_of_the_public_manifest(self):
        document = json.loads(json.dumps(self.manifest))
        document["contract"] = {"source": "private"}
        errors = self.validate_copy(document)
        self.assertIn("manifest exposes non-project review metadata", errors)

    def test_release_kind_is_baseline(self):
        document = json.loads(json.dumps(self.manifest))
        document["release_kind"] = "compatible_minor"
        errors = self.validate_copy(document)
        self.assertIn("release_kind is not baseline", errors)

    def test_format_count_disagreement_is_detected(self):
        document = json.loads(json.dumps(self.manifest))
        document["semantic_source"]["exact_round_trips"] = 8
        errors = self.validate_copy(document)
        self.assertTrue(any("format strength counts differ" in error for error in errors), errors)

    def test_predecessor_commit_is_pinned(self):
        document = json.loads(json.dumps(self.manifest))
        document["predecessor"]["commit"] = "0" * 40
        errors = self.validate_copy(document)
        self.assertIn("predecessor tag target differs from the 2.0 contract", errors)

    def test_sound_fidelity_claim_is_bounded_and_pinned(self):
        document = json.loads(json.dumps(self.manifest))
        document["authoring"]["sound_fidelity"]["exact_ordered_chip_writes"] = 12
        errors = self.validate_copy(document)
        self.assertIn(
            "sound fidelity claim covers fewer than 2600 chip writes", errors
        )
        document = json.loads(json.dumps(self.manifest))
        document["authoring"]["sound_fidelity"]["max_timing_error_frames"] = 3
        errors = self.validate_copy(document)
        self.assertIn("sound fidelity timing tolerance exceeds 2.1 frames", errors)

    def test_public_release_audit_runs_end_to_end(self):
        result = subprocess.run(
            [
                sys.executable,
                str(ROOT / "scripts" / "run.py"),
                "validation.source_2_audit",
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)


class HistoryPolicy(unittest.TestCase):
    def test_cyrillic_in_changed_public_text_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            subprocess.run(["git", "init", "-q"], cwd=root, check=True)
            subprocess.run(
                ["git", "config", "user.name", "Release Test"], cwd=root, check=True
            )
            subprocess.run(
                ["git", "config", "user.email", "test@example.invalid"],
                cwd=root,
                check=True,
            )
            readme = root / "README.md"
            readme.write_text("English baseline\n", encoding="utf-8")
            subprocess.run(["git", "add", "README.md"], cwd=root, check=True)
            subprocess.run(
                ["git", "commit", "-q", "-m", "Create fixture"], cwd=root, check=True
            )
            base = subprocess.run(
                ["git", "rev-parse", "HEAD"],
                cwd=root,
                check=True,
                capture_output=True,
                text=True,
            ).stdout.strip()
            readme.write_text(
                "Public text " + "".join(chr(code) for code in (1085, 1077)) + "\n",
                encoding="utf-8",
            )
            errors: list[str] = []
            source_2_audit.validate_public_language(root, base, errors)
            self.assertTrue(any("non-English script" in error for error in errors), errors)

    def test_empty_commit_is_rejected_from_delta_history(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            subprocess.run(["git", "init", "-q"], cwd=root, check=True)
            subprocess.run(
                ["git", "config", "user.name", "Release Test"], cwd=root, check=True
            )
            subprocess.run(
                ["git", "config", "user.email", "test@example.invalid"],
                cwd=root,
                check=True,
            )
            (root / "README.md").write_text("fixture\n", encoding="utf-8")
            subprocess.run(["git", "add", "README.md"], cwd=root, check=True)
            subprocess.run(["git", "commit", "-q", "-m", "Create fixture"], cwd=root, check=True)
            base = subprocess.run(
                ["git", "rev-parse", "HEAD"],
                cwd=root,
                check=True,
                capture_output=True,
                text=True,
            ).stdout.strip()
            subprocess.run(
                ["git", "commit", "-q", "--allow-empty", "-m", "Empty fixture"],
                cwd=root,
                check=True,
            )
            empty = subprocess.run(
                ["git", "rev-parse", "HEAD"],
                cwd=root,
                check=True,
                capture_output=True,
                text=True,
            ).stdout.strip()
            release = {
                "delta": [
                    {
                        "id": "fixture",
                        "kind": "test",
                        "summary": "Exercise empty commit rejection.",
                        "evidence": ["README.md"],
                        "commits": [empty],
                    }
                ],
                "delta_history": {
                    "base_commit": base,
                    "tip": "pending",
                    "commit_count": None,
                },
            }
            errors: list[str] = []
            source_2_audit.validate_history(root, release, base, errors, False)
            self.assertTrue(any("empty commit" in error for error in errors), errors)


if __name__ == "__main__":
    unittest.main()
