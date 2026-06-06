"""Compatibility module for legacy ``libRangeMap`` imports.

The canonical alpha package is ``librangemap``. This module keeps the old
``from libRangeMap import RangeMapper`` style usable for integer ranges while
moving behavior to the new dependency-free implementation.
"""

from librangemap import IntegerRangeMapper


class RangeMapper(IntegerRangeMapper):
    """Compatibility wrapper around IntegerRangeMapper.

    Unlike the historical experiment, the default output range is now
    ``[-1.0, 1.0]`` and strict out-of-range behavior is the default.
    """

    def __init__(self, low, high, low_out=-1.0, high_out=1.0, clip=False):
        super().__init__(input_range=(low, high), output_range=(low_out, high_out), clip=clip)

    def get_input_range(self):
        return list(self.input_range)

    def get_output_range(self):
        return list(self.output_range)


CharRangeMapper = None
