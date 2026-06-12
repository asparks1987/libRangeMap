@echo off
setlocal

set "ROOT=%~dp0..\.."
set "PHP_EXE=%ROOT%third_party\bin\php.exe"
if not exist "%PHP_EXE%" set "PHP_EXE="

if not exist "%PHP_EXE%" (
    if exist "C:\\PHP\\php.exe" set "PHP_EXE=C:\\PHP\\php.exe"
)
if not exist "%PHP_EXE%" (
    if exist "C:\\Program Files\\PHP\\php.exe" set "PHP_EXE=C:\\Program Files\\PHP\\php.exe"
)
if not exist "%PHP_EXE%" (
    if exist "C:\\Program Files\\PHP\\PHP 8\\php.exe" set "PHP_EXE=C:\\Program Files\\PHP\\PHP 8\\php.exe"
)

if not exist "%PHP_EXE%" (
    for /f "delims=" %%P in ('where php 2^>nul') do (
        set "PHP_EXE=%%P"
        goto found
    )
)

:found
if not defined PHP_EXE (
    echo PHP executable not found. Install PHP and ensure it is on PATH.
    exit /b 2
)

"%PHP_EXE%" "%ROOT%\wrappers\php\LibrangeMap.php"
