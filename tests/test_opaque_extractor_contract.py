import json
import os
import unittest


ROOT = os.path.dirname(os.path.dirname(__file__))
CONTRACT_PATH = os.path.join(ROOT, "compliance", "opaque_extractor_contract.json")


class OpaqueExtractorContractTests(unittest.TestCase):
    def test_contract_declares_reject_by_default_policy(self):
        with open(CONTRACT_PATH, "r", encoding="utf-8") as handle:
            contract = json.load(handle)

        self.assertEqual(contract["default_policy"], "reject_without_explicit_extractor")
        self.assertIn("raw pointers without metadata", contract["opaque_runtime_types"])
        self.assertIn("file handles", contract["opaque_runtime_types"])

    def test_contract_fields_cover_determinism_schema_and_failures(self):
        with open(CONTRACT_PATH, "r", encoding="utf-8") as handle:
            contract = json.load(handle)

        required_fields = set(contract["required_contract_fields"])
        self.assertIn("schema", required_fields)
        self.assertIn("failure_policy", required_fields)
        self.assertIn("determinism_statement", required_fields)

        required_failures = {item["name"]: item for item in contract["required_failures"]}
        for name in (
            "no_extractor",
            "missing_metadata",
            "non_deterministic_extractor",
            "unsupported_extractor_output",
        ):
            self.assertEqual(required_failures[name]["expected_error"], "UnsupportedTypeError")

    def test_minimal_example_targets_existing_beta_family(self):
        with open(CONTRACT_PATH, "r", encoding="utf-8") as handle:
            contract = json.load(handle)

        example = contract["minimal_contract_example"]
        self.assertEqual(example["contract_type"], "opaque_extractor")
        self.assertIn(example["output_family"], contract["allowed_output_families"])
        self.assertIn("pointer_metadata_required", example["schema"])
        self.assertTrue(example["schema"]["pointer_metadata_required"]["bounds_checked"])


if __name__ == "__main__":
    unittest.main()
