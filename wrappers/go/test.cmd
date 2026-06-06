@echo off
setlocal

set "ROOT=%~dp0..\.."
set "PATH=%ROOT%\librangemap\native;%PATH%"
set "CC=%ROOT%\tools\zigcc.cmd"
set "CGO_ENABLED=1"

pushd "%~dp0"
go test ./...
set "EXITCODE=%ERRORLEVEL%"
popd
exit /b %EXITCODE%
