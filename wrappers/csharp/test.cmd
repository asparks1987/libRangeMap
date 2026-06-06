@echo off

setlocal
set "ROOT=%~dp0..\.."
set "PATH=%ROOT%\librangemap\native;%PATH%"

dotnet run --project "%ROOT%\wrappers\csharp\Verify\Verify.csproj"
