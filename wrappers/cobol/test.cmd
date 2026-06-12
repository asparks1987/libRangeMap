@echo off
setlocal

set "ROOT=%~dp0..\.."

set "VERIFIER=%ROOT%\tools\verify_wrapper_contract.ps1"
if exist "%VERIFIER%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%VERIFIER%" -Language cobol -Artifact "%ROOT%\wrappers\cobol\librangemap.cob"
    exit /b %ERRORLEVEL%
)

echo Contract verifier unavailable for COBOL wrappers.
exit /b 2
