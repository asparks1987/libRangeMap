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
    OutOfRangeError,
    SequenceRangeMapper,
    TemporalRangeMapper,
    TextRangeMapper,
    UnsupportedTypeError,
)


ROOT = os.path.dirname(os.path.dirname(__file__))
FIXTURE_PATH = os.path.join(ROOT, "compliance", "beta_conformance_fixtures.json")
EXPECTED_FAMILIES = {
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
}
ERROR_TYPES = {
    "OutOfRangeError": OutOfRangeError,
    "UnsupportedTypeError": UnsupportedTypeError,
}


def _load_fixture():
    with open(FIXTURE_PATH, "r", encoding="utf-8") as handle:
        return json.load(handle)


def _mapper_from_spec(spec):
    mapper_type = spec["mapper_type"]
    if mapper_type == "integer_range":
        return IntegerRangeMapper(
            input_range=tuple(spec["input_range"]),
            output_range=tuple(spec.get("output_range", (-1.0, 1.0))),
            clip=spec.get("clip", False),
        )
    if mapper_type == "float_range":
        return FloatRangeMapper(
            input_range=tuple(spec["input_range"]),
            output_range=tuple(spec.get("output_range", (-1.0, 1.0))),
            clip=spec.get("clip", False),
        )
    if mapper_type == "boolean_range":
        return BooleanRangeMapper(
            output_range=tuple(spec.get("output_range", (-1.0, 1.0))),
            false_value=spec.get("false_value", -1.0),
            true_value=spec.get("true_value", 1.0),
        )
    if mapper_type == "text_range":
        return TextRangeMapper(
            mode=spec.get("mode", "codepoint"),
            alphabet=spec.get("alphabet"),
            output_range=tuple(spec.get("output_range", (-1.0, 1.0))),
            clip=spec.get("clip", False),
            allow_empty=spec.get("allow_empty", False),
        )
    if mapper_type == "bytes_range":
        return BytesRangeMapper(
            output_range=tuple(spec.get("output_range", (-1.0, 1.0))),
            allow_empty=spec.get("allow_empty", False),
        )
    if mapper_type == "sequence_range":
        return SequenceRangeMapper(
            _mapper_from_spec(spec["element_mapper"]),
            allow_empty=spec.get("allow_empty", False),
            preserve_tuples=spec.get("preserve_tuples", True),
        )
    if mapper_type == "map_range":
        return MapRangeMapper(
            {key: _mapper_from_spec(value) for key, value in spec["schema"].items()},
            allow_unknown=spec.get("allow_unknown", False),
            allow_empty=spec.get("allow_empty", False),
        )
    if mapper_type == "categorical_range":
        return CategoricalRangeMapper(
            vocabulary=tuple(spec["vocabulary"]),
            output_range=tuple(spec.get("output_range", (-1.0, 1.0))),
        )
    if mapper_type == "temporal_range":
        return TemporalRangeMapper(
            input_range=tuple(spec["input_range"]),
            mode=spec.get("mode", "timestamp"),
            output_range=tuple(spec.get("output_range", (-1.0, 1.0))),
            clip=spec.get("clip", False),
        )
    if mapper_type == "image_range":
        return ImageRangeMapper(
            input_range=tuple(spec.get("input_range", (0, 255))),
            mode=spec.get("mode", "grayscale"),
            output_range=tuple(spec.get("output_range", (-1.0, 1.0))),
            clip=spec.get("clip", False),
            allow_empty=spec.get("allow_empty", False),
        )
    raise AssertionError(f"unsupported fixture mapper_type {mapper_type}")


class BetaConformanceFixtureTests(unittest.TestCase):
    def test_fixture_covers_exact_beta_families(self):
        fixture = _load_fixture()
        self.assertEqual(fixture["default_output_range"], [-1.0, 1.0])
        self.assertEqual({item["family"] for item in fixture["families"]}, EXPECTED_FAMILIES)

    def test_fixture_expected_outputs_match_python_reference(self):
        fixture = _load_fixture()
        for family in fixture["families"]:
            mapper = _mapper_from_spec(family["mapper"])
            for case in family["cases"]:
                with self.subTest(family=family["family"], case=case["name"]):
                    self.assertEqual(mapper.map_value(_input_for_family(family["family"], case["input"])), case["expected"])

    def test_fixture_failure_cases_are_explicit(self):
        fixture = _load_fixture()
        for family in fixture["families"]:
            mapper = _mapper_from_spec(family["mapper"])
            for case in family["failures"]:
                with self.subTest(family=family["family"], case=case["name"]):
                    self.assertIn(case["error"], ERROR_TYPES)
                    with self.assertRaises(ERROR_TYPES[case["error"]]):
                        mapper.map_value(_input_for_family(family["family"], case["input"]))


def _input_for_family(family, value):
    if family == "bytes":
        return bytes(value)
    return value


if __name__ == "__main__":
    unittest.main()
