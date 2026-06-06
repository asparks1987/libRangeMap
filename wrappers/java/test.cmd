@echo off
setlocal

set "ROOT=%~dp0..\.."
set "PATH=%ROOT%\librangemap\native;%ROOT%\wrappers\java\native;%PATH%"

call "%ROOT%\wrappers\java\build.cmd" || exit /b 1

"%JAVA_HOME%\bin\java.exe" -ea -Djava.library.path=%ROOT%\wrappers\java\native -cp "%ROOT%\wrappers\java\build\classes" librangemap.Verify
