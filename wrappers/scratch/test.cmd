@echo off
setlocal

set "ROOT=%~dp0..\.."
set "VERIFIER=%ROOT%\tools\verify_wrapper_contract.ps1"

if exist "%VERIFIER%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%VERIFIER%" -Language scratch -Artifact "%ROOT%\wrappers\scratch\librangemap.md"
    if errorlevel 1 exit /b %ERRORLEVEL%
    findstr /C:"Text inputs:" "%ROOT%\wrappers\scratch\librangemap.md" >nul
    if errorlevel 1 exit /b 1
    findstr /C:"Map/object inputs:" "%ROOT%\wrappers\scratch\librangemap.md" >nul
    if errorlevel 1 exit /b 1
    findstr /C:"Image-like inputs:" "%ROOT%\wrappers\scratch\librangemap.md" >nul
    if errorlevel 1 exit /b 1
    findstr /C:"unknown_text_token" "%ROOT%\wrappers\scratch\librangemap.md" >nul
    if errorlevel 1 exit /b 1
    exit /b 0
)

echo Contract verifier unavailable for Scratch wrappers.
exit /b 2
