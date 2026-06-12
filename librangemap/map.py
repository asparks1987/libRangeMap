"""Map/object schema mapping into normalized values."""

from __future__ import annotations

from typing import Any, Dict, Iterable, Optional, Mapping

from .errors import SerializationError, UnsupportedTypeError
from .serialization import dumps_json, load_json_file, loads_json, save_json_file
from .spec import MAPPER_TYPE_MAP_RANGE, SPEC_VERSION

_MISSING = object()


def _validate_schema(value: object, field_name: str, *, allow_empty: bool) -> Dict[str, Any]:
    if not isinstance(value, Mapping):
        raise UnsupportedTypeError(f"{field_name} must be a mapping of field name to mapper.")

    if not value and not allow_empty:
        raise UnsupportedTypeError(f"{field_name} must include at least one field.")

    validated = {}
    for key, mapper in value.items():
        if not isinstance(key, str) or not key:
            raise UnsupportedTypeError("schema field names must be non-empty strings.")
        if not hasattr(mapper, "map_value") or not callable(mapper.map_value):
            raise UnsupportedTypeError(f"schema field {key!r} requires a mapper with map_value().")
        if not hasattr(mapper, "to_dict") or not callable(mapper.to_dict):
            raise UnsupportedTypeError(f"schema field {key!r} requires a mapper with to_dict().")
        validated[key] = mapper

    return validated


def _mapping_fields(obj: object) -> Optional[Mapping[str, Any]]:
    if isinstance(obj, Mapping):
        return obj
    return None


class MapRangeMapper:
    """Map dictionaries/objects by explicit schema to normalized outputs."""

    mapper_type = MAPPER_TYPE_MAP_RANGE
    spec_version = SPEC_VERSION

    def __init__(
        self,
        schema: Mapping[str, Any],
        *,
        allow_unknown: bool = False,
        allow_empty: bool = False,
        missing_value: object = _MISSING,
        name: Optional[str] = None,
    ) -> None:
        if not isinstance(allow_unknown, bool):
            raise UnsupportedTypeError("allow_unknown must be a bool.")
        if not isinstance(allow_empty, bool):
            raise UnsupportedTypeError("allow_empty must be a bool.")
        if name is not None and not isinstance(name, str):
            raise UnsupportedTypeError("name must be a string when provided.")
        if name is not None and name == "":
            raise UnsupportedTypeError("name must not be empty.")
        if not isinstance(schema, Mapping):
            raise UnsupportedTypeError("schema must be a mapping of field names to mappers.")
        if missing_value is not _MISSING:
            try:
                dumps_json(missing_value)
            except SerializationError as exc:
                raise UnsupportedTypeError("missing_value must be JSON-serializable.") from exc

        self.schema = dict(_validate_schema(schema, "schema", allow_empty=allow_empty))
        self.allow_unknown = allow_unknown
        self.allow_empty = allow_empty
        self.missing_value = missing_value
        self.name = name

    def map_value(self, value: object) -> Dict[str, Any]:
        """Map each schema field using its mapped sub-policy."""
        fields = _mapping_fields(value)
        discovered_fields: Optional[Iterable[str]] = None

        if fields is not None:
            if not self.allow_unknown:
                unknown_fields = [str(key) for key in fields.keys() if key not in self.schema]
                if unknown_fields:
                    raise UnsupportedTypeError(
                        f"input has schema fields not declared in map: {unknown_fields}; "
                        "set allow_unknown=True to ignore extra fields."
                    )

        mapped = {}
        if fields is not None:
            for field_name, mapper in self.schema.items():
                if field_name in fields:
                    mapped[field_name] = mapper.map_value(fields[field_name])
                elif self.missing_value is not _MISSING:
                    mapped[field_name] = self.missing_value
                else:
                    raise UnsupportedTypeError(f"missing required field {field_name!r} in map input.")
        else:
            discovered_fields = tuple(_object_fields(value))
            if not self.allow_unknown and discovered_fields:
                unknown_fields = [field_name for field_name in discovered_fields if field_name not in self.schema]
                if unknown_fields:
                    raise UnsupportedTypeError(
                        f"input has schema fields not declared in map: {unknown_fields}; "
                        "set allow_unknown=True to ignore extra fields."
                    )

            if not hasattr(value, "__dict__") and not hasattr(value, "__slots__") and not any(
                _has_field(value, field_name) for field_name in self.schema
            ):
                raise UnsupportedTypeError("value must be a mapping or an object with accessible attributes.")
            for field_name, mapper in self.schema.items():
                try:
                    field_value = _get_field_value(value, field_name)
                except AttributeError:
                    field_value = _MISSING

                if field_value is not _MISSING:
                    mapped[field_name] = mapper.map_value(field_value)
                elif self.missing_value is not _MISSING:
                    mapped[field_name] = self.missing_value
                else:
                    raise UnsupportedTypeError(f"missing required field {field_name!r} in object input.")

        return mapped

    def transform(self, value: object) -> Dict[str, Any]:
        """Alias for map_value."""
        return self.map_value(value)

    def map(self, value: object) -> Dict[str, Any]:
        """Compatibility alias."""
        return self.map_value(value)

    def to_dict(self) -> Dict[str, Any]:
        """Return a JSON-compatible mapper spec."""
        data = {
            "spec_version": self.spec_version,
            "implementation_version": _implementation_version(),
            "mapper_type": self.mapper_type,
            "schema": {field: mapper.to_dict() for field, mapper in self.schema.items()},
            "allow_unknown": self.allow_unknown,
            "allow_empty": self.allow_empty,
        }
        if self.missing_value is not _MISSING:
            data["missing_value"] = self.missing_value
        if self.name is not None:
            data["name"] = self.name
        return data

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "MapRangeMapper":
        """Create a map mapper from a JSON-compatible mapper spec."""
        from .sequence import _mapper_from_spec

        if not isinstance(data, dict):
            raise SerializationError("mapper spec must be a dictionary.")
        if data.get("spec_version") != SPEC_VERSION:
            raise SerializationError(f"unsupported spec_version {data.get('spec_version')!r}; expected {SPEC_VERSION!r}.")
        if data.get("mapper_type") != MAPPER_TYPE_MAP_RANGE:
            raise SerializationError(f"unsupported mapper_type {data.get('mapper_type')!r}; expected {MAPPER_TYPE_MAP_RANGE!r}.")

        if "schema" not in data:
            raise SerializationError("mapper spec is missing required field 'schema'.")

        schema = {}
        if not isinstance(data["schema"], Mapping):
            raise SerializationError("schema must be a mapping in mapper spec.")

        for field_name, mapper_spec in data["schema"].items():
            if not isinstance(field_name, str) or not field_name:
                raise SerializationError("schema field names must be non-empty strings.")
            schema[field_name] = _mapper_from_spec(mapper_spec)

        try:
            return cls(
                schema=schema,
                allow_unknown=data.get("allow_unknown", False),
                allow_empty=data.get("allow_empty", False),
                missing_value=data.get("missing_value", _MISSING),
                name=data.get("name"),
            )
        except KeyError as exc:
            raise SerializationError(f"mapper spec is missing required field {exc.args[0]!r}.") from exc

    def to_json(self) -> str:
        """Serialize this mapper spec as JSON."""
        return dumps_json(self.to_dict())

    @classmethod
    def from_json(cls, text: str) -> "MapRangeMapper":
        """Load a map mapper from JSON."""
        return cls.from_dict(loads_json(text))

    def save(self, path: str) -> None:
        """Save a mapper spec as JSON."""
        save_json_file(path, self.to_dict())

    @classmethod
    def load(cls, path: str) -> "MapRangeMapper":
        """Load a map mapper from JSON file."""
        return cls.from_dict(load_json_file(path))


