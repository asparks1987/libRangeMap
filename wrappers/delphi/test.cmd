@echo off
setlocal

set "ROOT=%~dp0..\.."

set "VERIFIER=%ROOT%\tools\verify_wrapper_contract.ps1"
if exist "%VERIFIER%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%VERIFIER%" -Language delphi -Artifact "%ROOT%\wrappers\delphi\librangemap.pas"
    if errorlevel 1 exit /b %ERRORLEVEL%
    findstr /C:"MapImageRawValue" "%ROOT%\wrappers\delphi\librangemap.pas" >nul
    if errorlevel 1 exit /b 1
    findstr /C:"image payload length does not match shape metadata" "%ROOT%\wrappers\delphi\librangemap.pas" >nul
    if errorlevel 1 exit /b 1
    exit /b 0
)

echo Contract verifier unavailable for Delphi/Object Pascal wrappers.
exit /b 2
