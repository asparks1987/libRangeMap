from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

from setuptools import setup
from setuptools.command.build_py import build_py as _build_py


ROOT = Path(__file__).resolve().parent
NATIVE_SOURCE = ROOT / "csrc" / "librangemap_core.c"
NATIVE_HEADER = ROOT / "csrc" / "librangemap_core.h"
NATIVE_OUTPUT = ROOT / "librangemap" / "native" / "librangemap_core.dll"


def _find_zig() -> str | None:
    candidate = shutil.which("zig")
    if candidate:
        return candidate

    local_appdata = os.environ.get("LOCALAPPDATA")
    if local_appdata:
        packages_root = Path(local_appdata) / "Microsoft" / "WinGet" / "Packages"
        if packages_root.exists():
            matches = sorted(packages_root.rglob("zig.exe"))
            if matches:
                return str(matches[0])

    return None


def _build_native_library() -> None:
    if not NATIVE_SOURCE.exists() or not NATIVE_HEADER.exists():
        return

    zig = _find_zig()
    if zig is None:
        raise RuntimeError("Zig is required to build the libRangeMap native C core.")

    NATIVE_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    command = [
        zig,
        "cc",
        "-shared",
        "-O3",
        "-DLRM_BUILD_DLL",
        "-o",
        str(NATIVE_OUTPUT),
        str(NATIVE_SOURCE),
    ]
    subprocess.run(command, cwd=ROOT, check=True)


class build_py(_build_py):
    def run(self):
        _build_native_library()
        super().run()


setup(
    cmdclass={"build_py": build_py},
    package_data={"librangemap": ["native/*.dll"]},
)
