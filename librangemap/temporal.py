"""Temporal value mapping into normalized floats."""

from __future__ import annotations

from datetime import date, datetime, time, timezone
from typing import Any, Dict, Optional, Sequence

from .core import map_linear, require_finite_number
from .errors import OutOfRangeError, SerializationError, UnsupportedTypeError
from .spec import DEFAULT_OUTPUT_RANGE, MAPPER_TYPE_TEMPORAL_RANGE, SPEC_VERSION
from .serialization import dumps_json, load_json_file, loads_json, save_json_file


def _coerce_epoch_base(epoch: object, naive_datetime_policy: str) -> float:
    if epoch is None:
        return 0.0
    if isinstance(epoch, (int, float)) and not isinstance(epoch, bool):
        value = float(epoch)
        require_finite_number(value, "epoch")
        return value
    if isinstance(epoch, datetime):
        return _datetime_to_epoch_seconds(_normalize_datetime(epoch, naive_datetime_policy))
    if isinstance(epoch, date):
        return _date_to_epoch_seconds(epoch)
    raise UnsupportedTypeError("epoch must be None, a finite number, or a datetime/date object.")


def _validate_output_range(output_range: object, field_name: str) -> tuple[float, float]:
    if not isinstance(output_range, (list, tuple)) or len(output_range) != 2:
        raise UnsupportedTypeError(f"{field_name} must be a two-item range like (-1.0, 1.0).")

    low, high = output_range
    if not isinstance(low, (int, float)) or isinstance(low, bool):
        raise UnsupportedTypeError(f"{field_name}[0] must be a finite number.")
    if not isinstance(high, (int, float)) or isinstance(high, bool):
        raise UnsupportedTypeError(f"{field_name}[1] must be a finite number.")

    low_f = float(low)
    high_f = float(high)
    require_finite_number(low_f, f"{field_name}[0]")
    require_finite_number(high_f, f"{field_name}[1]")

    if high == low:
        raise UnsupportedTypeError(f"{field_name} must be ordered from lower value to higher value.")
    if high_f < low_f:
        raise UnsupportedTypeError(f"{field_name} must be ordered from lower value to higher value.")

    return low_f, high_f


def _validate_input_range(value_range: object, field_name: str) -> tuple[float, float]:
    if not isinstance(value_range, (list, tuple)) or len(value_range) != 2:
        raise UnsupportedTypeError(f"{field_name} must be a two-item range like (0.0, 1.0).")

    low, high = value_range
    if not isinstance(low, (int, float)) or isinstance(low, bool):
        raise UnsupportedTypeError(f"{field_name}[0] must be a finite number.")
    if not isinstance(high, (int, float)) or isinstance(high, bool):
        raise UnsupportedTypeError(f"{field_name}[1] must be a finite number.")

    low_f = float(low)
    high_f = float(high)
    require_finite_number(low_f, f"{field_name}[0]")
    require_finite_number(high_f, f"{field_name}[1]")

    if high_f == low_f:
        raise UnsupportedTypeError(f"{field_name} min and max must be different.")
    if high_f < low_f:
        raise UnsupportedTypeError(f"{field_name} must be ordered from lower value to higher value.")

    return low_f, high_f


def _normalize_datetime(value: datetime, naive_datetime_policy: str) -> datetime:
    if value.tzinfo is None:
        if naive_datetime_policy != "naive_is_utc":
            raise UnsupportedTypeError(
                "naive datetime inputs are rejected; set naive_datetime_policy='naive_is_utc' to map as UTC."
            )
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def _date_to_epoch_seconds(value: date) -> float:
    return _datetime_to_epoch_seconds(
        datetime(value.year, value.month, value.day, tzinfo=timezone.utc)
    )


def _datetime_to_epoch_seconds(value: datetime) -> float:
    return value.timestamp()


def _validate_mode(value: object, field_name: str) -> None:
    if not isinstance(value, str):
        raise UnsupportedTypeError(f"{field_name} must be a supported temporal mode.")
    if value not in {"auto", "timestamp", "datetime", "duration", "time"}:
        raise UnsupportedTypeError(
            f"{field_name} must be one of: 'auto', 'timestamp', 'datetime', 'duration', or 'time'."
        )


def _validate_naive_policy(value: object, field_name: str) -> None:
    if not isinstance(value, str):
        raise UnsupportedTypeError(f"{field_name} must be a supported policy string.")
    if value not in {"naive_is_utc", "reject"}:
        raise UnsupportedTypeError(f"{field_name} must be 'naive_is_utc' or 'reject'.")


