@echo off
setlocal

set "ROOT=%~dp0..\.."
set "CC=%ROOT%\tools\zigcc.cmd"
if not defined ZIG_EXE for /f "delims=" %%I in ('where /r "%LOCALAPPDATA%\\Microsoft\\WinGet\\Packages" zig.exe 2^>nul') do set "ZIG_EXE=%%I"
set "OUT=%TEMP%\librangemap_c_verify.exe"

"%CC%" -std=c11 -I"%ROOT%\csrc" -I"%ROOT%\wrappers\c" "%ROOT%\wrappers\c\librangemap.c" "%ROOT%\csrc\librangemap_core.c" "%ROOT%\wrappers\c\verify.c" -o "%OUT%"
if errorlevel 1 exit /b 1

"%OUT%"
set "RC=%ERRORLEVEL%"
exit /b %RC%
