@echo off
setlocal

set "ROOT=%~dp0..\.."

set "VERIFIER=%ROOT%\tools\verify_wrapper_contract.ps1"
if exist "%VERIFIER%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%VERIFIER%" -Language matlab -Artifact "%ROOT%\wrappers\matlab\librangemap.m"
    exit /b %ERRORLEVEL%
)

echo Contract verifier unavailable for MATLAB wrappers.
exit /b 2
