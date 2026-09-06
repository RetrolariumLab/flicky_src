import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import verify_toolchain  # noqa: E402

CONFIG = json.loads((ROOT / "config" / "toolchain.json").read_text(encoding="utf-8"))


class Manifest(unittest.TestCase):
    def test_every_component_records_what_it_is(self):
        for component in CONFIG["components"]:
            for field in ("id", "version", "source", "provenance", "verification"):
                self.assertTrue(component.get(field), f"{component.get('id')}: {field}")

    def test_a_source_built_component_pins_a_commit(self):
        # A locally built binary has no stable hash, so the commit is the
        # identity. Without one, nothing says which build ran.
        for component in CONFIG["components"]:
            if component["provenance"] == "source-built":
                self.assertRegex(component["source_commit"] or "", r"^[0-9a-f]{40}$")

    def test_every_recorded_file_has_a_hash_and_a_size(self):
        for component in CONFIG["components"]:
            for entries in component["files"].values():
                for entry in entries:
                    self.assertRegex(entry["sha256"], r"^[0-9a-f]{64}$")
                    self.assertGreater(entry["size"], 0)

    def test_the_recorded_hashes_match_the_vendored_files(self):
        for component in CONFIG["components"]:
            for entries in component["files"].values():
                for entry in entries:
                    path = ROOT / entry["path"]
                    if not path.is_file() or entry.get("observed_only"):
                        continue
                    digest = hashlib.sha256(path.read_bytes()).hexdigest()
                    self.assertEqual(digest, entry["sha256"], entry["path"])

    def test_a_host_is_declared_with_a_support_status(self):
        self.assertTrue(CONFIG["hosts"])
        allowed = {"supported", "partial", "unsupported", "planned"}
        for host in CONFIG["hosts"]:
            self.assertIn(host["supported_status"], allowed)
            self.assertTrue(host["evidence"], host["os"])


class Verification(unittest.TestCase):
    def entry(self, path: Path) -> dict:
        return {
            "path": str(path),
            "size": path.stat().st_size,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        }

    def test_a_matching_file_passes(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "tool.exe"
            path.write_bytes(b"assembler")
            errors, notes = [], []
            checked = verify_toolchain.check_files([self.entry(path)], errors, notes)
            self.assertEqual((errors, checked), ([], 1))

    def test_a_swapped_binary_is_caught(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "tool.exe"
            path.write_bytes(b"assembler")
            entry = self.entry(path)
            path.write_bytes(b"assemblES")  # same length, different bytes
            errors, notes = [], []
            verify_toolchain.check_files([entry], errors, notes)
            self.assertEqual(len(errors), 1)
            self.assertIn("does not match the recorded build", errors[0])

    def test_a_missing_binary_is_an_error(self):
        errors, notes = [], []
        verify_toolchain.check_files(
            [{"path": "does/not/exist", "size": 1, "sha256": "0" * 64}], errors, notes
        )
        self.assertEqual(len(errors), 1)
        self.assertIn("missing", errors[0])

    def test_an_observed_only_file_only_produces_a_note(self):
        # The emulator is pinned by commit, so a different local build is
        # recorded rather than rejected.
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "Gens.exe"
            path.write_bytes(b"a build")
            entry = self.entry(path)
            entry["observed_only"] = True
            entry["sha256"] = "0" * 64
            errors, notes = [], []
            verify_toolchain.check_files([entry], errors, notes)
            self.assertEqual(errors, [])
            self.assertEqual(len(notes), 1)
            self.assertIn("different build", notes[0])


if __name__ == "__main__":
    unittest.main()
