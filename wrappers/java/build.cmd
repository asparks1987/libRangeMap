@echo off
setlocal

set "ROOT=%~dp0..\.."

if not defined JAVA_HOME (
    echo JAVA_HOME is required. 1>&2
    exit /b 1
)

if not exist "%ROOT%\wrappers\java\native" mkdir "%ROOT%\wrappers\java\native"
if not exist "%ROOT%\wrappers\java\build\classes" mkdir "%ROOT%\wrappers\java\build\classes"

"%JAVA_HOME%\bin\javac.exe" -encoding UTF-8 -d "%ROOT%\wrappers\java\build\classes" %ROOT%\wrappers\java\src\librangemap\*.java
if errorlevel 1 exit /b 1

call "%ROOT%\tools\zigcc.cmd" -shared -O3 -DLRM_BUILD_DLL -I"%JAVA_HOME%\include" -I"%JAVA_HOME%\include\win32" -I"%ROOT%\csrc" -o "%ROOT%\wrappers\java\native\librangemap_java.dll" "%ROOT%\wrappers\java\native\librangemap_jni.c" -L"%ROOT%\librangemap\native" -llibrangemap_core
if errorlevel 1 exit /b 1

echo Java wrapper build complete.
