import json
import os
import re
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

    def test_alpha_wrapper_readme_contract_sections(self):
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

        required_headings = (
            r"^## Install/use",
            r"^## 2-line quickstart",
            r"^#{2,3} Failure contract",
            r"^#{2,3} Family status",
        )

        for item in canon["languages"]:
            name = item["name"].lower()
            key = slug_map.get(name)
            self.assertIsNotNone(key, f"Missing slug mapping for {name}")

            if name == "python":
                continue

            readme = os.path.join(root, "wrappers", key, "README.md")
            verifier = os.path.join(root, "wrappers", key, "test.cmd")
            self.assertTrue(os.path.isfile(readme), f"Missing README for {item['name']}")
            self.assertTrue(os.path.isfile(verifier), f"Missing smoke verifier for {item['name']}")
            with open(readme, "r", encoding="utf-8") as handle:
                readme_text = handle.read()
            for heading in required_headings:
                self.assertIsNotNone(
                    re.search(heading, readme_text, flags=re.MULTILINE),
                    f"README missing heading pattern '{heading}' for {item['name']}",
                )

    def test_runtime_verification_status_matches_alpha_manifest(self):
        root = os.path.dirname(os.path.dirname(__file__))
        canon_path = os.path.join(root, "compliance", "alpha_v1_languages.json")
        status_path = os.path.join(root, "compliance", "runtime_verification_status.json")
        with open(canon_path, "r", encoding="utf-8") as handle:
            canon = json.load(handle)
        with open(status_path, "r", encoding="utf-8") as handle:
            status = json.load(handle)

        canon_languages = [(item["order"], item["name"]) for item in canon["languages"]]
        status_languages = [(item["order"], item["name"]) for item in status["languages"]]
        self.assertEqual(status_languages, canon_languages)
        self.assertEqual(status["source_test"], "tests/test_alpha_wrapper_runtime.py")

        root_statuses = {"tracked_by_runtime_test", "environment_gated"}
        for item in status["languages"]:
            self.assertIn(item["runtime_status"], root_statuses)
            self.assertTrue(item["smoke_check"])
            if item["smoke_check"].endswith(".cmd"):
                self.assertTrue(
                    os.path.isfile(os.path.join(root, item["smoke_check"])),
                    f"Missing smoke check for {item['name']}: {item['smoke_check']}",
                )

    def test_runtime_verification_results_schema_matches_status_manifest(self):
        root = os.path.dirname(os.path.dirname(__file__))
        status_path = os.path.join(root, "compliance", "runtime_verification_status.json")
        schema_path = os.path.join(root, "compliance", "runtime_verification_results.schema.json")
        with open(status_path, "r", encoding="utf-8") as handle:
            status = json.load(handle)
        with open(schema_path, "r", encoding="utf-8") as handle:
            schema = json.load(handle)

        self.assertEqual(schema["status_source"], "compliance/runtime_verification_status.json")
        self.assertEqual(schema["source_test"], status["source_test"])
        self.assertEqual(set(schema["allowed_result_statuses"]), {"verified", "skipped", "failed"})

        required_fields = set(schema["required_result_fields"])
        for field in ("order", "name", "slug", "smoke_check", "result", "reason"):
            self.assertIn(field, required_fields)

        example_results = schema["example_result_file"]["results"]
        self.assertGreaterEqual(len(example_results), 2)
        status_by_order = {item["order"]: item for item in status["languages"]}
        for item in example_results:
            source = status_by_order[item["order"]]
            self.assertEqual(item["name"], source["name"])
            self.assertEqual(item["slug"], source["slug"])
            self.assertEqual(item["smoke_check"], source["smoke_check"])
            self.assertIn(item["result"], schema["allowed_result_statuses"])
            self.assertTrue(item["reason"])


if __name__ == "__main__":
    unittest.main()
