"""Integer range mapper for the libRangeMap alpha reference implementation."""

from .core import map_linear, require_integer, validate_integer_range, validate_output_range
from .errors import OutOfRangeError, SerializationError, UnsupportedTypeError
from .spec import DEFAULT_OUTPUT_RANGE, MAPPER_TYPE_INTEGER_RANGE, SPEC_VERSION
from .serialization import dumps_json, load_json_file, loads_json, save_json_file


class IntegerRangeMapper:
    """Map finite integers from a declared input range into an output range."""

    mapper_type = MAPPER_TYPE_INTEGER_RANGE
    spec_version = SPEC_VERSION

    def __init__(self, input_range, output_range=DEFAULT_OUTPUT_RANGE, clip=False, name=None):
        if not isinstance(clip, bool):
            raise UnsupportedTypeError("clip must be a bool: True for clipping mode or False for strict mode.")
        if name is not None and not isinstance(name, str):
            raise UnsupportedTypeError("name must be a string when provided.")

        self.input_range = validate_integer_range(input_range, "input_range")
        self.output_range = validate_output_range(output_range, "output_range")
        self.clip = clip
        self.name = name

    def map_value(self, value):
        """Map one integer value to a float."""
        require_integer(value, "value")

        in_min, in_max = self.input_range
        if value < in_min:
            if not self.clip:
                raise OutOfRangeError(f"value {value} is below input_range lower bound {in_min}; enable clip to clamp.")
            value = in_min
        elif value > in_max:
            if not self.clip:
                raise OutOfRangeError(f"value {value} is above input_range upper bound {in_max}; enable clip to clamp.")
            value = in_max

        return float(map_linear(value, self.input_range, self.output_range))

    def transform(self, value):
        """Alias for map_value, reserved for future mapper consistency."""
        return self.map_value(value)

    def map(self, value):
        """Compatibility alias for older libRangeMap-style callers."""
        return self.map_value(value)

    def to_dict(self):
        """Return a JSON-compatible mapper spec."""
        data = {
            "spec_version": self.spec_version,
            "implementation_version": _implementation_version(),
            "mapper_type": self.mapper_type,
            "input_range": list(self.input_range),
            "output_range": list(self.output_range),
            "clip": self.clip,
        }
        if self.name is not None:
            data["name"] = self.name
        return data

    @classmethod
    def from_dict(cls, data):
        """Create a mapper from a JSON-compatible mapper spec."""
        if not isinstance(data, dict):
            raise SerializationError("mapper spec must be a dictionary.")
        if data.get("spec_version") != SPEC_VERSION:
            raise SerializationError(f"unsupported spec_version {data.get('spec_version')!r}; expected {SPEC_VERSION!r}.")
        if data.get("mapper_type") != MAPPER_TYPE_INTEGER_RANGE:
            raise SerializationError(
                f"unsupported mapper_type {data.get('mapper_type')!r}; expected {MAPPER_TYPE_INTEGER_RANGE!r}."
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

    def to_json(self):
        """Serialize this mapper spec to a stable JSON string."""
        return dumps_json(self.to_dict())

    @classmethod
    def from_json(cls, text):
        """Load a mapper from a JSON string."""
        return cls.from_dict(loads_json(text))

    def save(self, path):
        """Save this mapper spec as JSON."""
        save_json_file(path, self.to_dict())

    @classmethod
    def load(cls, path):
        """Load a mapper spec from a JSON file."""
        return cls.from_dict(load_json_file(path))


def _implementation_version():
    from . import __version__

    return __version__
