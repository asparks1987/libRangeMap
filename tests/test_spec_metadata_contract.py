import json
import os
import unittest

from librangemap import (
    BooleanRangeMapper,
    BytesRangeMapper,
    CategoricalRangeMapper,
    FloatRangeMapper,
    ImageRangeMapper,
    IntegerRangeMapper,
    MapRangeMapper,
    SequenceRangeMapper,
    TemporalRangeMapper,
    TextRangeMapper,
)


ROOT = os.path.dirname(os.path.dirname(__file__))
CONTRACT_PATH = os.path.join(ROOT, "compliance", "spec_metadata_contract.json")


def _reference_mappers():
    integer_mapper = IntegerRangeMapper(input_range=(0, 100), name="integer")
    return {
        "integer": integer_mapper,
        "float": FloatRangeMapper(input_range=(0.0, 1.0), name="float"),
        "boolean": BooleanRangeMapper(name="boolean"),
        "text": TextRangeMapper(mode="alphabet", alphabet="abc", allow_empty=True, name="text"),
        "bytes": BytesRangeMapper(allow_empty=True, name="bytes"),
        "sequences": SequenceRangeMapper(integer_mapper, allow_empty=True, name="sequence"),
        "maps_structs_objects": MapRangeMapper({"value": integer_mapper}, name="map"),
        "categorical_vocab": CategoricalRangeMapper(vocabulary=("red", "green", "blue"), name="category"),
        "temporal": TemporalRangeMapper(input_range=(0.0, 120.0), mode="duration", name="temporal"),
        "image_like": ImageRangeMapper(input_range=(0, 255), mode="grayscale", allow_empty=True, name="image"),
    }


class SpecMetadataContractTests(unittest.TestCase):
    def test_contract_covers_all_beta_families(self):
        with open(CONTRACT_PATH, "r", encoding="utf-8") as handle:
            contract = json.load(handle)

        expected_families = set(_reference_mappers())
        actual_families = {item["family"] for item in contract["family_contracts"]}
        self.assertEqual(actual_families, expected_families)

    def test_python_reference_specs_include_required_metadata(self):
        with open(CONTRACT_PATH, "r", encoding="utf-8") as handle:
            contract = json.load(handle)

        common_fields = set(contract["common_required_fields"])
        mappers = _reference_mappers()
        for family_contract in contract["family_contracts"]:
            family = family_contract["family"]
            with self.subTest(family=family):
                spec = mappers[family].to_dict()
                required_fields = common_fields | set(family_contract["required_fields"])
                self.assertTrue(required_fields.issubset(spec), sorted(required_fields - set(spec)))
                self.assertEqual(spec["mapper_type"], family_contract["mapper_type"])

    def test_nested_specs_recursively_include_common_metadata(self):
        common_fields = {"spec_version", "implementation_version", "mapper_type"}
        sequence_spec = _reference_mappers()["sequences"].to_dict()
        map_spec = _reference_mappers()["maps_structs_objects"].to_dict()

        self.assertTrue(common_fields.issubset(sequence_spec["element_mapper"]))
        for nested_spec in map_spec["schema"].values():
            self.assertTrue(common_fields.issubset(nested_spec))


if __name__ == "__main__":
    unittest.main()
