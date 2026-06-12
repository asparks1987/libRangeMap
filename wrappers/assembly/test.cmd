@echo off
setlocal

set "ROOT=%~dp0..\.."

set "VERIFIER=%ROOT%\tools\verify_wrapper_contract.ps1"
if exist "%VERIFIER%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%VERIFIER%" -Language assembly -Artifact "%ROOT%\wrappers\assembly\librangemap.asm"
    if errorlevel 1 exit /b %ERRORLEVEL%
    findstr /C:"global librangemap_map_float" "%ROOT%\wrappers\assembly\librangemap.asm" >nul
    if errorlevel 1 exit /b 1
    findstr /C:"global librangemap_map_boolean" "%ROOT%\wrappers\assembly\librangemap.asm" >nul
    if errorlevel 1 exit /b 1
    findstr /C:"global librangemap_map_text" "%ROOT%\wrappers\assembly\librangemap.asm" >nul
    if errorlevel 1 exit /b 1
    findstr /C:"global librangemap_map_bytes" "%ROOT%\wrappers\assembly\librangemap.asm" >nul
    if errorlevel 1 exit /b 1
    findstr /C:"global librangemap_map_sequence" "%ROOT%\wrappers\assembly\librangemap.asm" >nul
    if errorlevel 1 exit /b 1
    findstr /C:"global librangemap_map_object" "%ROOT%\wrappers\assembly\librangemap.asm" >nul
    if errorlevel 1 exit /b 1
    findstr /C:"global librangemap_map_categorical" "%ROOT%\wrappers\assembly\librangemap.asm" >nul
    if errorlevel 1 exit /b 1
    findstr /C:"global librangemap_map_image_raw" "%ROOT%\wrappers\assembly\librangemap.asm" >nul
    if errorlevel 1 exit /b 1
    findstr /C:"unknown_text_token" "%ROOT%\wrappers\assembly\librangemap.asm" >nul
    if errorlevel 1 exit /b 1
    findstr /C:"payload length must equal width * height * channels" "%ROOT%\wrappers\assembly\librangemap.asm" >nul
    if errorlevel 1 exit /b 1
    exit /b 0
)

echo Contract verifier unavailable for Assembly wrappers.
exit /b 2
