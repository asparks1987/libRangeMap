@echo off
setlocal

set "ROOT=%~dp0..\.."
set "PERL_EXE=%ROOT%third_party\bin\perl.exe"
if not exist "%PERL_EXE%" set "PERL_EXE="

if not exist "%PERL_EXE%" (
    if exist "C:\\Program Files\\Git\\usr\\bin\\perl.exe" set "PERL_EXE=C:\\Program Files\\Git\\usr\\bin\\perl.exe"
)
if not exist "%PERL_EXE%" (
    if exist "C:\\Strawberry\\perl\\bin\\perl.exe" set "PERL_EXE=C:\\Strawberry\\perl\\bin\\perl.exe"
)

if not exist "%PERL_EXE%" (
    for /f "delims=" %%P in ('where perl 2^>nul') do (
        set "PERL_EXE=%%P"
        goto found
    )
)

:found
if not defined PERL_EXE (
    echo Perl executable not found. Install perl and ensure it is on PATH.
    exit /b 2
)

"%PERL_EXE%" "%ROOT%\wrappers\perl\librangemap.pl"
