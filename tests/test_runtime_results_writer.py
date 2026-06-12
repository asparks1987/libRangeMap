import json
import os
import subprocess
import sys
import tempfile
import unittest


ROOT = os.path.dirname(os.path.dirname(__file__))


class RuntimeResultsWriterTests(unittest.TestCase):
    def test_dry_run_writes_schema_compatible_results(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            output_path = os.path.join(tmpdir, "runtime-results.json")
            proc = subprocess.run(
                [
                    sys.executable,
                    os.path.join(ROOT, "tools", "write_runtime_verification_results.py"),
                    "--dry-run",
                    "--output",
                    output_path,
                ],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(proc.returncode, 0, proc.stderr)

            with open(output_path, "r", encoding="utf-8") as handle:
                payload = json.load(handle)

        with open(os.path.join(ROOT, "compliance", "runtime_verification_status.json"), "r", encoding="utf-8") as handle:
            status = json.load(handle)
        with open(os.path.join(ROOT, "compliance", "runtime_verification_results.schema.json"), "r", encoding="utf-8") as handle:
            schema = json.load(handle)

        self.assertEqual(payload["scope"], "alpha_v1_beta_runtime_verification_results")
        self.assertTrue(payload["dry_run"])
        self.assertEqual(len(payload["results"]), 25)
        self.assertEqual(
            [(item["order"], item["name"]) for item in payload["results"]],
            [(item["order"], item["name"]) for item in status["languages"]],
        )
        required_fields = set(schema["required_result_fields"])
        allowed_statuses = set(schema["allowed_result_statuses"])
        for item in payload["results"]:
            self.assertTrue(required_fields.issubset(item))
            self.assertIn(item["result"], allowed_statuses)
            self.assertEqual(item["result"], "skipped")
            self.assertTrue(item["reason"])


if __name__ == "__main__":
    unittest.main()
