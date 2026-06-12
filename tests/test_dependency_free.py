import importlib
import os
import sys
import unittest


ROOT = os.path.dirname(os.path.dirname(__file__))


class DependencyFreeImportTests(unittest.TestCase):
    def test_imports_without_known_third_party_modules(self):
        before = set(sys.modules)
        module = importlib.import_module("librangemap")
        self.assertEqual(module.__version__, "0.1.0-alpha")
        imported = set(sys.modules) - before
        forbidden = {
            "numpy",
            "PIL",
            "pandas",
            "torch",
            "tensorflow",
            "sklearn",
            "cv2",
            "requests",
            "pydantic",
            "click",
            "typer",
            "rich",
            "pytest",
        }
        self.assertFalse(imported & forbidden)

    def test_packaging_declares_no_runtime_dependencies(self):
        pyproject_path = os.path.join(ROOT, "pyproject.toml")
        with open(pyproject_path, "r", encoding="utf-8") as handle:
            pyproject = handle.read()

        self.assertIn("\ndependencies = []\n", pyproject)
        self.assertNotIn("[project.optional-dependencies]", pyproject)

    def test_no_requirements_files_define_runtime_dependencies(self):
        forbidden_files = (
            "requirements.txt",
            "requirements.in",
            "Pipfile",
            "poetry.lock",
            "Pipfile.lock",
        )
        for filename in forbidden_files:
            self.assertFalse(
                os.path.exists(os.path.join(ROOT, filename)),
                f"{filename} must not define runtime dependencies for the core SDK.",
            )


if __name__ == "__main__":
    unittest.main()
