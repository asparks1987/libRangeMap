import importlib
import sys
import unittest


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


if __name__ == "__main__":
    unittest.main()
