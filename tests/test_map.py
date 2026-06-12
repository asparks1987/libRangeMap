import unittest

from librangemap import BooleanRangeMapper, FloatRangeMapper, IntegerRangeMapper, MapRangeMapper, SequenceRangeMapper, UnsupportedTypeError


class MapRangeMapperTests(unittest.TestCase):
    def test_map_value_maps_schema_fields(self):
        schema = {
            "age": IntegerRangeMapper(input_range=(0, 120), clip=True),
            "active": BooleanRangeMapper(),
            "score": FloatRangeMapper(input_range=(0.0, 10.0), clip=False),
        }
        mapper = MapRangeMapper(schema)

        value = {"age": 60, "active": True, "score": 5.0}
        mapped = mapper.map_value(value)

        self.assertEqual(mapped["age"], 0.0)
        self.assertEqual(mapped["active"], 1.0)
        self.assertEqual(mapped["score"], 0.0)

    def test_object_input_mapping_supports_attributes(self):
        schema = {
            "label": IntegerRangeMapper(input_range=(0, 1)),
        }
        mapper = MapRangeMapper(schema)
        mapped = mapper.map_value(_AttributeRecord(1))
        self.assertEqual(mapped["label"], 1.0)

    def test_object_input_mapping_supports_property(self):
        class Profile:
            def __init__(self, age: int):
                self._age = age

            @property
            def age(self):
                return self._age

        schema = {
            "age": IntegerRangeMapper(input_range=(0, 200)),
        }
        mapper = MapRangeMapper(schema)
        mapped = mapper.map_value(Profile(100))
        self.assertEqual(mapped["age"], 1.0)

    def test_unknown_object_property_fields_error(self):
        class Profile:
            def __init__(self, age: int, city: str):
                self._age = age
                self._city = city

            @property
            def age(self):
                return self._age

            @property
            def city(self):
                return self._city

        schema = {
            "age": IntegerRangeMapper(input_range=(0, 200)),
        }
        mapper = MapRangeMapper(schema)
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value(Profile(100, "NYC"))

    def test_slots_object_input_mapping_supports_attributes(self):
        schema = {
            "value": IntegerRangeMapper(input_range=(0, 1)),
        }
        mapper = MapRangeMapper(schema)
        mapped = mapper.map_value(_SlotsRecord(1))
        self.assertEqual(mapped["value"], 1.0)

    def test_unknown_fields_error_by_default(self):
        mapper = MapRangeMapper({"age": IntegerRangeMapper(input_range=(0, 200))})
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value({"age": 100, "city": "NYC"})

    def test_unknown_object_fields_error_by_default(self):
        class Profile:
            def __init__(self, age: int, city: str):
                self.age = age
                self.city = city

        mapper = MapRangeMapper({"age": IntegerRangeMapper(input_range=(0, 200))})
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value(Profile(100, "NYC"))

    def test_unknown_object_fields_allowed_when_enabled(self):
        class Profile:
            def __init__(self, age: int, city: str):
                self.age = age
                self.city = city

        mapper = MapRangeMapper(
            {"age": IntegerRangeMapper(input_range=(0, 200))},
            allow_unknown=True,
        )
        mapped = mapper.map_value(Profile(100, "NYC"))
        self.assertEqual(mapped["age"], 1.0)

    def test_unsupported_input_type_fails_explicitly(self):
        mapper = MapRangeMapper({"age": IntegerRangeMapper(input_range=(0, 200))})
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value(123)

    def test_schema_order_is_preserved(self):
        mapper = MapRangeMapper(
            {
                "first": IntegerRangeMapper(input_range=(0, 1)),
                "second": FloatRangeMapper(input_range=(0.0, 1.0)),
            }
        )
        mapped = mapper.map_value({"first": 1, "second": 0.5})
        self.assertEqual(list(mapped.keys()), ["first", "second"])

    def test_unsupported_object_without_schema_fields_fails_explicitly(self):
        class _Opaque:
            pass

        mapper = MapRangeMapper({"value": IntegerRangeMapper(input_range=(0, 1))})
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value(_Opaque())

    def test_schema_mapper_without_to_dict_is_rejected(self):
        class _MapperWithoutToDict:
            def map_value(self, value):
                return value

        with self.assertRaises(UnsupportedTypeError):
            MapRangeMapper({"value": _MapperWithoutToDict()})

    def test_property_accessor_errors_propagate_explicitly(self):
        class _ExplodingProperty:
            @property
            def age(self):
                raise RuntimeError("boom")

        mapper = MapRangeMapper({"age": IntegerRangeMapper(input_range=(0, 200))})
        with self.assertRaises(RuntimeError):
            mapper.map_value(_ExplodingProperty())

    def test_unknown_fields_optional_when_allowed(self):
        mapper = MapRangeMapper({"age": IntegerRangeMapper(input_range=(0, 200))}, allow_unknown=True)
        mapped = mapper.map_value({"age": 100, "city": "NYC"})
        self.assertEqual(mapped, {"age": 1.0})

    def test_missing_field_error(self):
        mapper = MapRangeMapper({"age": IntegerRangeMapper(input_range=(0, 200))})
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value({"city": "NYC"})

    def test_missing_field_with_fallback(self):
        mapper = MapRangeMapper({"age": IntegerRangeMapper(input_range=(0, 200))}, missing_value=-1.0)
        mapped = mapper.map_value({})
        self.assertEqual(mapped, {"age": -1.0})

    def test_missing_field_fallback_must_be_json_serializable(self):
        with self.assertRaises(UnsupportedTypeError):
            MapRangeMapper({"age": IntegerRangeMapper(input_range=(0, 200))}, missing_value=object())

    def test_map_schema_with_empty_and_allow_empty(self):
        mapper = MapRangeMapper({}, allow_empty=True)
        self.assertEqual(mapper.map_value({}), {})

    def test_empty_schema_rejected_by_default(self):
        with self.assertRaises(UnsupportedTypeError):
            MapRangeMapper({})

    def test_nested_map_schema(self):
        inner = MapRangeMapper({"x": IntegerRangeMapper(input_range=(0, 100))})
        outer = MapRangeMapper({"inner": inner})
        mapped = outer.map_value({"inner": {"x": 50}})
        self.assertEqual(mapped["inner"]["x"], 0.0)

    def test_nested_object_and_sequence_mapping_is_deterministic(self):
        record_schema = MapRangeMapper(
            {
                "profile": MapRangeMapper(
                    {
                        "age": IntegerRangeMapper(input_range=(0, 120), clip=True),
                        "active": BooleanRangeMapper(),
                    }
                ),
                "scores": SequenceRangeMapper(IntegerRangeMapper(input_range=(0, 100), clip=True)),
            }
        )
        input_record = {
            "profile": {"age": 30, "active": True},
            "scores": [0, 50, 100],
        }

        first = record_schema.map_value(input_record)
        second = record_schema.map_value(input_record)
        self.assertEqual(first, second)
        self.assertEqual(first["profile"]["age"], -0.5)
        self.assertEqual(first["profile"]["active"], 1.0)
        self.assertEqual(first["scores"], [-1.0, 0.0, 1.0])

    def test_round_trip_map_serialization(self):
        schema = {
            "value": IntegerRangeMapper(input_range=(0, 10), clip=True),
            "flag": BooleanRangeMapper(),
        }
        mapper = MapRangeMapper(schema, allow_unknown=True, allow_empty=False, name="sample")
        serialized = mapper.to_json()
        loaded = MapRangeMapper.from_json(serialized)

        mapped = loaded.map_value({"value": 10, "flag": False, "extra": True})
        self.assertEqual(mapped["value"], 1.0)
        self.assertEqual(mapped["flag"], -1.0)
        self.assertEqual(loaded.name, "sample")
        self.assertEqual(loaded.allow_unknown, True)

    def test_missing_object_attributes_with_fallback(self):
        mapper = MapRangeMapper({"value": IntegerRangeMapper(input_range=(0, 1))}, missing_value=-1.0)
        mapped = mapper.map_value(_AttributeRecord(None))
        self.assertEqual(mapped["value"], -1.0)


class _AttributeRecord:
    def __init__(self, label):
        self.label = label


class _SlotsRecord:
    __slots__ = ("value",)

    def __init__(self, value):
        self.value = value


if __name__ == "__main__":
    unittest.main()
