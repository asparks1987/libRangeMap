@echo off
setlocal

set "ROOT=%~dp0..\.."
set "PATH=%ROOT%\librangemap\native;%PATH%"
set "CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_LINKER=%ROOT%\tools\zigcc.cmd"

call "%ROOT%\wrappers\rust\build.cmd" || exit /b 1
