@echo off
setlocal

set "ROOT=%~dp0..\.."
set "PATH=%ROOT%\librangemap\native;%PATH%"

call "%ROOT%\wrappers\cpp\build.cmd" || exit /b 1
"%ROOT%\wrappers\cpp\build\librangemap_cpp.exe"
