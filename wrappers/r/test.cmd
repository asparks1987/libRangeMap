@echo off
set "ROOT=%~dp0..\.."

set "RSCRIPT_EXE="
if exist "C:\Program Files\R\R-4.6.0\bin\Rscript.exe" set "RSCRIPT_EXE=C:\Program Files\R\R-4.6.0\bin\Rscript.exe"
if not defined RSCRIPT_EXE if exist "C:\R\R-4.6.0\bin\Rscript.exe" set "RSCRIPT_EXE=C:\R\R-4.6.0\bin\Rscript.exe"
if not defined RSCRIPT_EXE for /f "delims=" %%I in ('where Rscript 2^>nul') do set "RSCRIPT_EXE=%%I"

if not defined RSCRIPT_EXE (
    echo Rscript executable not found.
    exit /b 2
)

"%RSCRIPT_EXE%" "%ROOT%\wrappers\r\librangemap.R"
