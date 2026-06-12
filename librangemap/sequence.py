"""Sequence mapper for nested, deterministic shape-preserving mapping."""

from __future__ import annotations

from typing import Any, Dict, List, Optional, Sequence, Tuple, Union

from .errors import SerializationError, UnsupportedTypeError
from .spec import MAPPER_TYPE_SEQUENCE_RANGE, SPEC_VERSION
from .serialization import dumps_json, load_json_file, loads_json, save_json_file


def _mapper_from_spec(spec: Dict[str, Any]):
    from .boolean import BooleanRangeMapper
    from .float import FloatRangeMapper
    from .integer import IntegerRangeMapper
    from .text import TextRangeMapper

    if not isinstance(spec, dict):
        raise SerializationError("mapper spec must be a dictionary.")

    mapper_type = spec.get("mapper_type")
    if mapper_type == IntegerRangeMapper.mapper_type:
        return IntegerRangeMapper.from_dict(spec)
    if mapper_type == FloatRangeMapper.mapper_type:
        return FloatRangeMapper.from_dict(spec)
    if mapper_type == BooleanRangeMapper.mapper_type:
        return BooleanRangeMapper.from_dict(spec)
    if mapper_type == TextRangeMapper.mapper_type:
        return TextRangeMapper.from_dict(spec)
    if mapper_type == MAPPER_TYPE_SEQUENCE_RANGE:
        return SequenceRangeMapper.from_dict(spec)

    raise SerializationError(f"unsupported element mapper_type {mapper_type!r}.")


class SequenceRangeMapper:
    """Map nested list/tuple containers recursively using an element mapper."""

    mapper_type = MAPPER_TYPE_SEQUENCE_RANGE
    spec_version = SPEC_VERSION

    def __init__(
        self,
        element_mapper: Any,
        *,
        allow_empty: bool = False,
        preserve_tuples: bool = True,
        name: Optional[str] = None,
    ) -> None:
        if not hasattr(element_mapper, "map_value") or not callable(element_mapper.map_value):
            raise UnsupportedTypeError("element_mapper must provide a map_value method.")
        if not isinstance(allow_empty, bool):
            raise UnsupportedTypeError("allow_empty must be a bool.")
        if not isinstance(preserve_tuples, bool):
            raise UnsupportedTypeError("preserve_tuples must be a bool.")
        if name is not None and not isinstance(name, str):
            raise UnsupportedTypeError("name must be a string when provided.")

        self.element_mapper = element_mapper
        self.allow_empty = allow_empty
        self.preserve_tuples = preserve_tuples
        self.name = name

    def map_value(self, value: Union[Sequence[Any], Any]) -> Union[List[Any], Tuple[Any, ...], Any]:
        """Map values recursively while preserving outer sequence shape."""
        if isinstance(value, (list, tuple)):
            if not value and not self.allow_empty:
                raise UnsupportedTypeError(
                    "empty sequence is invalid by default; set allow_empty=True to map empty containers."
                )
            mapper = list
            if self.preserve_tuples and isinstance(value, tuple):
                mapper = tuple
            return mapper(self.map_value(item) for item in value)

        return self.element_mapper.map_value(value)

    def transform(self, value: Union[Sequence[Any], Any]) -> Union[List[Any], Tuple[Any, ...], Any]:
        """Alias for map_value, reserved for future mapper consistency."""
        return self.map_value(value)

    def map(self, value: Union[Sequence[Any], Any]) -> Union[List[Any], Tuple[Any, ...], Any]:
        """Compatibility alias for older call styles."""
        return self.map_value(value)

    def to_dict(self) -> Dict[str, Any]:
        """Return a JSON-compatible mapper spec."""
        data = {
            "spec_version": self.spec_version,
            "mapper_type": self.mapper_type,
            "element_mapper": self.element_mapper.to_dict(),
            "allow_empty": self.allow_empty,
            "preserve_tuples": self.preserve_tuples,
        }
        if self.name is not None:
            data["name"] = self.name
        return data

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "SequenceRangeMapper":
        """Create a sequence mapper from a JSON-compatible mapper spec."""
        if not isinstance(data, dict):
            raise SerializationError("mapper spec must be a dictionary.")
        if data.get("spec_version") != SPEC_VERSION:
            raise SerializationError(f"unsupported spec_version {data.get('spec_version')!r}; expected {SPEC_VERSION!r}.")
        if data.get("mapper_type") != MAPPER_TYPE_SEQUENCE_RANGE:
            raise SerializationError(
                f"unsupported mapper_type {data.get('mapper_type')!r}; expected {MAPPER_TYPE_SEQUENCE_RANGE!r}."
            )

        if "element_mapper" not in data:
            raise SerializationError("mapper spec is missing required field 'element_mapper'.")

        element_mapper = _mapper_from_spec(data["element_mapper"])
        try:
            return cls(
                element_mapper=element_mapper,
                allow_empty=data.get("allow_empty", False),
                preserve_tuples=data.get("preserve_tuples", True),
                name=data.get("name"),
            )
        except KeyError as exc:
            raise SerializationError(f"mapper spec is missing required field {exc.args[0]!r}.") from exc

    def to_json(self) -> str:
        """Serialize this mapper spec to a stable JSON string."""
        return dumps_json(self.to_dict())

    @classmethod
    def from_json(cls, text: str) -> "SequenceRangeMapper":
        """Load a mapper from a JSON string."""
        return cls.from_dict(loads_json(text))

    def save(self, path: str) -> None:
        """Save this mapper spec as JSON."""
        save_json_file(path, self.to_dict())

    @classmethod
    def load(cls, path: str) -> "SequenceRangeMapper":
        """Load a mapper spec from a JSON file."""
        return cls.from_dict(load_json_file(path))
