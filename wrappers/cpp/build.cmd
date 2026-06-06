@echo off
setlocal

set "ROOT=%~dp0..\.."
set "BUILD_DIR=%ROOT%\wrappers\cpp\build"

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

call "%ROOT%\tools\zigcxx.cmd" -std=c++17 -O3 -I"%ROOT%\wrappers\cpp\include" -I"%ROOT%\csrc" -L"%ROOT%\librangemap\native" -llibrangemap_core -o "%BUILD_DIR%\librangemap_cpp.exe" "%ROOT%\wrappers\cpp\src\verify.cpp"
if errorlevel 1 exit /b 1

echo C++ wrapper build complete.
