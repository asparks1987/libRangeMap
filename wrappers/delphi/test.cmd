@echo off
setlocal

set "ROOT=%~dp0..\.."

set "VERIFIER=%ROOT%\tools\verify_wrapper_contract.ps1"
if exist "%VERIFIER%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%VERIFIER%" -Language delphi -Artifact "%ROOT%\wrappers\delphi\librangemap.pas"
    exit /b %ERRORLEVEL%
)

echo Contract verifier unavailable for Delphi/Object Pascal wrappers.
exit /b 1
