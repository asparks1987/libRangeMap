"""Exception types used by libRangeMap."""


class RangeMapError(Exception):
    """Base class for all libRangeMap exceptions."""


class InvalidRangeError(RangeMapError, ValueError):
    """Raised when a mapper range is malformed or unsupported."""


class OutOfRangeError(RangeMapError, ValueError):
    """Raised when strict mode receives a value outside the input range."""


class UnsupportedTypeError(RangeMapError, TypeError):
    """Raised when a mapper receives a value of an unsupported type."""


class NotFiniteError(RangeMapError, ValueError):
    """Raised when a mapper receives NaN or infinity."""


class SerializationError(RangeMapError, ValueError):
    """Raised when a mapping spec cannot be serialized or loaded."""


class NotFittedError(RangeMapError):
    """Reserved for future fitted mappers."""
