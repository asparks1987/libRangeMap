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
from .bytes import BytesRangeMapper
from .categorical import CategoricalRangeMapper
from .sequence import SequenceRangeMapper
from .text import TextRangeMapper
from .map import MapRangeMapper
from .image import ImageRangeMapper
from .temporal import TemporalRangeMapper
from .spec import SPEC_VERSION

__version__ = "0.1.0-alpha"

__all__ = [
    "IntegerRangeMapper",
    "FloatRangeMapper",
    "SequenceRangeMapper",
    "MapRangeMapper",
    "BytesRangeMapper",
    "TextRangeMapper",
    "TemporalRangeMapper",
    "ImageRangeMapper",
    "BooleanRangeMapper",
    "CategoricalRangeMapper",
    "InvalidRangeError",
    "NotFiniteError",
    "OutOfRangeError",
    "RangeMapError",
    "SerializationError",
    "SPEC_VERSION",
    "UnsupportedTypeError",
    "__version__",
]
