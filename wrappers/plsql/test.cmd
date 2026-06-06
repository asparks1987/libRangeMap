@echo off
setlocal

set "ROOT=%~dp0..\.."

set "VERIFIER=%ROOT%\tools\verify_wrapper_contract.ps1"
if exist "%VERIFIER%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%VERIFIER%" -Language plsql -Artifact "%ROOT%\wrappers\plsql\librangemap.sql"
    exit /b %ERRORLEVEL%
)

echo Contract verifier unavailable for PL/SQL wrappers.
exit /b 1
