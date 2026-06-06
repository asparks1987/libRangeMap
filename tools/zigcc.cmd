@echo off
setlocal

if defined ZIG_EXE goto run

for /f "delims=" %%I in ('where /r "%LOCALAPPDATA%\Microsoft\WinGet\Packages" zig.exe 2^>nul') do set "ZIG_EXE=%%I"

:run
if not defined ZIG_EXE (
    echo zig compiler not found. Set ZIG_EXE to the zig.exe path first. 1>&2
    exit /b 1
)

"%ZIG_EXE%" cc %*
