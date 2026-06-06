@echo off
setlocal

set "ROOT=%~dp0..\.."
set "VERIFIER=%ROOT%\tools\verify_wrapper_contract.ps1"

if exist "%VERIFIER%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%VERIFIER%" -Language scratch -Artifact "%ROOT%\wrappers\scratch\librangemap.md"
    exit /b %ERRORLEVEL%
)

echo Contract verifier unavailable for Scratch wrappers.
exit /b 1
