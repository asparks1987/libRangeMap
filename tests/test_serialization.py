import os
import os
import tempfile
import unittest
from unittest.mock import patch

from librangemap import (
    BytesRangeMapper,
    CategoricalRangeMapper,
    BooleanRangeMapper,
    FloatRangeMapper,
    IntegerRangeMapper,
    MapRangeMapper,
    SerializationError,
    SequenceRangeMapper,
    ImageRangeMapper,
    TemporalRangeMapper,
    TextRangeMapper,
)
from librangemap import __version__
from librangemap.serialization import dumps_json, load_json_file, loads_json, save_json_file


class SerializationTests(unittest.TestCase):
    def test_public_import_surface_includes_beta_families(self):
        from librangemap import __all__ as public_exports

        expected_exports = {
            "IntegerRangeMapper",
            "FloatRangeMapper",
            "SequenceRangeMapper",
            "MapRangeMapper",
            "BytesRangeMapper",
            "TextRangeMapper",
            "TemporalRangeMapper",
            "ImageRangeMapper",
            "BooleanRangeMapper",
            "CategoricalRangeMapper",
            "InvalidRangeError",
            "NotFiniteError",
            "OutOfRangeError",
            "RangeMapError",
            "SerializationError",
            "SPEC_VERSION",
            "UnsupportedTypeError",
            "__version__",
        }
        self.assertEqual(set(public_exports), expected_exports)

    def test_star_import_exports_expected_public_names(self):
        namespace = {}
        exec("from librangemap import *", namespace)

        for name in (
            "IntegerRangeMapper",
            "FloatRangeMapper",
            "SequenceRangeMapper",
            "MapRangeMapper",
            "BytesRangeMapper",
            "TextRangeMapper",
            "TemporalRangeMapper",
            "ImageRangeMapper",
            "BooleanRangeMapper",
            "CategoricalRangeMapper",
            "InvalidRangeError",
            "NotFiniteError",
            "OutOfRangeError",
            "RangeMapError",
            "SerializationError",
            "SPEC_VERSION",
            "UnsupportedTypeError",
            "__version__",
        ):
            self.assertIn(name, namespace)

    def test_to_dict_and_from_dict_round_trip(self):
        mapper = IntegerRangeMapper(input_range=(0, 255), clip=True, name="pixel")
        loaded = IntegerRangeMapper.from_dict(mapper.to_dict())
        self.assertEqual(loaded.to_dict(), mapper.to_dict())
        self.assertEqual(loaded.map_value(255), 1.0)

    def test_to_json_and_from_json_round_trip(self):
        mapper = IntegerRangeMapper(input_range=(-10, 10))
        loaded = IntegerRangeMapper.from_json(mapper.to_json())
        self.assertEqual(loaded.map_value(0), 0.0)

    def test_rejects_malformed_json(self):
        with self.assertRaises(SerializationError):
            IntegerRangeMapper.from_json('{"spec_version": "1.0",')

    def test_rejects_non_string_json_input(self):
        with self.assertRaises(SerializationError):
            IntegerRangeMapper.from_json(None)  # type: ignore[arg-type]

    def test_rejects_non_serializable_payloads(self):
        with self.assertRaises(SerializationError):
            dumps_json({"payload": object()})

    def test_rejects_non_finite_json_numbers(self):
        with self.assertRaises(SerializationError):
            dumps_json({"payload": float("nan")})
        with self.assertRaises(SerializationError):
            dumps_json({"payload": float("inf")})
        with self.assertRaises(SerializationError):
            loads_json('{"payload": NaN}')

    def test_rejects_duplicate_json_keys(self):
        with self.assertRaises(SerializationError):
            loads_json('{"mapper_type": "integer_range", "mapper_type": "float_range"}')

    def test_dumps_json_is_stable_and_sorted(self):
        text = dumps_json({"b": 1, "a": {"d": 4, "c": 3}})
        self.assertEqual(text, '{\n  "a": {\n    "c": 3,\n    "d": 4\n  },\n  "b": 1\n}\n')

    def test_load_and_save_json_wrap_os_errors(self):
        with patch("builtins.open", side_effect=OSError("boom")):
            with self.assertRaises(SerializationError):
                save_json_file("mapper.json", {"value": 1})
        with patch("builtins.open", side_effect=OSError("boom")):
            with self.assertRaises(SerializationError):
                load_json_file("mapper.json")

    def test_save_and_load_round_trip(self):
        mapper = IntegerRangeMapper(input_range=(0, 100), clip=True)
        with tempfile.TemporaryDirectory() as tmpdir:
            path = os.path.join(tmpdir, "mapper.json")
            mapper.save(path)
            loaded = IntegerRangeMapper.load(path)
        self.assertEqual(loaded.map_value(-10), -1.0)
        self.assertEqual(loaded.map_value(100), 1.0)

    def test_rejects_wrong_spec_version(self):
        data = IntegerRangeMapper(input_range=(0, 1)).to_dict()
        data["spec_version"] = "0"
        with self.assertRaises(SerializationError):
            IntegerRangeMapper.from_dict(data)

    def test_rejects_wrong_mapper_type(self):
        data = IntegerRangeMapper(input_range=(0, 1)).to_dict()
        data["mapper_type"] = "float_range"
        with self.assertRaises(SerializationError):
            IntegerRangeMapper.from_dict(data)

    def test_other_mappers_include_version_and_round_trip(self):
        float_mapper = FloatRangeMapper(input_range=(0.0, 1.0))
        bool_mapper = BooleanRangeMapper()
        text_mapper = TextRangeMapper(mode="alphabet", alphabet="abc")
        seq_mapper = SequenceRangeMapper(float_mapper)
        map_mapper = MapRangeMapper(
            {
                "value": IntegerRangeMapper(input_range=(0, 10)),
                "label": BooleanRangeMapper(),
            },
            allow_unknown=True,
            name="record-mapper",
        )

        for mapper in (float_mapper, bool_mapper, text_mapper, seq_mapper, map_mapper, BytesRangeMapper(), ImageRangeMapper()):
            spec = mapper.to_dict()
            self.assertEqual(spec.get("implementation_version"), __version__)

        float_loaded = FloatRangeMapper.from_dict(float_mapper.to_dict())
        bool_loaded = BooleanRangeMapper.from_dict(bool_mapper.to_dict())
        text_loaded = TextRangeMapper.from_dict(text_mapper.to_dict())
        seq_loaded = SequenceRangeMapper.from_dict(seq_mapper.to_dict())
        map_loaded = MapRangeMapper.from_dict(map_mapper.to_dict())
        bytes_loaded = BytesRangeMapper.from_dict(BytesRangeMapper(output_range=(0.0, 255.0)).to_dict())
        categorical_mapper = CategoricalRangeMapper(vocabulary=("red", "green", "blue"), name="label")
        categorical_loaded = CategoricalRangeMapper.from_dict(categorical_mapper.to_dict())
        temporal_mapper = TemporalRangeMapper(input_range=(0.0, 10.0), mode="duration")
        temporal_loaded = TemporalRangeMapper.from_dict(temporal_mapper.to_dict())
        image_mapper = ImageRangeMapper(input_range=(0, 255), mode="grayscale")
        image_loaded = ImageRangeMapper.from_dict(image_mapper.to_dict())

        self.assertEqual(float_loaded.map_value(0.5), 0.0)
        self.assertEqual(bool_loaded.map_value(True), 1.0)
        self.assertEqual(text_loaded.map_value("a"), [-1.0])
        self.assertEqual(seq_loaded.map_value([0.0, 1.0]), [0.0, 1.0])
        self.assertEqual(map_loaded.map_value({"value": 10, "label": False}), {"value": 1.0, "label": -1.0})
        self.assertEqual(bytes_loaded.map_value(bytes([0, 255])), [0.0, 255.0])
        self.assertEqual(categorical_loaded.map_value("green"), 0.0)
        self.assertEqual(temporal_loaded.map_value(0), -1.0)
        self.assertEqual(image_loaded.map_value([0, 127]), [-1.0, -0.0039215686274509665])

    def test_nested_map_sequence_and_categorical_round_trip(self):
        nested_mapper = MapRangeMapper(
            {
                "profile": MapRangeMapper(
                    {
                        "age": IntegerRangeMapper(input_range=(0, 100), clip=True),
                        "tags": SequenceRangeMapper(
                            CategoricalRangeMapper(vocabulary=("red", "green", "blue")),
                            allow_empty=True,
                        ),
                    }
                ),
                "active": BooleanRangeMapper(),
            },
            allow_unknown=True,
            name="nested-profile",
        )

        serialized = nested_mapper.to_json()
        restored = MapRangeMapper.from_json(serialized)
        sample = {
            "profile": {
                "age": 25,
                "tags": ["red", "green"],
            },
            "active": True,
        }

        first = nested_mapper.map_value(sample)
        second = restored.map_value(sample)

        self.assertEqual(first, second)
        self.assertEqual(first["profile"]["age"], -0.5)
        self.assertEqual(first["profile"]["tags"], [-1.0, 0.0])
        self.assertEqual(first["active"], 1.0)

    def test_nested_spec_dispatch_rejects_unsupported_mapper_types(self):
        sequence_spec = {
            "spec_version": "1.0",
            "mapper_type": "sequence_range",
            "element_mapper": {
                "spec_version": "1.0",
                "mapper_type": "other",
            },
            "allow_empty": False,
            "preserve_tuples": True,
        }
        map_spec = {
            "spec_version": "1.0",
            "mapper_type": "map_range",
            "schema": {
                "field": {
                    "spec_version": "1.0",
                    "mapper_type": "other",
                }
            },
            "allow_unknown": False,
            "allow_empty": False,
        }

        with self.assertRaises(SerializationError):
            SequenceRangeMapper.from_dict(sequence_spec)
        with self.assertRaises(SerializationError):
            MapRangeMapper.from_dict(map_spec)

    def test_nested_spec_dispatch_rejects_missing_required_fields(self):
        missing_element_mapper_spec = {
            "spec_version": "1.0",
            "mapper_type": "sequence_range",
            "allow_empty": False,
            "preserve_tuples": True,
        }
        missing_schema_spec = {
            "spec_version": "1.0",
            "mapper_type": "map_range",
            "allow_unknown": False,
            "allow_empty": False,
        }

        with self.assertRaises(SerializationError):
            SequenceRangeMapper.from_dict(missing_element_mapper_spec)
        with self.assertRaises(SerializationError):
            MapRangeMapper.from_dict(missing_schema_spec)


if __name__ == "__main__":
    unittest.main()
