"""Text and character mapping into normalized floats."""

from __future__ import annotations

from typing import Any, Dict, List, Optional, Sequence

from .core import map_linear, require_finite_number
from .errors import SerializationError, UnsupportedTypeError
from .spec import DEFAULT_OUTPUT_RANGE, MAPPER_TYPE_TEXT_RANGE, SPEC_VERSION
from .serialization import dumps_json, load_json_file, loads_json, save_json_file

MIN_CODEPOINT = 0.0
MAX_CODEPOINT = 0x10FFFF
MIN_BYTE = 0.0
MAX_BYTE = 255.0


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


def _validate_alphabet(value: object, field_name: str) -> str:
    if not isinstance(value, str) or not value:
        raise UnsupportedTypeError(f"{field_name} must be a non-empty string alphabet.")
    if len(value) < 2:
        raise UnsupportedTypeError(f"{field_name} must contain at least two unique characters.")
    return value


def _normalize_codepoint(ch: str) -> int:
    return ord(ch)


class TextRangeMapper:
    """Map string/character values into normalized floats."""

    mapper_type = MAPPER_TYPE_TEXT_RANGE
    spec_version = SPEC_VERSION

    def __init__(
        self,
        output_range: Sequence[float] = DEFAULT_OUTPUT_RANGE,
        mode: str = "codepoint",
        alphabet: Optional[str] = None,
        clip: bool = False,
        allow_empty: bool = False,
        name: Optional[str] = None,
    ) -> None:
        if mode not in {"codepoint", "alphabet", "byte"}:
            raise UnsupportedTypeError("mode must be one of 'codepoint', 'alphabet', or 'byte'.")
        if not isinstance(clip, bool):
            raise UnsupportedTypeError("clip must be a bool.")
        if not isinstance(allow_empty, bool):
            raise UnsupportedTypeError("allow_empty must be a bool.")
        if name is not None and not isinstance(name, str):
            raise UnsupportedTypeError("name must be a string when provided.")

        if name is not None and name == "":
            raise UnsupportedTypeError("name must not be empty.")

        self.output_range = _validate_output_range(output_range, "output_range")

        if mode == "codepoint":
            self.input_range = (MIN_CODEPOINT, MAX_CODEPOINT)
            self.alphabet = None
        elif mode == "byte":
            self.input_range = (MIN_BYTE, MAX_BYTE)
            self.alphabet = None
        else:
            if alphabet is None:
                raise UnsupportedTypeError("alphabet is required when mode='alphabet'.")
            self.alphabet = _validate_alphabet(alphabet, "alphabet")
            self.input_range = (0.0, float(len(self.alphabet) - 1))

        if mode == "alphabet" and self.alphabet is None:
            raise UnsupportedTypeError("internal state error: alphabet mode requires alphabet.")
        if mode == "alphabet":
            self.alphabet_to_index = {char: idx for idx, char in enumerate(self.alphabet)}
            if len(self.alphabet_to_index) != len(self.alphabet):
                raise UnsupportedTypeError("alphabet must contain unique characters.")

        self.mode = mode
        self.clip = clip
        self.allow_empty = allow_empty
        self.name = name

    def map_value(self, value: str) -> List[float]:
        """Map each character/byte in a string into normalized float values."""
        if not isinstance(value, str):
            raise UnsupportedTypeError("value must be a string.")
        if not value and not self.allow_empty:
            raise UnsupportedTypeError("empty string is invalid by default; set allow_empty=True to map empty strings.")

        if self.mode == "byte":
            values = list(value.encode("utf-8"))
        else:
            values = list(value)

        in_min, in_max = self.input_range
        out = []
        for unit in values:
            if self.mode == "byte":
                unit_value = float(unit)
            elif self.mode == "codepoint":
                unit_value = float(_normalize_codepoint(unit))
            else:
                if unit not in self.alphabet_to_index:
                    raise UnsupportedTypeError(f"unknown character {unit!r} for alphabet mode.")
                unit_value = float(self.alphabet_to_index[unit])

            if unit_value < in_min and not self.clip:
                raise UnsupportedTypeError(
                    f"value {unit_value} is below input_range lower bound {in_min}; enable clip to clamp."
                )
            if unit_value > in_max and not self.clip:
                raise UnsupportedTypeError(
                    f"value {unit_value} is above input_range upper bound {in_max}; enable clip to clamp."
                )
            if unit_value < in_min:
                unit_value = in_min
            elif unit_value > in_max:
                unit_value = in_max
            out.append(float(map_linear(unit_value, self.input_range, self.output_range)))
        return out

    def transform(self, value: str) -> List[float]:
        """Alias for map_value."""
        return self.map_value(value)

    def map(self, value: str) -> List[float]:
        """Compatibility alias."""
        return self.map_value(value)

    def to_dict(self) -> Dict[str, Any]:
        """Return a JSON-compatible mapper spec."""
        data = {
            "spec_version": self.spec_version,
            "implementation_version": _implementation_version(),
            "mapper_type": self.mapper_type,
            "output_range": [self.output_range[0], self.output_range[1]],
            "mode": self.mode,
            "clip": self.clip,
            "allow_empty": self.allow_empty,
        }
        if self.alphabet is not None:
            data["alphabet"] = self.alphabet
        if self.name is not None:
            data["name"] = self.name
        return data

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "TextRangeMapper":
        """Load a text mapper from a JSON-compatible mapper spec."""
        if not isinstance(data, dict):
            raise SerializationError("mapper spec must be a dictionary.")
        if data.get("spec_version") != SPEC_VERSION:
            raise SerializationError(f"unsupported spec_version {data.get('spec_version')!r}; expected {SPEC_VERSION!r}.")
        if data.get("mapper_type") != MAPPER_TYPE_TEXT_RANGE:
            raise SerializationError(
                f"unsupported mapper_type {data.get('mapper_type')!r}; expected {MAPPER_TYPE_TEXT_RANGE!r}."
            )
        try:
            return cls(
                output_range=data.get("output_range", DEFAULT_OUTPUT_RANGE),
                mode=data.get("mode", "codepoint"),
                alphabet=data.get("alphabet"),
                clip=data.get("clip", False),
                allow_empty=data.get("allow_empty", False),
                name=data.get("name"),
            )
        except KeyError as exc:
            raise SerializationError(f"mapper spec is missing required field {exc.args[0]!r}.") from exc

    def to_json(self) -> str:
        """Serialize this mapper spec as JSON."""
        return dumps_json(self.to_dict())

    @classmethod
    def from_json(cls, text: str) -> "TextRangeMapper":
        """Load a mapper from JSON."""
        return cls.from_dict(loads_json(text))

    def save(self, path: str) -> None:
        """Save this mapper spec to disk."""
        save_json_file(path, self.to_dict())

    @classmethod
    def load(cls, path: str) -> "TextRangeMapper":
        """Load a mapper spec from disk."""
        return cls.from_dict(load_json_file(path))


def _implementation_version() -> str:
    from . import __version__

    return __version__
