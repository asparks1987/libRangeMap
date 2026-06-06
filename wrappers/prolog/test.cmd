@echo off
setlocal

set "ROOT=%~dp0..\.."

set "VERIFIER=%ROOT%\tools\verify_wrapper_contract.ps1"
if exist "%VERIFIER%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%VERIFIER%" -Language prolog -Artifact "%ROOT%\wrappers\prolog\librangemap.pl"
    exit /b %ERRORLEVEL%
)

echo Contract verifier unavailable for Prolog wrappers.
exit /b 1