def _object_fields(value: object) -> Iterable[str]:
    fields = []

    if not hasattr(value, "__slots__") and hasattr(value, "__dict__"):
        raw_fields = getattr(value, "__dict__")
        if isinstance(raw_fields, Mapping):
            fields.extend(raw_fields.keys())

    for cls in type(value).mro():
        slots = cls.__dict__.get("__slots__")
        if slots is None:
            continue

        if isinstance(slots, str):
            if slots not in {"__dict__", "__weakref__"}:
                fields.append(slots)
        else:
            for slot_name in slots:
                if isinstance(slot_name, str) and slot_name not in {"__dict__", "__weakref__"}:
                    fields.append(slot_name)

        for attr_name, descriptor in cls.__dict__.items():
            if isinstance(descriptor, property):
                fields.append(attr_name)

    return tuple(dict.fromkeys(fields))


def _has_field(value: object, field_name: str) -> bool:
    try:
        _get_field_value(value, field_name)
    except AttributeError:
        return False
    return True


def _get_field_value(value: object, field_name: str) -> Any:
    if hasattr(type(value), field_name):
        descriptor = getattr(type(value), field_name)
        if isinstance(descriptor, property):
            return descriptor.__get__(value, type(value))

    if hasattr(value, "__dict__"):
        raw_fields = getattr(value, "__dict__")
        if isinstance(raw_fields, Mapping) and field_name in raw_fields:
            return raw_fields[field_name]

    if hasattr(value, "__slots__"):
        slots = getattr(type(value), "__slots__", ())
        if isinstance(slots, str):
            slots = (slots,)
        for slot_name in slots:
            if slot_name == field_name and hasattr(value, slot_name):
                return getattr(value, slot_name)

    if hasattr(value, field_name):
        return getattr(value, field_name)

    raise AttributeError(field_name)


def _implementation_version() -> str:
    from . import __version__

    return __version__
