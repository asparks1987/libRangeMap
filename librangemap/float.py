"""Floating-point range mapper for dependency-free normalization."""

from typing import Any, Dict, Optional, Sequence

from .core import map_linear, require_finite_number, validate_output_range
from .errors import OutOfRangeError, SerializationError, UnsupportedTypeError
from .spec import DEFAULT_OUTPUT_RANGE, MAPPER_TYPE_FLOAT_RANGE, SPEC_VERSION
from .serialization import dumps_json, load_json_file, loads_json, save_json_file


def validate_float_input_range(range_value: object, field_name: str) -> tuple[float, float]:
    """Validate an ordered two-item finite-number input range."""
    if not isinstance(range_value, (list, tuple)) or len(range_value) != 2:
        raise UnsupportedTypeError(f"{field_name} must be a two-item range like (0.0, 1.0).")

    low = range_value[0]
    high = range_value[1]
    require_finite_number(low, f"{field_name}[0]")
    require_finite_number(high, f"{field_name}[1]")

    low = float(low)
    high = float(high)

    if high == low:
        raise OutOfRangeError(f"{field_name} min and max must be different.")
    if high < low:
        raise OutOfRangeError(f"{field_name} must be ordered from lower value to higher value.")

    return low, high


class FloatRangeMapper:
    """Map finite numbers from a declared input range into an output range."""

    mapper_type = MAPPER_TYPE_FLOAT_RANGE
    spec_version = SPEC_VERSION

    def __init__(
        self,
        input_range: Sequence[float],
        output_range: Sequence[float] = DEFAULT_OUTPUT_RANGE,
        clip: bool = False,
        name: Optional[str] = None,
    ) -> None:
        if not isinstance(clip, bool):
            raise UnsupportedTypeError("clip must be a bool: True for clipping mode or False for strict mode.")
        if name is not None and not isinstance(name, str):
            raise UnsupportedTypeError("name must be a string when provided.")

        self.input_range = validate_float_input_range(input_range, "input_range")
        self.output_range = validate_output_range(output_range, "output_range")
        self.clip = clip
        self.name = name

    def map_value(self, value: float) -> float:
        """Map one floating-point value to a float."""
        require_finite_number(value, "value")

        value_f = float(value)
        in_min, in_max = self.input_range
        if value_f < in_min:
            if not self.clip:
                raise OutOfRangeError(
                    f"value {value_f} is below input_range lower bound {in_min}; enable clip to clamp."
                )
            value_f = in_min
        elif value_f > in_max:
            if not self.clip:
                raise OutOfRangeError(
                    f"value {value_f} is above input_range upper bound {in_max}; enable clip to clamp."
                )
            value_f = in_max

        return float(map_linear(value_f, self.input_range, self.output_range))

    def transform(self, value: float) -> float:
        """Alias for map_value, reserved for future mapper consistency."""
        return self.map_value(value)

    def map(self, value: float) -> float:
        """Compatibility alias for older libRangeMap-style callers."""
        return self.map_value(value)

    def to_dict(self) -> Dict[str, Any]:
        """Return a JSON-compatible mapper spec."""
        data = {
            "spec_version": self.spec_version,
            "implementation_version": _implementation_version(),
            "mapper_type": self.mapper_type,
            "input_range": [float(self.input_range[0]), float(self.input_range[1])],
            "output_range": [self.output_range[0], self.output_range[1]],
            "clip": self.clip,
        }
        if self.name is not None:
            data["name"] = self.name
        return data

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "FloatRangeMapper":
        """Create a mapper from a JSON-compatible mapper spec."""
        if not isinstance(data, dict):
            raise SerializationError("mapper spec must be a dictionary.")
        if data.get("spec_version") != SPEC_VERSION:
            raise SerializationError(f"unsupported spec_version {data.get('spec_version')!r}; expected {SPEC_VERSION!r}.")
        if data.get("mapper_type") != MAPPER_TYPE_FLOAT_RANGE:
            raise SerializationError(
                f"unsupported mapper_type {data.get('mapper_type')!r}; expected {MAPPER_TYPE_FLOAT_RANGE!r}."
            )
        try:
            return cls(
                input_range=data["input_range"],
                output_range=data.get("output_range", DEFAULT_OUTPUT_RANGE),
                clip=data.get("clip", False),
                name=data.get("name"),
            )
        except KeyError as exc:
            raise SerializationError(f"mapper spec is missing required field {exc.args[0]!r}.") from exc

    def to_json(self) -> str:
        """Serialize this mapper spec to a stable JSON string."""
        return dumps_json(self.to_dict())

    @classmethod
    def from_json(cls, text: str) -> "FloatRangeMapper":
        """Load a mapper from a JSON string."""
        return cls.from_dict(loads_json(text))

    def save(self, path: str) -> None:
        """Save this mapper spec as JSON."""
        save_json_file(path, self.to_dict())

    @classmethod
    def load(cls, path: str) -> "FloatRangeMapper":
        """Load a mapper spec from a JSON file."""
        return cls.from_dict(load_json_file(path))


def _implementation_version() -> str:
    from . import __version__

    return __version__
