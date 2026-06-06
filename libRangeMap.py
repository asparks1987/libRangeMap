"""Compatibility module for legacy ``libRangeMap`` imports.

The canonical alpha package is ``librangemap``. This module keeps the old
``from libRangeMap import RangeMapper`` style usable for integer ranges while
moving behavior to the new dependency-free implementation.
"""

from librangemap import IntegerRangeMapper, UnsupportedTypeError


class RangeMapper(IntegerRangeMapper):
    """Compatibility wrapper around IntegerRangeMapper.

    Unlike the historical experiment, the default output range is now
    ``[-1.0, 1.0]`` and strict out-of-range behavior is the default.
    """

    def __init__(self, low: int, high: int, low_out: float = -1.0, high_out: float = 1.0, clip: bool = False) -> None:
        super().__init__(input_range=(low, high), output_range=(low_out, high_out), clip=clip)

    def get_input_range(self) -> list:
        return list(self.input_range)

    def get_output_range(self) -> list:
        return list(self.output_range)


class CharRangeMapper:
    """Legacy character mapper placeholder.

    Character mapping is deferred until beta because alpha does not allow
    unknown characters to map to arbitrary fallback values.
    """

    def __init__(self, *args, **kwargs) -> None:
        raise UnsupportedTypeError(
            "CharRangeMapper is legacy and not supported in Alpha v1; use IntegerRangeMapper for integer ranges."
        )
