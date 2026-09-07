import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import source_2_audit  # noqa: E402


class Source2Audit(unittest.TestCase):
    def setUp(self):
        self.path = ROOT / "config/source_reconstruction_2_0.json"
        self.manifest = json.loads(self.path.read_text(encoding="utf-8"))

    def validate_copy(self, document: dict, require_ready: bool = False) -> list[str]:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "source_2.json"
            path.write_text(json.dumps(document), encoding="utf-8")
            return source_2_audit.validate_source_2(ROOT, path, require_ready)

    def test_project_contract_is_tag_ready(self):
        self.assertEqual(source_2_audit.validate_source_2(ROOT, self.path, True), [])

    def test_development_manifest_fails_release_audit(self):
        document = dict(self.manifest)
        document["status"] = "development"
        errors = self.validate_copy(document, True)
        self.assertIn("Source Reconstruction 2.0 manifest is not tag-ready", errors)

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


if __name__ == "__main__":
    unittest.main()
