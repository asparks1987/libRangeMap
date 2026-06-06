@echo off
setlocal

set "ROOT=%~dp0..\.."
set "PATH=%ROOT%\librangemap\native;%PATH%"

dotnet run --project "%ROOT%\wrappers\vb\Verify\Verify.vbproj"
set "RC=%ERRORLEVEL%"
exit /b %RC%
