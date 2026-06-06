@echo off
setlocal

set "ROOT=%~dp0..\.."
set "PATH=%ROOT%\librangemap\native;%PATH%"
set "PATH=C:\Tools\Ruby\bin;%PATH%"

ruby "%ROOT%\wrappers\ruby\verify\verify.rb"
set "RC=%ERRORLEVEL%"
exit /b %RC%
