@echo off
setlocal

set "ROOT=%~dp0..\.."

set "VERIFIER=%ROOT%\tools\verify_wrapper_contract.ps1"
if exist "%VERIFIER%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%VERIFIER%" -Language assembly -Artifact "%ROOT%\wrappers\assembly\librangemap.asm"
    exit /b %ERRORLEVEL%
)

echo Contract verifier unavailable for Assembly wrappers.
exit /b 1
