"""Native C backend loading for libRangeMap."""

from __future__ import annotations

import ctypes
from pathlib import Path
from typing import Optional


class _NativeMapperStruct(ctypes.Structure):
    _fields_ = [
        ("input_min", ctypes.c_longlong),
        ("input_max", ctypes.c_longlong),
        ("output_min", ctypes.c_double),
        ("output_max", ctypes.c_double),
        ("clip", ctypes.c_int),
    ]


class _NativeSpecStruct(ctypes.Structure):
    _fields_ = [
        ("spec_version_major", ctypes.c_int),
        ("spec_version_minor", ctypes.c_int),
        ("input_min", ctypes.c_longlong),
        ("input_max", ctypes.c_longlong),
        ("output_min", ctypes.c_double),
        ("output_max", ctypes.c_double),
        ("clip", ctypes.c_int),
    ]


class NativeBackend:
    """Load and call the compiled C core when present."""

    def __init__(self, library_path: Path):
        self.library_path = library_path
        self._lib = ctypes.CDLL(str(library_path))
        self._configure()

    def _configure(self) -> None:
        self._lib.lrm_integer_range_mapper_init.argtypes = [
            ctypes.POINTER(_NativeMapperStruct),
            ctypes.c_longlong,
            ctypes.c_longlong,
            ctypes.c_double,
            ctypes.c_double,
            ctypes.c_int,
        ]
        self._lib.lrm_integer_range_mapper_init.restype = ctypes.c_int

        self._lib.lrm_integer_range_mapper_map_value.argtypes = [
            ctypes.POINTER(_NativeMapperStruct),
            ctypes.c_longlong,
            ctypes.POINTER(ctypes.c_double),
        ]
        self._lib.lrm_integer_range_mapper_map_value.restype = ctypes.c_int

        self._lib.lrm_integer_range_mapper_get_spec.argtypes = [
            ctypes.POINTER(_NativeMapperStruct),
            ctypes.POINTER(_NativeSpecStruct),
        ]
        self._lib.lrm_integer_range_mapper_get_spec.restype = ctypes.c_int

    def create_mapper(self, input_min: int, input_max: int, output_min: float, output_max: float, clip: bool):
        mapper = _NativeMapperStruct()
        result = self._lib.lrm_integer_range_mapper_init(
            ctypes.byref(mapper),
            input_min,
            input_max,
            output_min,
            output_max,
            1 if clip else 0,
        )
        if result != 0:
            return None
        return mapper

    def map_value(self, mapper: _NativeMapperStruct, value: int) -> float:
        output = ctypes.c_double()
        result = self._lib.lrm_integer_range_mapper_map_value(
            ctypes.byref(mapper),
            value,
            ctypes.byref(output),
        )
        if result != 0:
            raise RuntimeError(f"native mapping failed with code {result}")
        return float(output.value)

    def get_spec(self, mapper: _NativeMapperStruct) -> dict:
        spec = _NativeSpecStruct()
        result = self._lib.lrm_integer_range_mapper_get_spec(ctypes.byref(mapper), ctypes.byref(spec))
        if result != 0:
            raise RuntimeError(f"native spec retrieval failed with code {result}")
        return {
            "spec_version_major": int(spec.spec_version_major),
            "spec_version_minor": int(spec.spec_version_minor),
            "input_min": int(spec.input_min),
            "input_max": int(spec.input_max),
            "output_min": float(spec.output_min),
            "output_max": float(spec.output_max),
            "clip": bool(spec.clip),
        }


def _candidate_paths() -> list[Path]:
    package_dir = Path(__file__).resolve().parent
    return [
        package_dir / "native" / "librangemap_core.dll",
    ]


def load_native_backend() -> Optional[NativeBackend]:
    for path in _candidate_paths():
        if path.exists():
            try:
                return NativeBackend(path)
            except OSError:
                return None
    return None
