@echo off
setlocal

set "ROOT=%~dp0..\.."
set "PATH=%ROOT%\librangemap\native;%PATH%"
set "VERIFIER=%ROOT%\tools\verify_wrapper_contract.ps1"

if not exist "%ROOT%\wrappers\ruby\verify\verify.rb" exit /b 1

set "RUBY_EXE="
for /f "delims=" %%I in ('where ruby 2^>nul') do (
    set "RUBY_EXE=%%I"
    goto found
)
if not defined RUBY_EXE if exist "C:\Ruby31-x64\bin\ruby.exe" set "RUBY_EXE=C:\Ruby31-x64\bin\ruby.exe"

:found
if not defined RUBY_EXE (
    if exist "C:\RubySandbox\Ruby\bin\ruby.exe" set "RUBY_EXE=C:\RubySandbox\Ruby\bin\ruby.exe"
)
if not defined RUBY_EXE (
    echo Ruby executable not found on PATH. Falling back to source contract check.
    if exist "%VERIFIER%" (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%VERIFIER%" -Language ruby -Artifact "%ROOT%\wrappers\ruby\lib\librangemap.rb"
        exit /b %ERRORLEVEL%
    )
    echo Contract verifier unavailable for Ruby wrappers.
    exit /b 1
)

%RUBY_EXE% "%ROOT%\wrappers\ruby\verify\verify.rb"
