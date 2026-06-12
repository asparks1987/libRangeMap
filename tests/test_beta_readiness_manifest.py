import json
import os
import unittest


EXPECTED_FAMILIES = [
    "integer",
    "float",
    "boolean",
    "text",
    "bytes",
    "sequences",
    "maps_structs_objects",
    "categorical_vocab",
    "temporal",
    "image_like",
]

EXPECTED_LANGUAGES = [
    "Python",
    "C",
    "Java",
    "C++",
    "C#",
    "JavaScript",
    "Visual Basic",
    "R",
    "SQL",
    "Delphi/Object Pascal",
    "Fortran",
    "Scratch",
    "Perl",
    "PHP",
    "Rust",
    "Go",
    "Assembly language",
    "Swift",
    "Ada",
    "MATLAB",
    "Classic Visual Basic",
    "PL/SQL",
    "Ruby",
    "Prolog",
    "COBOL",
]


class BetaReadinessManifestTests(unittest.TestCase):
    def setUp(self):
        self.root = os.path.dirname(os.path.dirname(__file__))
        path = os.path.join(self.root, "compliance", "beta_readiness.json")
        with open(path, "r", encoding="utf-8-sig") as handle:
            self.manifest = json.load(handle)

    def test_manifest_shape(self):
        self.assertEqual(self.manifest["scope"], "beta_v1_readiness")
        self.assertEqual(self.manifest["spec_version"], "1.0")
        self.assertEqual(self.manifest["families"], EXPECTED_FAMILIES)

    def test_alpha_order_and_language_coverage(self):
        languages = [entry["name"] for entry in self.manifest["languages"]]
        self.assertEqual(languages, EXPECTED_LANGUAGES)
        orders = [entry["order"] for entry in self.manifest["languages"]]
        self.assertEqual(orders, list(range(1, 26)))

    def test_family_keys_and_integer_default_coverage(self):
        expected_family_set = set(EXPECTED_FAMILIES)
        for entry in self.manifest["languages"]:
            implemented = entry.get("implemented", [])
            planned = entry.get("planned", [])
            self.assertIn("integer", implemented)
            self.assertNotIn("integer", planned)
            combined = set(implemented) | set(planned)
            self.assertEqual(expected_family_set, combined)
            self.assertEqual(len(implemented) + len(planned), len(expected_family_set))
            self.assertEqual(set(implemented).intersection(set(planned)), set())
            self.assertIsInstance(entry.get("slug", ""), str)
            self.assertTrue(entry["slug"].strip())

        python_entry = next(entry for entry in self.manifest["languages"] if entry["name"] == "Python")
        self.assertEqual(set(python_entry["implemented"]), expected_family_set)
        self.assertEqual(python_entry["planned"], [])

        java_entry = next(entry for entry in self.manifest["languages"] if entry["name"] == "Java")
        self.assertIn("temporal", java_entry["implemented"])
        self.assertNotIn("temporal", java_entry.get("planned", []))

        c_entry = next(entry for entry in self.manifest["languages"] if entry["name"] == "C")
        self.assertIn("image_like", c_entry["implemented"])
        self.assertIn("temporal", c_entry["implemented"])
        self.assertNotIn("temporal", c_entry.get("planned", []))

        scratch_entry = next(entry for entry in self.manifest["languages"] if entry["name"] == "Scratch")
        self.assertIn("temporal", scratch_entry["implemented"])
        self.assertNotIn("temporal", scratch_entry.get("planned", []))

        assembly_entry = next(entry for entry in self.manifest["languages"] if entry["name"] == "Assembly language")
        self.assertIn("temporal", assembly_entry["implemented"])
        self.assertNotIn("temporal", assembly_entry.get("planned", []))

        cobol_entry = next(entry for entry in self.manifest["languages"] if entry["name"] == "COBOL")
        self.assertIn("categorical_vocab", cobol_entry["implemented"])
        self.assertIn("temporal", cobol_entry["implemented"])
        self.assertNotIn("categorical_vocab", cobol_entry.get("planned", []))
        self.assertNotIn("temporal", cobol_entry.get("planned", []))

    def test_milestone_status_shape(self):
        milestones = self.manifest["milestones"]
        self.assertEqual(milestones["Foundation"], "complete")
        self.assertIn(milestones["Compatibility matrix"], {"in_progress", "complete"})
        self.assertIn(milestones["Wrapper parity"], {"done", "complete", "in_progress"})

    def test_readiness_gates_shape(self):
        valid_statuses = {"complete", "done", "in_progress"}

        self.assertIn("readiness_gates", self.manifest)
        self.assertEqual(self.manifest["production_target"]["goal"], "99_percent_plus_practical_coverage")
        self.assertEqual(self.manifest["production_target"]["base_ordinary_coverage"], 0.99)
        self.assertTrue(self.manifest["production_target"]["extractor_required_for_opaque_runtime_objects"])
        self.assertEqual(
            len(self.manifest["production_target"]["opaque_runtime_objects"]),
            len(self.manifest["opaque_runtime_extractor_required"]),
        )

        gate_weight_total = 0.0
        for item in self.manifest["readiness_gates"].values():
            self.assertIn(item.get("status"), valid_statuses)
            self.assertIn("status", item)
            self.assertIsInstance(item["alpha_completion_weight"], (int, float))
            self.assertGreater(item["alpha_completion_weight"], 0.0)
            self.assertLessEqual(item["alpha_completion_weight"], 1.0)
            gate_weight_total += float(item["alpha_completion_weight"])

        self.assertAlmostEqual(gate_weight_total, 1.0, places=6)

    def test_default_output_range_is_alpha_target(self):
        self.assertEqual(self.manifest["default_output_range"], [-1.0, 1.0])

    def test_roadmap_docs_reflect_current_reference_and_wrapper_evidence(self):
        roadmap_path = os.path.join(self.root, "docs", "beta_roadmap.md")
        production_path = os.path.join(self.root, "docs", "production_path_to_v1.md")
        compatibility_path = os.path.join(self.root, "docs", "compatibility.md")
        wrapper_contract_path = os.path.join(self.root, "docs", "beta_wrapper_contract.md")

        with open(roadmap_path, "r", encoding="utf-8") as handle:
            roadmap = handle.read()
        with open(production_path, "r", encoding="utf-8") as handle:
            production = handle.read()
        with open(compatibility_path, "r", encoding="utf-8") as handle:
            compatibility = handle.read()
        with open(wrapper_contract_path, "r", encoding="utf-8") as handle:
            wrapper_contract = handle.read()

        self.assertIn("## Alpha and Beta Milestones", roadmap)
        self.assertIn("Compatibility matrix", roadmap)
        for runtime_name in ("Python", "JavaScript", "C++", "C#", "PHP"):
            self.assertIn(runtime_name, roadmap)
        self.assertIn("## Production-ready claim target", production)
        for runtime_name in ("Python", "JavaScript", "C++", "C#", "PHP"):
            self.assertIn(runtime_name, production)
        self.assertIn("The current beta blocker", compatibility)
        for runtime_name in ("Python", "JavaScript", "C++", "C#", "PHP"):
            self.assertIn(runtime_name, compatibility)
        self.assertIn("| 14 | PHP |", wrapper_contract)


if __name__ == "__main__":
    unittest.main()
