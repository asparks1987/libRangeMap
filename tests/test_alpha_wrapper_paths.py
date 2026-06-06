import json
import os
import unittest


class AlphaWrapperPathTests(unittest.TestCase):
    def test_alpha_v1_language_paths_exist(self):
        root = os.path.dirname(os.path.dirname(__file__))
        canon_path = os.path.join(root, "compliance", "alpha_v1_languages.json")
        with open(canon_path, "r", encoding="utf-8") as handle:
            canon = json.load(handle)

        slug_map = {
            "python": "python",
            "c": "c",
            "java": "java",
            "c++": "cpp",
            "c#": "csharp",
            "javascript": "javascript",
            "visual basic": "vb",
            "r": "r",
            "sql": "sql",
            "delphi/object pascal": "delphi",
            "fortran": "fortran",
            "scratch": "scratch",
            "perl": "perl",
            "php": "php",
            "rust": "rust",
            "go": "go",
            "assembly language": "assembly",
            "swift": "swift",
            "ada": "ada",
            "matlab": "matlab",
            "classic visual basic": "vb6",
            "pl/sql": "plsql",
            "ruby": "ruby",
            "prolog": "prolog",
            "cobol": "cobol",
        }

        required_artifacts = {
            "python": None,
            "c": "c",
            "java": "java",
            "cpp": "cpp",
            "csharp": "csharp",
            "javascript": "javascript",
            "vb": "vb",
            "r": "r\\librangemap.R",
            "sql": "sql\\librangemap.sql",
            "delphi": "delphi\\librangemap.pas",
            "fortran": "fortran\\librangemap.f90",
            "scratch": "scratch\\librangemap.md",
            "perl": "perl\\librangemap.pl",
            "php": "php\\LibrangeMap.php",
            "rust": "rust",
            "go": "go\\librangemap\\integer_windows.go",
            "assembly": "assembly\\librangemap.asm",
            "swift": "swift\\LibrangeMap.swift",
            "ada": "ada\\librangemap.adb",
            "matlab": "matlab\\librangemap.m",
            "vb6": "vb6\\Librangemap.bas",
            "plsql": "plsql\\librangemap.sql",
            "ruby": "ruby\\lib\\librangemap.rb",
            "prolog": "prolog\\librangemap.pl",
            "cobol": "cobol\\librangemap.cob",
        }

        for item in canon["languages"]:
            name = item["name"].lower()
            key = slug_map.get(name)
            self.assertIsNotNone(key, f"Missing slug mapping for {name}")
            if name == "python":
                marker = os.path.join(root, "libRangeMap.py")
                self.assertTrue(os.path.isfile(marker), "Python reference path must exist")
                continue

            wrapper_dir = os.path.join(root, "wrappers", key)
            self.assertTrue(
                os.path.isdir(wrapper_dir),
                f"Missing wrapper/runtime path for {item['name']} at {wrapper_dir}",
            )

            readme = os.path.join(wrapper_dir, "README.md")
            self.assertTrue(os.path.isfile(readme), f"Missing README for {item['name']} wrapper")

            rel_artifact = required_artifacts.get(key)
            if rel_artifact and rel_artifact != key:
                artifact = os.path.join(root, "wrappers", rel_artifact)
                self.assertTrue(
                    os.path.isfile(artifact),
                    f"Missing canonical artifact for {item['name']} at {artifact}",
                )

            if name in ("c", "java", "cpp", "csharp", "javascript", "vb", "rust", "go", "ruby"):
                # Existing wrappers are treated as runtime paths in their implementation directories.
                self.assertTrue(os.path.isfile(readme))


if __name__ == "__main__":
    unittest.main()
