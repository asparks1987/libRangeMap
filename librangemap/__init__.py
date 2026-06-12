"""Dependency-free range mapping primitives for libRangeMap."""

from .errors import (
    InvalidRangeError,
    NotFiniteError,
    OutOfRangeError,
    RangeMapError,
    SerializationError,
    UnsupportedTypeError,
)
from .integer import IntegerRangeMapper
from .float import FloatRangeMapper
from .boolean import BooleanRangeMapper
from .sequence import SequenceRangeMapper
from .text import TextRangeMapper
from .spec import SPEC_VERSION

__version__ = "0.1.0-alpha"

__all__ = [
    "IntegerRangeMapper",
    "FloatRangeMapper",
    "SequenceRangeMapper",
    "TextRangeMapper",
    "BooleanRangeMapper",
    "InvalidRangeError",
    "NotFiniteError",
    "OutOfRangeError",
    "RangeMapError",
    "SerializationError",
    "SPEC_VERSION",
    "UnsupportedTypeError",
    "__version__",
]
