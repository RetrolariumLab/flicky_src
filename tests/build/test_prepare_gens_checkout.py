import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from scripts.build import prepare_gens_checkout


def git(cwd: Path, *arguments: str) -> str:
    result = subprocess.run(
        ["git", *arguments], cwd=cwd, capture_output=True, text=True, check=True
    )
    return result.stdout.strip()


class PrepareGensCheckoutTests(unittest.TestCase):
    def fixture(self, root: Path) -> tuple[Path, Path, str]:
        origin = root / "origin"
        origin.mkdir()
        git(origin, "init", "-q")
        git(origin, "config", "user.name", "Fixture Author")
        git(origin, "config", "user.email", "fixture@example.com")
        source = origin / "source.txt"
        source.write_text("pinned\n", encoding="utf-8")
        git(origin, "add", "source.txt")
        git(origin, "commit", "-q", "-m", "Create pinned source")
        pinned = git(origin, "rev-parse", "HEAD")
        source.write_text("later\n", encoding="utf-8")
        git(origin, "commit", "-qam", "Advance default branch")

        config = root / "toolchain.json"
        config.write_text(
            json.dumps(
                {
                    "components": [
                        {
                            "id": "emulator",
                            "source": str(origin),
                            "source_commit": pinned,
                        }
                    ]
                }
            ),
            encoding="utf-8",
        )
        return origin, config, pinned

    def test_missing_checkout_is_cloned_at_the_pinned_revision(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            _origin, config, pinned = self.fixture(root)
            checkout = root / "checkout"

            result = prepare_gens_checkout.prepare_checkout(config, checkout)

            self.assertEqual(result, pinned)
            self.assertEqual(git(checkout, "rev-parse", "HEAD"), pinned)
            self.assertEqual(git(checkout, "branch", "--show-current"), "")
            self.assertEqual((checkout / "source.txt").read_text(), "pinned\n")

    def test_existing_checkout_at_another_revision_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            origin, config, _pinned = self.fixture(root)
            checkout = root / "checkout"
            git(root, "clone", "-q", str(origin), str(checkout))

            with self.assertRaisesRegex(
                prepare_gens_checkout.CheckoutError, "expected pinned commit"
            ):
                prepare_gens_checkout.prepare_checkout(config, checkout)

    def test_existing_checkout_with_tracked_changes_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            _origin, config, pinned = self.fixture(root)
            checkout = root / "checkout"
            prepare_gens_checkout.prepare_checkout(config, checkout)
            (checkout / "source.txt").write_text("modified\n", encoding="utf-8")

            with self.assertRaisesRegex(
                prepare_gens_checkout.CheckoutError,
                "tracked files differ from the pinned commit",
            ):
                prepare_gens_checkout.prepare_checkout(config, checkout)
            self.assertEqual(git(checkout, "rev-parse", "HEAD"), pinned)

    def test_existing_checkout_from_another_origin_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            origin, config, pinned = self.fixture(root)
            checkout = root / "checkout"
            prepare_gens_checkout.prepare_checkout(config, checkout)
            other = root / "other"
            git(root, "clone", "-q", str(origin), str(other))
            git(checkout, "remote", "set-url", "origin", str(other))

            with self.assertRaisesRegex(
                prepare_gens_checkout.CheckoutError, "origin is"
            ):
                prepare_gens_checkout.prepare_checkout(config, checkout)
            self.assertEqual(git(checkout, "rev-parse", "HEAD"), pinned)


if __name__ == "__main__":
    unittest.main()
