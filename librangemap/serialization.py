"""Standard-library JSON serialization helpers."""

import json
from typing import Any

from .errors import SerializationError


def dumps_json(data: Any) -> str:
    """Serialize data to stable, human-readable JSON."""
    try:
        return json.dumps(data, indent=2, sort_keys=True) + "\n"
    except (TypeError, ValueError) as exc:
        raise SerializationError(f"mapper spec could not be serialized: {exc}") from exc


def loads_json(text: str) -> Any:
    """Deserialize JSON text."""
    try:
        return json.loads(text)
    except json.JSONDecodeError as exc:
        raise SerializationError(f"mapper spec is not valid JSON: {exc}") from exc


def save_json_file(path: str, data: Any) -> None:
    """Write JSON data to a UTF-8 file."""
    try:
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(dumps_json(data))
    except OSError as exc:
        raise SerializationError(f"mapper spec could not be saved to {path!r}: {exc}") from exc


def load_json_file(path: str) -> Any:
    """Read JSON data from a UTF-8 file."""
    try:
        with open(path, "r", encoding="utf-8") as handle:
            return loads_json(handle.read())
    except OSError as exc:
        raise SerializationError(f"mapper spec could not be loaded from {path!r}: {exc}") from exc
