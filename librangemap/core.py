"""Core validation and mapping helpers."""

import math
from typing import Sequence, Tuple

from .errors import InvalidRangeError, NotFiniteError, UnsupportedTypeError


def is_bool(value: object) -> bool:
    """Return True for booleans, which are intentionally not integers here."""
    return isinstance(value, bool)


def require_finite_number(value: object, field_name: str) -> None:
    """Validate that a value is a finite int or float."""
    if is_bool(value) or not isinstance(value, (int, float)):
        raise UnsupportedTypeError(f"{field_name} must be a finite numeric value.")
    if not math.isfinite(float(value)):
        raise NotFiniteError(f"{field_name} must be finite; NaN and infinity are not supported.")


def require_integer(value: object, field_name: str) -> None:
    """Validate that a value is an integer, excluding bool."""
    if is_bool(value) or not isinstance(value, int):
        raise UnsupportedTypeError(f"{field_name} must be an integer; bool and non-integers are not supported.")


def validate_integer_range(range_value: object, field_name: str) -> Tuple[int, int]:
    """Validate an ordered two-item integer range."""
    if not isinstance(range_value, (list, tuple)) or len(range_value) != 2:
        raise InvalidRangeError(f"{field_name} must be a two-item range like (0, 100).")

    low, high = range_value
    require_integer(low, f"{field_name}[0]")
    require_integer(high, f"{field_name}[1]")

    if high == low:
        raise InvalidRangeError(f"{field_name} min and max must be different.")
    if high < low:
        raise InvalidRangeError(f"{field_name} must be ordered from lower value to higher value.")

    return int(low), int(high)


def validate_output_range(range_value: object, field_name: str) -> Tuple[float, float]:
    """Validate an ordered two-item finite numeric output range."""
    if not isinstance(range_value, (list, tuple)) or len(range_value) != 2:
        raise InvalidRangeError(f"{field_name} must be a two-item range like (-1.0, 1.0).")

    low, high = range_value
    require_finite_number(low, f"{field_name}[0]")
    require_finite_number(high, f"{field_name}[1]")

    low = float(low)
    high = float(high)

    if high == low:
        raise InvalidRangeError(f"{field_name} min and max must be different.")
    if high < low:
        raise InvalidRangeError(f"{field_name} must be ordered from lower value to higher value.")

    return low, high


def map_linear(value: int, input_range: Sequence[int], output_range: Sequence[float]) -> float:
    """Map a value between ordered ranges using the canonical formula."""
    in_min, in_max = input_range
    out_min, out_max = output_range
    return out_min + ((value - in_min) / (in_max - in_min)) * (out_max - out_min)
