@echo off
setlocal

set "ROOT=%~dp0..\.."
set "PATH=%ROOT%\librangemap\native;%PATH%"

if not exist "%ROOT%\wrappers\ruby\verify\verify.rb" exit /b 1

set "RUBY_EXE="
for /f "delims=" %%I in ('where ruby 2^>nul') do (
    set "RUBY_EXE=%%I"
    goto found
)
if not defined RUBY_EXE if exist "C:\Ruby31-x64\bin\ruby.exe" set "RUBY_EXE=C:\Ruby31-x64\bin\ruby.exe"

:found
if not defined RUBY_EXE (
    echo Ruby executable not found on PATH.
    exit /b 2
)

%RUBY_EXE% "%ROOT%\wrappers\ruby\verify\verify.rb"
