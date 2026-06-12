@echo off
setlocal

set "ROOT=%~dp0..\.."
set "ARTIFACT=%ROOT%\wrappers\plsql\librangemap.sql"
set "VERIFIER=%ROOT%\tools\verify_wrapper_contract.ps1"

if not exist "%VERIFIER%" (
    echo Contract verifier unavailable for PL/SQL wrappers.
    exit /b 2
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%VERIFIER%" -Language plsql -Artifact "%ARTIFACT%"
if errorlevel 1 exit /b %errorlevel%

findstr /C:"libRangeMap_map_object_value" "%ARTIFACT%" >nul
if errorlevel 1 exit /b 1

findstr /C:"libRangeMap_map_object(" "%ARTIFACT%" >nul
if errorlevel 1 exit /b 1

findstr /C:"libRangeMap_map_image_raw" "%ARTIFACT%" >nul
if errorlevel 1 exit /b 1

findstr /C:"image payload length does not match shape metadata" "%ARTIFACT%" >nul
if errorlevel 1 exit /b 1

findstr /C:"unknown mapper_type" "%ARTIFACT%" >nul
if errorlevel 1 exit /b 1

findstr /C:"spec must define mapper_type or family" "%ARTIFACT%" >nul
if errorlevel 1 exit /b 1

findstr /C:"allow_unknown" "%ARTIFACT%" >nul
if errorlevel 1 exit /b 1

exit /b 0
