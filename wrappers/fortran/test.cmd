@echo off
setlocal

set "ROOT=%~dp0..\.."
set "FORTRAN_EXE="
if defined FC set "FORTRAN_EXE=%FC%"
if not defined FORTRAN_EXE if exist "C:\Strawberry\c\bin\gfortran.exe" set "FORTRAN_EXE=C:\Strawberry\c\bin\gfortran.exe"
if not defined FORTRAN_EXE if exist "C:\Strawberry\perl\site\bin\gfortran.exe" set "FORTRAN_EXE=C:\Strawberry\perl\site\bin\gfortran.exe"
if not defined FORTRAN_EXE (
    for /f "delims=" %%I in ('where gfortran.exe 2^>nul') do (
        set "FORTRAN_EXE=%%I"
        goto found
    )
)
if not defined FORTRAN_EXE set "FORTRAN_EXE=gfortran"
:found
if not defined FORTRAN_EXE (
    echo Fortran compiler not found.
    exit /b 2
)
if not exist "%FORTRAN_EXE%" (
    echo Fortran compiler not found at %FORTRAN_EXE%.
    exit /b 2
)

set "TMP_DIR=%TEMP%\libRangeMap_fortran_verify"
if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"
set "SRC=%TMP_DIR%\\librangemap_verify.f90"
set "OUT=%TMP_DIR%\\librangemap_verify.exe"

echo program verify_map > "%SRC%"
echo   use librangemap_integer >> "%SRC%"
echo   implicit none >> "%SRC%"
echo   real(8) :: x >> "%SRC%"
echo   x = map_integer_value(0, 0, 100, -1.0d0, 1.0d0, .false.) >> "%SRC%"
echo   if ^(abs^(x - ^(-1.0d0^)^) ^> 1.0d-12^) stop 1 >> "%SRC%"
echo   x = map_integer_value(50, 0, 100, -1.0d0, 1.0d0, .false.) >> "%SRC%"
echo   if ^(abs^(x - 0.0d0^) ^> 1.0d-12^) stop 1 >> "%SRC%"
echo   x = map_integer_value(100, 0, 100, -1.0d0, 1.0d0, .false.) >> "%SRC%"
echo   if ^(abs^(x - 1.0d0^) ^> 1.0d-12^) stop 1 >> "%SRC%"
echo   print *, "Fortran wrapper verification passed." >> "%SRC%"
echo end program >> "%SRC%"

"%FORTRAN_EXE%" -o "%OUT%" "%ROOT%\wrappers\fortran\librangemap.f90" "%SRC%"
if errorlevel 1 exit /b 1

"%OUT%"
set "RC=%ERRORLEVEL%"
exit /b %RC%
