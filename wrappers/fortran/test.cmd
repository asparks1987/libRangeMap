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
echo   real(8), allocatable :: object_mapped(:) >> "%SRC%"
echo   type(map_object_field_t) :: object_values(1), object_schema(1) >> "%SRC%"
echo   x = map_integer_value(0, 0, 100, -1.0d0, 1.0d0, .false.) >> "%SRC%"
echo   if ^(abs^(x - ^(-1.0d0^)^) ^> 1.0d-12^) stop 1 >> "%SRC%"
echo   x = map_integer_value(50, 0, 100, -1.0d0, 1.0d0, .false.) >> "%SRC%"
echo   if ^(abs^(x - 0.0d0^) ^> 1.0d-12^) stop 1 >> "%SRC%"
echo   x = map_integer_value(100, 0, 100, -1.0d0, 1.0d0, .false.) >> "%SRC%"
echo   if ^(abs^(x - 1.0d0^) ^> 1.0d-12^) stop 1 >> "%SRC%"
echo   object_schema(1)%name = "age" >> "%SRC%"
echo   object_schema(1)%family = MAP_FAMILY_INTEGER >> "%SRC%"
echo   object_schema(1)%int_input_min = 0 >> "%SRC%"
echo   object_schema(1)%int_input_max = 100 >> "%SRC%"
echo   object_schema(1)%output_min = -1.0d0 >> "%SRC%"
echo   object_schema(1)%output_max = 1.0d0 >> "%SRC%"
echo   object_values(1)%name = "age" >> "%SRC%"
echo   object_values(1)%family = MAP_FAMILY_INTEGER >> "%SRC%"
echo   object_values(1)%int_value = 50 >> "%SRC%"
echo   object_mapped = map_object_value(object_values, object_schema) >> "%SRC%"
echo   if ^(abs^(object_mapped(1) - 0.0d0^) ^> 1.0d-12^) stop 1 >> "%SRC%"
echo   print *, "Fortran wrapper verification passed." >> "%SRC%"
echo end program >> "%SRC%"

"%FORTRAN_EXE%" -o "%OUT%" "%ROOT%\wrappers\fortran\librangemap.f90" "%SRC%"
if errorlevel 1 exit /b 1

"%OUT%"
set "RC=%ERRORLEVEL%"
exit /b %RC%
