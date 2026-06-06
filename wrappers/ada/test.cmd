@echo off
setlocal

set "ROOT=%~dp0..\.."

set "ADAC=%ROOT%\tools\verify_wrapper_contract.ps1"
if exist "%ADAC%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%ADAC%" -Language ada -Artifact "%ROOT%\wrappers\ada\librangemap.adb"
    exit /b %ERRORLEVEL%
)

echo Contract verifier missing for Ada wrappers.
exit /b 1
