"""Image-like data mapping into normalized floats."""

from __future__ import annotations

from typing import Any, Dict, List, Optional, Sequence, Tuple, Union

from .core import map_linear, require_finite_number
from .errors import OutOfRangeError, SerializationError, UnsupportedTypeError
from .spec import DEFAULT_OUTPUT_RANGE, MAPPER_TYPE_IMAGE_RANGE, SPEC_VERSION
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


def _validate_input_range(value_range: object, field_name: str) -> tuple[float, float]:
    if not isinstance(value_range, (list, tuple)) or len(value_range) != 2:
        raise UnsupportedTypeError(f"{field_name} must be a two-item range like (0.0, 255.0).")

    low = value_range[0]
    high = value_range[1]
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


def _validate_mode(mode: object, field_name: str) -> None:
    if not isinstance(mode, str):
        raise UnsupportedTypeError(f"{field_name} must be a string.")
    if mode not in {"grayscale", "rgb", "rgba", "raw_bytes"}:
        raise UnsupportedTypeError(f"{field_name} must be one of: 'grayscale', 'rgb', 'rgba', 'raw_bytes'.")


def _is_scalar_pixel_unit(value: object) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _coerce_channel_value(
    value: object,
    input_range: tuple[float, float],
    output_range: tuple[float, float],
    clip: bool,
) -> float:
    if not _is_scalar_pixel_unit(value):
        raise UnsupportedTypeError("image channel values must be non-bool int or float numbers.")
    value_f = float(value)
    require_finite_number(value_f, "channel value")

    in_min, in_max = input_range
    if value_f < in_min:
        if not clip:
            raise OutOfRangeError(
                f"channel value {value_f} is below input_range lower bound {in_min}; enable clip to clamp."
            )
        value_f = in_min
    elif value_f > in_max:
        if not clip:
            raise OutOfRangeError(
                f"channel value {value_f} is above input_range upper bound {in_max}; enable clip to clamp."
            )
        value_f = in_max

    return float(map_linear(value_f, input_range, output_range))


def _map_nested_values(
    value: object,
    map_pixel,
    allow_empty: bool,
    preserve_tuples: bool,
) -> Union[List[Any], Tuple[Any, ...], Any]:
    if isinstance(value, (list, tuple)):
        if not value:
            if not allow_empty:
                raise UnsupportedTypeError("empty input is invalid by default; set allow_empty=True to map empty containers.")
            return () if (preserve_tuples and isinstance(value, tuple)) else []

        mapper = tuple if preserve_tuples and isinstance(value, tuple) else list
        return mapper(_map_nested_values(item, map_pixel=map_pixel, allow_empty=allow_empty, preserve_tuples=preserve_tuples) for item in value)

    return map_pixel(value)


def _map_grayscale(
    value: object,
    *,
    input_range: tuple[float, float],
    output_range: tuple[float, float],
    clip: bool,
    allow_empty: bool,
    preserve_tuples: bool,
) -> Union[float, List[Any], Tuple[Any, ...]]:
    return _map_nested_values(
        value,
        map_pixel=lambda unit: _coerce_channel_value(
            unit,
            input_range=input_range,
            output_range=output_range,
            clip=clip,
        ),
        allow_empty=allow_empty,
        preserve_tuples=preserve_tuples,
    )


def _map_pixel(
    value: object,
    *,
    channels: int,
    mode: str,
    input_range: tuple[float, float],
    output_range: tuple[float, float],
    clip: bool,
    allow_empty: bool,
    preserve_tuples: bool,
) -> Union[List[Any], Tuple[Any, ...]]:
    if isinstance(value, (list, tuple)):
        if not value:
            if not allow_empty:
                raise UnsupportedTypeError(
                    f"empty input is invalid by default for {mode}; set allow_empty=True to map empty containers."
                )
            return () if (preserve_tuples and isinstance(value, tuple)) else []

        if _is_channel_vector(value, channels):
            return tuple(
                _coerce_channel_value(
                    channel,
                    input_range=input_range,
                    output_range=output_range,
                    clip=clip,
                )
                for channel in value
            )

        return _map_nested_values(
            value,
            map_pixel=lambda item: _map_pixel(
                item,
                channels=channels,
                mode=mode,
                input_range=input_range,
                output_range=output_range,
                clip=clip,
                allow_empty=allow_empty,
                preserve_tuples=preserve_tuples,
            ),
            allow_empty=allow_empty,
            preserve_tuples=preserve_tuples,
        )

    raise UnsupportedTypeError(
        f"{mode} mode expects sequence input; found {type(value).__name__}."
    )


def _is_channel_vector(value: object, channels: int) -> bool:
    if not isinstance(value, (list, tuple)) or len(value) != channels:
        return False
    return all(_is_scalar_pixel_unit(item) for item in value)


