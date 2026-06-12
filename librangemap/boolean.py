"""Boolean range mapper with explicit binary policy."""

from typing import Any, Dict, Optional, Sequence

from .errors import UnsupportedTypeError, SerializationError
from .spec import DEFAULT_OUTPUT_RANGE, MAPPER_TYPE_BOOLEAN_RANGE, SPEC_VERSION
from .serialization import dumps_json, load_json_file, loads_json, save_json_file


def validate_output_range(output_range: object, field_name: str) -> tuple[float, float]:
    """Validate an ordered two-item finite-number output range."""
    if not isinstance(output_range, (list, tuple)) or len(output_range) != 2:
        raise UnsupportedTypeError(f"{field_name} must be a two-item range like (-1.0, 1.0).")

    low, high = output_range
    if not isinstance(low, (int, float)) or isinstance(low, bool):
        raise UnsupportedTypeError(f"{field_name}[0] must be a finite number.")
    if not isinstance(high, (int, float)) or isinstance(high, bool):
        raise UnsupportedTypeError(f"{field_name}[1] must be a finite number.")

    low_f = float(low)
    high_f = float(high)

    if not (low_f < high_f):
        raise UnsupportedTypeError(f"{field_name} must be ordered from lower value to higher value.")

    return low_f, high_f


class BooleanRangeMapper:
    """Map booleans into an explicit false/true output policy."""

    mapper_type = MAPPER_TYPE_BOOLEAN_RANGE
    spec_version = SPEC_VERSION

    def __init__(
        self,
        output_range: Sequence[float] = DEFAULT_OUTPUT_RANGE,
        false_value: Optional[float] = None,
        true_value: Optional[float] = None,
        name: Optional[str] = None,
    ) -> None:
        if name is not None and not isinstance(name, str):
            raise UnsupportedTypeError("name must be a string when provided.")

        self.output_range = validate_output_range(output_range, "output_range")
        self.false_value = float(false_value if false_value is not None else self.output_range[0])
        self.true_value = float(true_value if true_value is not None else self.output_range[1])
        self.name = name

    def map_value(self, value: bool) -> float:
        """Map one boolean value to a float."""
        if not isinstance(value, bool):
            raise UnsupportedTypeError("value must be a boolean.")
        return self.true_value if value else self.false_value

    def transform(self, value: bool) -> float:
        """Alias for map_value, reserved for future mapper consistency."""
        return self.map_value(value)

    def map(self, value: bool) -> float:
        """Compatibility alias for older libRangeMap-style callers."""
        return self.map_value(value)

    def to_dict(self) -> Dict[str, Any]:
        """Return a JSON-compatible mapper spec."""
        data = {
            "spec_version": self.spec_version,
            "mapper_type": self.mapper_type,
            "output_range": [self.output_range[0], self.output_range[1]],
            "false_value": self.false_value,
            "true_value": self.true_value,
        }
        if self.name is not None:
            data["name"] = self.name
        return data

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "BooleanRangeMapper":
        """Create a mapper from a JSON-compatible mapper spec."""
        if not isinstance(data, dict):
            raise SerializationError("mapper spec must be a dictionary.")
        if data.get("spec_version") != SPEC_VERSION:
            raise SerializationError(f"unsupported spec_version {data.get('spec_version')!r}; expected {SPEC_VERSION!r}.")
        if data.get("mapper_type") != MAPPER_TYPE_BOOLEAN_RANGE:
            raise SerializationError(
                f"unsupported mapper_type {data.get('mapper_type')!r}; expected {MAPPER_TYPE_BOOLEAN_RANGE!r}."
            )
        try:
            return cls(
                output_range=data.get("output_range", DEFAULT_OUTPUT_RANGE),
                false_value=data.get("false_value"),
                true_value=data.get("true_value"),
                name=data.get("name"),
            )
        except KeyError as exc:
            raise SerializationError(f"mapper spec is missing required field {exc.args[0]!r}.") from exc

    def to_json(self) -> str:
        """Serialize this mapper spec to a stable JSON string."""
        return dumps_json(self.to_dict())

    @classmethod
    def from_json(cls, text: str) -> "BooleanRangeMapper":
        """Load a mapper from a JSON string."""
        return cls.from_dict(loads_json(text))

    def save(self, path: str) -> None:
        """Save this mapper spec as JSON."""
        save_json_file(path, self.to_dict())

    @classmethod
    def load(cls, path: str) -> "BooleanRangeMapper":
        """Load a mapper spec from a JSON file."""
        return cls.from_dict(load_json_file(path))
