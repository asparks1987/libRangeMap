@echo off
set "ROOT=%~dp0..\.."

set "PHP_EXE="
if exist "C:\Users\Aryns\AppData\Local\Microsoft\WinGet\Packages\PHP.PHP.8.3_Microsoft.Winget.Source_8wekyb3d8bbwe\php.exe" set "PHP_EXE=C:\Users\Aryns\AppData\Local\Microsoft\WinGet\Packages\PHP.PHP.8.3_Microsoft.Winget.Source_8wekyb3d8bbwe\php.exe"
if not defined PHP_EXE if exist "C:\Users\Aryns\AppData\Local\Programs\PHP\php.exe" set "PHP_EXE=C:\Users\Aryns\AppData\Local\Programs\PHP\php.exe"
for /f "delims=" %%I in ('where php 2^>nul') do if not defined PHP_EXE set "PHP_EXE=%%I"

if not defined PHP_EXE (
    echo PHP executable not found.
    exit /b 2
)

"%PHP_EXE%" "%ROOT%\wrappers\php\LibrangeMap.php"
set "RC=%ERRORLEVEL%"
if "%RC%"=="5" exit /b 2
exit /b %RC%
