@echo off
setlocal

set "ROOT=%~dp0..\.."
set "CC=%ROOT%\tools\zigcc.cmd"
set "OUT=%TEMP%\librangemap_c_verify.exe"

"%CC%" -std=c11 -I"%ROOT%\csrc" -I"%ROOT%\wrappers\c" "%ROOT%\wrappers\c\librangemap.c" "%ROOT%\csrc\librangemap_core.c" "%ROOT%\wrappers\c\verify.c" -o "%OUT%"
if errorlevel 1 exit /b 1

"%OUT%"
set "RC=%ERRORLEVEL%"
exit /b %RC%
