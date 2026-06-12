@echo off
setlocal

set "ROOT=%~dp0..\.."
set "VERIFIER=%ROOT%\tools\verify_wrapper_contract.ps1"

if exist "%VERIFIER%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%VERIFIER%" -Language sql -Artifact "%ROOT%\wrappers\sql\librangemap.sql"
    exit /b %ERRORLEVEL%
)

echo Contract verifier unavailable for SQL wrappers.
exit /b 2
