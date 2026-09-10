import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPTS = ROOT / "scripts"
CATEGORIES = {"authoring", "build", "formats", "runtime", "validation", "workflow"}


class ScriptLayout(unittest.TestCase):
    def test_dispatcher_is_the_only_root_python_file(self) -> None:
        root_modules = {path.name for path in SCRIPTS.glob("*.py")}
        self.assertEqual(root_modules, {"run.py"})

    def test_categories_are_importable_packages(self) -> None:
        packages = {
            path.name
            for path in SCRIPTS.iterdir()
            if path.is_dir() and (path / "__init__.py").is_file()
        }
        self.assertEqual(packages, CATEGORIES)

    def test_every_category_contains_tools(self) -> None:
        for category in CATEGORIES:
            modules = set((SCRIPTS / category).glob("*.py"))
            self.assertGreater(len(modules), 1, category)


if __name__ == "__main__":
    unittest.main()
