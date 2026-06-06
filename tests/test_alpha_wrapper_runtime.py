import os
import shutil
import subprocess
import unittest


ROOT = os.path.dirname(os.path.dirname(__file__))


def _run_command(command, *, cwd, env=None):
    return subprocess.run(
        command,
        cwd=cwd,
        shell=True,
        check=False,
        capture_output=True,
        text=True,
        env=env,
    )


def _exists(path: str | None) -> bool:
    return bool(path and os.path.exists(path))


def _discover_zig():
    for candidate in (
        os.environ.get("ZIG_EXE"),
        os.path.join(
            os.environ.get("LOCALAPPDATA", ""),
            "Microsoft",
            "WinGet",
            "Packages",
            "zig.zig_Microsoft.Winget.Source_8wekyb3d8bbwe",
            "zig-x86_64-windows-0.16.0",
            "zig.exe",
        ),
        r"C:\Users\Aryns\AppData\Local\Microsoft\WinGet\Packages\zig.zig_Microsoft.Winget.Source_8wekyb3d8bbwe\zig-x86_64-windows-0.16.0\zig.exe",
    ):
        if _exists(candidate):
            return candidate

    return shutil.which("zig")


def _with_native_path(env=None):
    copied = dict(env or os.environ)
    native_dir = os.path.join(ROOT, "librangemap", "native")
    copied["PATH"] = os.pathsep.join([native_dir, copied.get("PATH", "")])
    return copied


def _with_zig_and_native_path(env=None):
    zig = _discover_zig()
    if not zig:
        return None

    copied = dict(env or os.environ)
    copied["ZIG_EXE"] = zig
    copied["CC"] = os.path.join(ROOT, "tools", "zigcc.cmd")
    return _with_native_path(copied)


def _with_java(env=None):
    if shutil.which("java") is None and shutil.which("java.exe") is None:
        return None
    return dict(env or os.environ)


def _with_node(env=None):
    if shutil.which("node") is None:
        return None
    return dict(env or os.environ)


def _with_dotnet(env=None):
    if shutil.which("dotnet") is None:
        return None
    return _with_native_path(env or os.environ)


def _with_go(env=None):
    if shutil.which("go") is None:
        return None
    copied = dict(env or os.environ)
    copied["CC"] = os.path.join(ROOT, "tools", "zigcc.cmd")
    copied["CGO_ENABLED"] = "1"
    return _with_native_path(copied)


def _with_cmake_style(env=None):
    return _with_zig_and_native_path(env)


def _with_r(env=None):
    if shutil.which("Rscript"):
        return dict(env or os.environ)
    for candidate in (
        os.path.join("C:", os.sep, "Program Files", "R", "R-4.6.0", "bin", "Rscript.exe"),
        os.path.join("C:", os.sep, "R", "R-4.6.0", "bin", "Rscript.exe"),
    ):
        if _exists(candidate):
            return dict(env or os.environ)
    return None


def _with_ruby(env=None):
    if _exists(os.path.join(ROOT, "third_party", "bin", "ruby.exe")):
        return dict(env or os.environ)
    if _exists(r"C:\RubySandbox\Ruby\bin\ruby.exe"):
        return dict(env or os.environ)
    if shutil.which("ruby"):
        return dict(env or os.environ)
    return None


def _with_php(env=None):
    if shutil.which("php"):
        return dict(env or os.environ)
    for candidate in (
        os.path.join(os.environ.get("LOCALAPPDATA", ""), "Programs", "PHP", "php.exe"),
        os.path.join(
            os.environ.get("LOCALAPPDATA", ""),
            "Microsoft",
            "WinGet",
            "Packages",
            "PHP.PHP.8.3_Microsoft.Winget.Source_8wekyb3d8bbwe",
            "php.exe",
        ),
    ):
        if _exists(candidate):
            return dict(env or os.environ)
    return None


def _with_perl(env=None):
    for candidate in (
        os.path.join(ROOT, "third_party", "bin", "perl.exe"),
        os.path.join("C:\\", "Program Files", "Git", "usr", "bin", "perl.exe"),
        os.path.join("C:\\", "Strawberry", "perl", "bin", "perl.exe"),
    ):
        if _exists(candidate):
            return dict(env or os.environ)
    if shutil.which("perl"):
        return dict(env or os.environ)
    return None


def _with_fortran(env=None):
    gfortran_paths = (
        os.environ.get("FC"),
        os.path.join("C:\\", "Strawberry", "c", "bin", "gfortran.exe"),
        os.path.join("C:\\", "Strawberry", "perl", "site", "bin", "gfortran.exe"),
        shutil.which("gfortran"),
    )
    executable = next((path for path in gfortran_paths if _exists(path)), None)
    if not executable:
        return None

    copied = dict(env or os.environ)
    copied["FC"] = executable
    copied["PATH"] = os.pathsep.join([os.path.dirname(executable), copied.get("PATH", "")])
    return copied


def _noop(_env=None):
    return dict(_env or os.environ)


