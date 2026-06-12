"""Byte mapping into normalized floats."""

from typing import Any, Dict, List, Optional, Sequence

from .core import require_finite_number
from .errors import SerializationError, UnsupportedTypeError
from .spec import DEFAULT_OUTPUT_RANGE, MAPPER_TYPE_BYTES_RANGE, SPEC_VERSION
from .serialization import dumps_json, load_json_file, loads_json, save_json_file


def _validate_output_range(output_range: object, field_name: str) -> tuple[float, float]:
    if not isinstance(output_range, (list, tuple)) or len(output_range) != 2:
        raise UnsupportedTypeError(f"{field_name} must be a two-item range like (-1.0, 1.0).")

    low = output_range[0]
    high = output_range[1]
    if not isinstance(low, (int, float)) or isinstance(low, bool):
        raise UnsupportedTypeError(f"{field_name}[0] must be a finite number.")
    if not isinstance(high, (int, float)) or isinstance(high, bool):
        raise UnsupportedTypeError(f"{field_name}[1] must be a finite number.")

    low_f = float(low)
    high_f = float(high)

    require_finite_number(low_f, f"{field_name}[0]")
    require_finite_number(high_f, f"{field_name}[1]")

    if not (low_f < high_f):
        raise UnsupportedTypeError(f"{field_name} must be ordered from lower value to higher value.")

    return low_f, high_f


def _validate_bytes(value: object) -> bytes:
    if not isinstance(value, (bytes, bytearray, memoryview)):
        raise UnsupportedTypeError("value must be bytes-like (bytes, bytearray, or memoryview).")
    return bytes(value)


class BytesRangeMapper:
    """Map byte containers into normalized floats."""

    mapper_type = MAPPER_TYPE_BYTES_RANGE
    spec_version = SPEC_VERSION

    def __init__(
        self,
        output_range: Sequence[float] = DEFAULT_OUTPUT_RANGE,
        allow_empty: bool = False,
        name: Optional[str] = None,
    ) -> None:
        if not isinstance(allow_empty, bool):
            raise UnsupportedTypeError("allow_empty must be a bool.")
        if name is not None and not isinstance(name, str):
            raise UnsupportedTypeError("name must be a string when provided.")
        if name is not None and name == "":
            raise UnsupportedTypeError("name must not be empty.")

        self.output_range = _validate_output_range(output_range, "output_range")
        self.allow_empty = allow_empty
        self.name = name

    def map_value(self, value: bytes | bytearray | memoryview) -> List[float]:
        """Map each byte to a normalized float."""
        payload = _validate_bytes(value)
        if not payload and not self.allow_empty:
            raise UnsupportedTypeError("empty bytes payload is invalid by default; set allow_empty=True to map empty payloads.")

        if not payload:
            return []

        out_min, out_max = self.output_range
        return [float((float(unit) / 255.0) * (out_max - out_min) + out_min) for unit in payload]

    def transform(self, value: bytes | bytearray | memoryview) -> List[float]:
        """Alias for map_value."""
        return self.map_value(value)

    def map(self, value: bytes | bytearray | memoryview) -> List[float]:
        """Compatibility alias."""
        return self.map_value(value)

    def to_dict(self) -> Dict[str, Any]:
        """Return a JSON-compatible mapper spec."""
        data = {
            "spec_version": self.spec_version,
            "implementation_version": _implementation_version(),
            "mapper_type": self.mapper_type,
            "output_range": [self.output_range[0], self.output_range[1]],
            "allow_empty": self.allow_empty,
        }
        if self.name is not None:
            data["name"] = self.name
        return data

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "BytesRangeMapper":
        """Create a byte mapper from a JSON-compatible mapper spec."""
        if not isinstance(data, dict):
            raise SerializationError("mapper spec must be a dictionary.")
        if data.get("spec_version") != SPEC_VERSION:
            raise SerializationError(f"unsupported spec_version {data.get('spec_version')!r}; expected {SPEC_VERSION!r}.")
        if data.get("mapper_type") != MAPPER_TYPE_BYTES_RANGE:
            raise SerializationError(
                f"unsupported mapper_type {data.get('mapper_type')!r}; expected {MAPPER_TYPE_BYTES_RANGE!r}."
            )
        try:
            return cls(
                output_range=data.get("output_range", DEFAULT_OUTPUT_RANGE),
                allow_empty=data.get("allow_empty", False),
                name=data.get("name"),
            )
        except KeyError as exc:
            raise SerializationError(f"mapper spec is missing required field {exc.args[0]!r}.") from exc

    def to_json(self) -> str:
        """Serialize this mapper spec as JSON."""
        return dumps_json(self.to_dict())

    @classmethod
    def from_json(cls, text: str) -> "BytesRangeMapper":
        """Load a mapper from JSON."""
        return cls.from_dict(loads_json(text))

    def save(self, path: str) -> None:
        """Save a mapper spec to disk."""
        save_json_file(path, self.to_dict())

    @classmethod
    def load(cls, path: str) -> "BytesRangeMapper":
        """Load a mapper spec from disk."""
        return cls.from_dict(load_json_file(path))


def _implementation_version() -> str:
    from . import __version__

    return __version__
