import json
import os
import unittest


ROOT = os.path.dirname(os.path.dirname(__file__))


class BetaCompletionAuditTests(unittest.TestCase):
    def test_beta_manifest_marks_beta_complete_without_claiming_production(self):
        with open(os.path.join(ROOT, "compliance", "beta_readiness.json"), "r", encoding="utf-8") as handle:
            manifest = json.load(handle)

        self.assertEqual(manifest["beta_v1_status"], "complete")
        self.assertEqual(manifest["production_v1_status"], "path_defined_hardening_pending")
        self.assertEqual(manifest["milestones"]["Docs finish"], "complete")
        self.assertEqual(manifest["milestones"]["Packaging readiness"], "complete_for_beta")
        self.assertEqual(manifest["readiness_gates"]["Docs finish"]["status"], "complete")
        self.assertEqual(manifest["readiness_gates"]["Packaging readiness"]["status"], "complete_for_beta")

        for item in manifest["languages"]:
            self.assertEqual(item.get("planned", []), [])
            self.assertEqual(set(item["implemented"]), set(manifest["families"]))

    def test_beta_completion_audit_links_required_evidence(self):
        audit_path = os.path.join(ROOT, "docs", "beta_completion_audit.md")
        with open(audit_path, "r", encoding="utf-8") as handle:
            audit = handle.read()

        for required in (
            "Beta v1 readiness is complete.",
            "Production v1 remains pending",
            "../compliance/beta_readiness.json",
            "../compliance/beta_conformance_fixtures.json",
            "../compliance/spec_metadata_contract.json",
            "../compliance/runtime_verification_status.json",
        ):
            self.assertIn(required, audit)


if __name__ == "__main__":
    unittest.main()
