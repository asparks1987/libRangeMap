import json
import os
import unittest

from librangemap import IntegerRangeMapper


class ComplianceFixtureTests(unittest.TestCase):
    def test_integer_alpha_fixture(self):
        root = os.path.dirname(os.path.dirname(__file__))
        path = os.path.join(root, "compliance", "integer_alpha.json")
        with open(path, "r", encoding="utf-8") as handle:
            fixture = json.load(handle)

        self.assertEqual(fixture["spec_version"], "1.0-alpha")
        self.assertEqual(fixture["mapper_type"], "integer_range")

        for case in fixture["cases"]:
            mapper = IntegerRangeMapper(
                input_range=case["input_range"],
                output_range=case["output_range"],
                clip=case["clip"],
            )
            for item in case["values"]:
                self.assertEqual(mapper.map_value(item["input"]), item["output"], case["name"])


if __name__ == "__main__":
    unittest.main()