def _coerce_temporal_value(value: object, *, mode: str, epoch_base: float, naive_datetime_policy: str) -> float:
    if mode == "timestamp":
        if isinstance(value, (int, float)) and not isinstance(value, bool):
            value_f = float(value)
            require_finite_number(value_f, "value")
            return value_f
        raise UnsupportedTypeError("timestamp mode accepts float or int values only.")

    if mode == "duration":
        if isinstance(value, (int, float)) and not isinstance(value, bool):
            value_f = float(value)
            require_finite_number(value_f, "value")
            return value_f
        if hasattr(value, "total_seconds") and callable(getattr(value, "total_seconds")):
            value_f = float(value.total_seconds())
            require_finite_number(value_f, "value")
            return value_f
        raise UnsupportedTypeError("duration mode accepts float, int, or timedelta values.")

    if mode == "time":
        if not isinstance(value, time):
            raise UnsupportedTypeError("time mode accepts datetime.time values only.")
        if value.tzinfo is not None:
            raise UnsupportedTypeError("time mode does not accept timezone-aware times; normalize to UTC first.")
        return float(
            (
                (value.hour * 3600)
                + (value.minute * 60)
                + value.second
                + (value.microsecond / 1_000_000.0)
            )
        )

    if mode == "datetime":
        if isinstance(value, time):
            raise UnsupportedTypeError("datetime mode accepts datetime/date values only.")
        if hasattr(value, "total_seconds") and callable(getattr(value, "total_seconds")):
            raise UnsupportedTypeError("datetime mode does not accept duration-like values.")
        if isinstance(value, (int, float)) and not isinstance(value, bool):
            raise UnsupportedTypeError("datetime mode accepts datetime/date values only.")

    # auto or datetime
    if isinstance(value, time):
        return float(
            (
                (value.hour * 3600)
                + (value.minute * 60)
                + value.second
                + (value.microsecond / 1_000_000.0)
            )
        )
    if isinstance(value, datetime):
        return _datetime_to_epoch_seconds(_normalize_datetime(value, naive_datetime_policy)) - epoch_base
    if isinstance(value, date):
        return _date_to_epoch_seconds(value) - epoch_base
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        value_f = float(value)
        require_finite_number(value_f, "value")
        return value_f
    if hasattr(value, "total_seconds") and callable(getattr(value, "total_seconds")):
        value_f = float(value.total_seconds())  # type: ignore[assignment]
        require_finite_number(value_f, "value")
        return value_f

    if mode == "datetime":
        raise UnsupportedTypeError("datetime mode accepts datetime/date values only.")
    raise UnsupportedTypeError("unsupported temporal value type; configure a compatible temporal mode.")


class TemporalRangeMapper:
    """Map temporal-like values into a normalized float range."""

    mapper_type = MAPPER_TYPE_TEMPORAL_RANGE
    spec_version = SPEC_VERSION

    def __init__(
        self,
        input_range: Sequence[float],
        output_range: Sequence[float] = DEFAULT_OUTPUT_RANGE,
        clip: bool = False,
        mode: str = "auto",
        epoch: object = None,
        naive_datetime_policy: str = "naive_is_utc",
        name: Optional[str] = None,
    ) -> None:
        if not isinstance(clip, bool):
            raise UnsupportedTypeError("clip must be a bool.")
        if not isinstance(name, (str, type(None))):
            raise UnsupportedTypeError("name must be a string when provided.")
        if name is not None and name == "":
            raise UnsupportedTypeError("name must not be empty.")

        _validate_mode(mode, "mode")
        _validate_naive_policy(naive_datetime_policy, "naive_datetime_policy")
        self.input_range = _validate_input_range(input_range, "input_range")
        self.output_range = _validate_output_range(output_range, "output_range")
        self.clip = clip
        self.mode = mode
        self.epoch = _coerce_epoch_base(epoch, naive_datetime_policy)
        self.naive_datetime_policy = naive_datetime_policy
        self.name = name

    def map_value(self, value: object) -> float:
        """Map one temporal-like value to a float."""
        raw_value = _coerce_temporal_value(
            value,
            mode=self.mode,
            epoch_base=self.epoch,
            naive_datetime_policy=self.naive_datetime_policy,
        )

        in_min, in_max = self.input_range
        if raw_value < in_min:
            if not self.clip:
                raise OutOfRangeError(
                    f"value {raw_value} is below input_range lower bound {in_min}; enable clip to clamp."
                )
            raw_value = in_min
        elif raw_value > in_max:
            if not self.clip:
                raise OutOfRangeError(
                    f"value {raw_value} is above input_range upper bound {in_max}; enable clip to clamp."
                )
            raw_value = in_max

        return float(map_linear(raw_value, self.input_range, self.output_range))

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
            "input_range": [self.input_range[0], self.input_range[1]],
            "output_range": [self.output_range[0], self.output_range[1]],
            "clip": self.clip,
            "mode": self.mode,
            "naive_datetime_policy": self.naive_datetime_policy,
            "epoch": self.epoch,
        }
        if self.name is not None:
            data["name"] = self.name
        return data

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "TemporalRangeMapper":
        """Create a temporal mapper from a JSON-compatible mapper spec."""
        if not isinstance(data, dict):
            raise SerializationError("mapper spec must be a dictionary.")
        if data.get("spec_version") != SPEC_VERSION:
            raise SerializationError(f"unsupported spec_version {data.get('spec_version')!r}; expected {SPEC_VERSION!r}.")
        if data.get("mapper_type") != MAPPER_TYPE_TEMPORAL_RANGE:
            raise SerializationError(
                f"unsupported mapper_type {data.get('mapper_type')!r}; expected {MAPPER_TYPE_TEMPORAL_RANGE!r}."
            )

        if "input_range" not in data:
            raise SerializationError("mapper spec is missing required field 'input_range'.")

        try:
            return cls(
                input_range=data["input_range"],
                output_range=data.get("output_range", DEFAULT_OUTPUT_RANGE),
                clip=data.get("clip", False),
                mode=data.get("mode", "auto"),
                epoch=data.get("epoch"),
                naive_datetime_policy=data.get("naive_datetime_policy", "naive_is_utc"),
                name=data.get("name"),
            )
        except KeyError as exc:
            raise SerializationError(f"mapper spec is missing required field {exc.args[0]!r}.") from exc

    def to_json(self) -> str:
        """Serialize this mapper spec as JSON."""
        return dumps_json(self.to_dict())

    @classmethod
    def from_json(cls, text: str) -> "TemporalRangeMapper":
        """Load a temporal mapper from JSON."""
        return cls.from_dict(loads_json(text))

    def save(self, path: str) -> None:
        """Save this mapper spec to disk."""
        save_json_file(path, self.to_dict())

    @classmethod
    def load(cls, path: str) -> "TemporalRangeMapper":
        """Load a temporal mapper from disk."""
        return cls.from_dict(load_json_file(path))


def _implementation_version() -> str:
    from . import __version__

    return __version__
