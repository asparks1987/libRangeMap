@echo off
setlocal

set "ROOT=%~dp0..\.."
set "VERIFIER=%ROOT%\tools\verify_wrapper_contract.ps1"

if exist "%VERIFIER%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%VERIFIER%" -Language vb6 -Artifact "%ROOT%\wrappers\vb6\Librangemap.bas"
    exit /b %ERRORLEVEL%
)

echo Contract verifier unavailable for Classic VB wrappers.
exit /b 1