class ImageRangeMapper:
    """Map image-like values into normalized floats."""

    mapper_type = MAPPER_TYPE_IMAGE_RANGE
    spec_version = SPEC_VERSION

    def __init__(
        self,
        input_range: Sequence[float] = (0.0, 255.0),
        output_range: Sequence[float] = DEFAULT_OUTPUT_RANGE,
        *,
        clip: bool = False,
        mode: str = "grayscale",
        allow_empty: bool = False,
        preserve_tuples: bool = True,
        name: Optional[str] = None,
    ) -> None:
        if not isinstance(clip, bool):
            raise UnsupportedTypeError("clip must be a bool.")
        if not isinstance(allow_empty, bool):
            raise UnsupportedTypeError("allow_empty must be a bool.")
        if not isinstance(preserve_tuples, bool):
            raise UnsupportedTypeError("preserve_tuples must be a bool.")
        if name is not None and not isinstance(name, str):
            raise UnsupportedTypeError("name must be a string when provided.")
        if name is not None and name == "":
            raise UnsupportedTypeError("name must not be empty.")

        _validate_mode(mode, "mode")
        self.input_range = _validate_input_range(input_range, "input_range")
        self.output_range = _validate_output_range(output_range, "output_range")
        self.mode = mode
        self.clip = clip
        self.allow_empty = allow_empty
        self.preserve_tuples = preserve_tuples
        self.name = name

    def map_value(self, value: object) -> Union[float, List[Any], Tuple[Any, ...]]:
        """Map one image-like value to normalized value(s)."""
        if self.mode == "raw_bytes":
            if not isinstance(value, (bytes, bytearray, memoryview)):
                raise UnsupportedTypeError("raw_bytes mode requires bytes, bytearray, or memoryview input.")
            payload = bytes(value)
            if not payload and not self.allow_empty:
                raise UnsupportedTypeError("empty bytes input is invalid by default; set allow_empty=True to map it.")
            return [
                _coerce_channel_value(
                    unit,
                    input_range=self.input_range,
                    output_range=self.output_range,
                    clip=self.clip,
                )
                for unit in payload
            ]

        if self.mode in {"rgb", "rgba"}:
            channels = 3 if self.mode == "rgb" else 4
            return _map_pixel(
                value,
                channels=channels,
                mode=self.mode,
                input_range=self.input_range,
                output_range=self.output_range,
                clip=self.clip,
                allow_empty=self.allow_empty,
                preserve_tuples=self.preserve_tuples,
            )

        return _map_grayscale(
            value,
            input_range=self.input_range,
            output_range=self.output_range,
            clip=self.clip,
            allow_empty=self.allow_empty,
            preserve_tuples=self.preserve_tuples,
        )

    def transform(self, value: object) -> Union[float, List[Any], Tuple[Any, ...]]:
        """Alias for map_value."""
        return self.map_value(value)

    def map(self, value: object) -> Union[float, List[Any], Tuple[Any, ...]]:
        """Compatibility alias."""
        return self.map_value(value)

    def to_dict(self) -> Dict[str, Any]:
        """Return a JSON-compatible mapper spec."""
        data = {
            "spec_version": self.spec_version,
            "implementation_version": _implementation_version(),
            "mapper_type": self.mapper_type,
            "input_range": [self.input_range[0], self.input_range[1]],
            "output_range": [self.output_range[0], self.output_range[1]],
            "clip": self.clip,
            "mode": self.mode,
            "allow_empty": self.allow_empty,
            "preserve_tuples": self.preserve_tuples,
        }
        if self.name is not None:
            data["name"] = self.name
        return data

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "ImageRangeMapper":
        """Create an image mapper from a JSON-compatible mapper spec."""
        if not isinstance(data, dict):
            raise SerializationError("mapper spec must be a dictionary.")
        if data.get("spec_version") != SPEC_VERSION:
            raise SerializationError(f"unsupported spec_version {data.get('spec_version')!r}; expected {SPEC_VERSION!r}.")
        if data.get("mapper_type") != MAPPER_TYPE_IMAGE_RANGE:
            raise SerializationError(
                f"unsupported mapper_type {data.get('mapper_type')!r}; expected {MAPPER_TYPE_IMAGE_RANGE!r}."
            )
        if "input_range" not in data:
            raise SerializationError("mapper spec is missing required field 'input_range'.")

        try:
            return cls(
                input_range=data["input_range"],
                output_range=data.get("output_range", DEFAULT_OUTPUT_RANGE),
                clip=data.get("clip", False),
                mode=data.get("mode", "grayscale"),
                allow_empty=data.get("allow_empty", False),
                preserve_tuples=data.get("preserve_tuples", True),
                name=data.get("name"),
            )
        except KeyError as exc:
            raise SerializationError(f"mapper spec is missing required field {exc.args[0]!r}.") from exc

    def to_json(self) -> str:
        """Serialize this mapper as JSON."""
        return dumps_json(self.to_dict())

    @classmethod
    def from_json(cls, text: str) -> "ImageRangeMapper":
        """Load an image mapper from JSON."""
        return cls.from_dict(loads_json(text))

    def save(self, path: str) -> None:
        """Save an image mapper spec to disk."""
        save_json_file(path, self.to_dict())

    @classmethod
    def load(cls, path: str) -> "ImageRangeMapper":
        """Load an image mapper spec from disk."""
        return cls.from_dict(load_json_file(path))


def _implementation_version() -> str:
    from . import __version__

    return __version__