VERIFIER_MATRIX = [
    ("python", None, _noop),
    ("c", "wrappers\\c\\test.cmd", _with_cmake_style),
    ("java", "wrappers\\java\\test.cmd", _with_java),
    ("c++", "wrappers\\cpp\\test.cmd", _with_cmake_style),
    ("c#", "wrappers\\csharp\\test.cmd", _with_dotnet),
    ("javascript", "wrappers\\javascript\\test.cmd", _with_node),
    ("visual basic", "wrappers\\vb\\test.cmd", _with_dotnet),
    ("r", "wrappers\\r\\test.cmd", _with_r),
    ("sql", "wrappers\\sql\\test.cmd", _noop),
    ("delphi/object pascal", "wrappers\\delphi\\test.cmd", _noop),
    ("fortran", "wrappers\\fortran\\test.cmd", _with_fortran),
    ("scratch", "wrappers\\scratch\\test.cmd", _noop),
    ("perl", "wrappers\\perl\\test.cmd", _with_perl),
    ("php", "wrappers\\php\\test.cmd", _with_php),
    ("rust", "wrappers\\rust\\test.cmd", _with_cmake_style),
    ("go", "wrappers\\go\\test.cmd", _with_go),
    ("assembly language", "wrappers\\assembly\\test.cmd", _noop),
    ("swift", "wrappers\\swift\\test.cmd", _noop),
    ("ada", "wrappers\\ada\\test.cmd", _noop),
    ("matlab", "wrappers\\matlab\\test.cmd", _noop),
    ("classic visual basic", "wrappers\\vb6\\test.cmd", _noop),
    ("pl/sql", "wrappers\\plsql\\test.cmd", _noop),
    ("ruby", "wrappers\\ruby\\test.cmd", _with_ruby),
    ("prolog", "wrappers\\prolog\\test.cmd", _noop),
    ("cobol", "wrappers\\cobol\\test.cmd", _noop),
]


class AlphaWrapperRuntimeComplianceTests(unittest.TestCase):
    def test_alpha_runtime_verifiers_pass(self):
        verified_languages = []
        skipped_languages = []
        failed = []

        for name, command, prepare_env in VERIFIER_MATRIX:
            env = prepare_env(os.environ.copy())
            if env is None:
                skipped_languages.append((name, "runtime not available in environment"))
                continue

            if command is None:
                try:
                    import librangemap  # pylint: disable=import-outside-toplevel

                    _ = librangemap.IntegerRangeMapper
                    verified_languages.append(name)
                    continue
                except Exception as exc:
                    failed.append((name, "import-failed", "", str(exc)))
                    continue

            rel_path = os.path.join(ROOT, command)
            if not os.path.isfile(rel_path):
                failed.append((name, 2, "", f"Missing verifier script: {rel_path}"))
                continue

            proc = _run_command(f'"{rel_path}"', cwd=ROOT, env=env)
            if proc.returncode == 0:
                verified_languages.append(name)
                continue
            if proc.returncode == 2:
                skipped_languages.append((name, "runtime missing or not configured"))
                continue
            failed.append((name, proc.returncode, proc.stdout, proc.stderr))

        with self.subTest():
            self.assertEqual(
                len(failed),
                0,
                "Runtime verifier failures: "
                + "; ".join(f"{name} (code {code})" for name, code, _, _ in failed),
            )

        self.assertGreaterEqual(len(verified_languages), 1)
        self.assertEqual(
            len(verified_languages) + len(skipped_languages),
            25,
            "Every canon language should be accounted for by verified or skipped verifier status.",
        )

    def test_alpha_reference_wrappers_present(self):
        expected_artifacts = {
            "python": "libRangeMap.py",
            "c": os.path.join("wrappers", "c", "librangemap.c"),
            "java": os.path.join("wrappers", "java", "src", "librangemap", "IntegerRangeMapper.java"),
            "cpp": os.path.join("wrappers", "cpp", "src", "verify.cpp"),
            "c#": os.path.join("wrappers", "csharp", "LibRangeMap", "IntegerRangeMapper.cs"),
            "javascript": os.path.join("wrappers", "javascript", "index.js"),
            "visual basic": os.path.join("wrappers", "vb", "LibRangeMap", "IntegerRangeMapper.vb"),
            "r": os.path.join("wrappers", "r", "librangemap.R"),
            "sql": os.path.join("wrappers", "sql", "librangemap.sql"),
            "delphi/object pascal": os.path.join("wrappers", "delphi", "librangemap.pas"),
            "fortran": os.path.join("wrappers", "fortran", "librangemap.f90"),
            "scratch": os.path.join("wrappers", "scratch", "librangemap.md"),
            "perl": os.path.join("wrappers", "perl", "librangemap.pl"),
            "php": os.path.join("wrappers", "php", "LibrangeMap.php"),
            "rust": os.path.join("wrappers", "rust", "src", "lib.rs"),
            "go": os.path.join("wrappers", "go", "librangemap", "integer_windows.go"),
            "assembly language": os.path.join("wrappers", "assembly", "librangemap.asm"),
            "swift": os.path.join("wrappers", "swift", "LibrangeMap.swift"),
            "ada": os.path.join("wrappers", "ada", "librangemap.adb"),
            "matlab": os.path.join("wrappers", "matlab", "librangemap.m"),
            "classic visual basic": os.path.join("wrappers", "vb6", "Librangemap.bas"),
            "pl/sql": os.path.join("wrappers", "plsql", "librangemap.sql"),
            "ruby": os.path.join("wrappers", "ruby", "lib", "librangemap.rb"),
            "prolog": os.path.join("wrappers", "prolog", "librangemap.pl"),
            "cobol": os.path.join("wrappers", "cobol", "librangemap.cob"),
        }
        for rel_path in expected_artifacts.values():
            self.assertTrue(os.path.exists(os.path.join(ROOT, rel_path)))


if __name__ == "__main__":
    unittest.main()
