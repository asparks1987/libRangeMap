@echo off
setlocal

set "ROOT=%~dp0..\.."
set "VERIFIER=%ROOT%\tools\verify_wrapper_contract.ps1"

if exist "%VERIFIER%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%VERIFIER%" -Language swift -Artifact "%ROOT%\wrappers\swift\LibrangeMap.swift"
    exit /b %ERRORLEVEL%
)

echo Contract verifier unavailable for Swift wrappers.
exit /b 2
