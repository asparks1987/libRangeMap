"""Write runtime verification results for the 25-language smoke matrix.

The default mode executes the same smoke checks used by
tests/test_alpha_wrapper_runtime.py and writes a JSON result file compatible
with compliance/runtime_verification_results.schema.json.

Use --dry-run to validate result-file shape without invoking language tools.
"""

from __future__ import annotations

import argparse
import json
import os
import platform
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List


ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tests.test_alpha_wrapper_runtime import (  # noqa: E402
    ROOT as TEST_ROOT,
    VERIFIER_MATRIX,
    _run_command,
)


STATUS_PATH = ROOT / "compliance" / "runtime_verification_status.json"


def _load_status() -> Dict[str, Any]:
    with STATUS_PATH.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def _matrix_by_name() -> Dict[str, Any]:
    return {name.lower(): (command, prepare_env) for name, command, prepare_env in VERIFIER_MATRIX}


def _result_for_language(item: Dict[str, Any], *, dry_run: bool) -> Dict[str, Any]:
    command, prepare_env = _matrix_by_name()[item["name"].lower()]
    base = {
        "order": item["order"],
        "name": item["name"],
        "slug": item["slug"],
        "smoke_check": item["smoke_check"],
    }

    if dry_run:
        return {
            **base,
            "result": "skipped",
            "reason": "dry-run requested; smoke check was not executed.",
        }

    env = prepare_env(os.environ.copy())
    if env is None:
        return {
            **base,
            "result": "skipped",
            "reason": f"runtime/toolchain unavailable: {item['environment_gate']}",
        }

    if command is None:
        try:
            import librangemap  # pylint: disable=import-outside-toplevel

            _ = librangemap.IntegerRangeMapper
            return {**base, "result": "verified", "reason": "Python package import succeeded."}
        except Exception as exc:  # pragma: no cover - environment evidence path
            return {**base, "result": "failed", "reason": f"Python import failed: {exc}"}

    script_path = Path(TEST_ROOT) / command
    if not script_path.is_file():
        return {**base, "result": "failed", "reason": f"missing smoke script: {script_path}"}

    proc = _run_command(f'"{script_path}"', cwd=str(ROOT), env=env)
    if proc.returncode == 0:
        return {**base, "result": "verified", "reason": "smoke check exited 0."}
    if proc.returncode == 2:
        return {**base, "result": "skipped", "reason": "smoke check reported missing runtime/toolchain."}

    stderr = (proc.stderr or "").strip()
    stdout = (proc.stdout or "").strip()
    detail = stderr or stdout or f"exit code {proc.returncode}"
    return {**base, "result": "failed", "reason": detail[:1000]}


def build_results(*, dry_run: bool) -> Dict[str, Any]:
    status = _load_status()
    results = [_result_for_language(item, dry_run=dry_run) for item in status["languages"]]
    return {
        "scope": "alpha_v1_beta_runtime_verification_results",
        "spec_version": "1.0",
        "generated_by": "tools/write_runtime_verification_results.py",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "dry_run": dry_run,
        "environment": {
            "os": platform.platform(),
            "python": platform.python_version(),
        },
        "results": results,
    }


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", help="Write results JSON to this path. Defaults to stdout.")
    parser.add_argument("--dry-run", action="store_true", help="Emit skipped records without running smoke checks.")
    args = parser.parse_args(argv)

    payload = build_results(dry_run=args.dry_run)
    text = json.dumps(payload, indent=2, sort_keys=True) + "\n"
    if args.output:
        Path(args.output).write_text(text, encoding="utf-8")
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
