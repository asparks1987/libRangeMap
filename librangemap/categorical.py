"""Categorical/vocabulary mapping into normalized floats."""

from typing import Any, Dict, Optional, Sequence

from .core import map_linear, require_finite_number
from .errors import SerializationError, UnsupportedTypeError
from .spec import DEFAULT_OUTPUT_RANGE, MAPPER_TYPE_CATEGORICAL_RANGE, SPEC_VERSION
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
    if low_f >= high_f:
        raise UnsupportedTypeError(f"{field_name} must be ordered from lower value to higher value.")
    return low_f, high_f


def _validate_vocabulary(vocabulary: object) -> tuple[Any, ...]:
    if not isinstance(vocabulary, Sequence) or isinstance(vocabulary, (str, bytes, bytearray, memoryview)):
        raise UnsupportedTypeError(
            "vocabulary must be a non-empty sequence of JSON-serializable scalar tokens."
        )
    if len(vocabulary) == 0:
        raise UnsupportedTypeError("vocabulary must be non-empty.")

    normalized = []
    seen = set()
    for token in vocabulary:
        key = _token_key(token)
        if key in seen:
            raise UnsupportedTypeError("vocabulary tokens must be unique.")
        seen.add(key)
        normalized.append(token)

    return tuple(normalized)


class CategoricalRangeMapper:
    """Map categorical tokens or symbolic values through a configured vocabulary."""

    mapper_type = MAPPER_TYPE_CATEGORICAL_RANGE
    spec_version = SPEC_VERSION

    def __init__(
        self,
        vocabulary: Sequence[Any],
        output_range: Sequence[float] = DEFAULT_OUTPUT_RANGE,
        name: Optional[str] = None,
    ) -> None:
        if name is not None and not isinstance(name, str):
            raise UnsupportedTypeError("name must be a string when provided.")
        if name is not None and name == "":
            raise UnsupportedTypeError("name must not be empty.")

        self.output_range = _validate_output_range(output_range, "output_range")
        self.vocabulary = _validate_vocabulary(vocabulary)
        self.token_to_index = {_token_key(token): idx for idx, token in enumerate(self.vocabulary)}
        self.name = name

    def map_value(self, value: object) -> float:
        """Map one categorical token to a float."""
        key = _token_key(value)
        if key not in self.token_to_index:
            raise UnsupportedTypeError(f"unknown token {value!r}; configure vocabulary or explicit unknown-token policy.")

        index = self.token_to_index[key]
        if len(self.vocabulary) == 1:
            return float(self.output_range[0])

        index_range = (0.0, float(len(self.vocabulary) - 1))
        return float(map_linear(float(index), index_range, self.output_range))

    def transform(self, value: object) -> float:
        """Alias for map_value."""
        return self.map_value(value)

    def map(self, value: object) -> float:
        """Compatibility alias."""
        return self.map_value(value)

    def to_dict(self) -> Dict[str, Any]:
        """Return a JSON-compatible mapper spec."""
        data = {
            "spec_version": self.spec_version,
            "implementation_version": _implementation_version(),
            "mapper_type": self.mapper_type,
            "vocabulary": list(self.vocabulary),
            "output_range": [self.output_range[0], self.output_range[1]],
        }
        if self.name is not None:
            data["name"] = self.name
        return data

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "CategoricalRangeMapper":
        """Create a categorical mapper from a JSON-compatible mapper spec."""
        if not isinstance(data, dict):
            raise SerializationError("mapper spec must be a dictionary.")
        if data.get("spec_version") != SPEC_VERSION:
            raise SerializationError(f"unsupported spec_version {data.get('spec_version')!r}; expected {SPEC_VERSION!r}.")
        if data.get("mapper_type") != MAPPER_TYPE_CATEGORICAL_RANGE:
            raise SerializationError(
                f"unsupported mapper_type {data.get('mapper_type')!r}; expected {MAPPER_TYPE_CATEGORICAL_RANGE!r}."
            )

        if "vocabulary" not in data:
            raise SerializationError("mapper spec is missing required field 'vocabulary'.")

        try:
            return cls(
                vocabulary=data["vocabulary"],
                output_range=data.get("output_range", DEFAULT_OUTPUT_RANGE),
                name=data.get("name"),
            )
        except KeyError as exc:
            raise SerializationError(f"mapper spec is missing required field {exc.args[0]!r}.") from exc

    def to_json(self) -> str:
        """Serialize this mapper spec as JSON."""
        return dumps_json(self.to_dict())

    @classmethod
    def from_json(cls, text: str) -> "CategoricalRangeMapper":
        """Load a mapper from JSON."""
        return cls.from_dict(loads_json(text))

    def save(self, path: str) -> None:
        """Save a mapper spec as JSON."""
        save_json_file(path, self.to_dict())

    @classmethod
    def load(cls, path: str) -> "CategoricalRangeMapper":
        """Load a mapper spec from JSON file."""
        return cls.from_dict(load_json_file(path))


def _implementation_version() -> str:
    from . import __version__

    return __version__


def _token_key(token: object) -> tuple[str, object]:
    if token is None:
        return ("null", None)
    if isinstance(token, bool):
        return ("bool", token)
    if isinstance(token, str):
        return ("str", token)
    if isinstance(token, int):
        return ("int", token)
    if isinstance(token, float):
        require_finite_number(token, "vocabulary token")
        return ("float", token)
    raise UnsupportedTypeError(
        "vocabulary tokens must be JSON-serializable scalar values (string, number, boolean, or null)."
    )
