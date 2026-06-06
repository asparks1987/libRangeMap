@echo off
setlocal

set "ROOT=%~dp0..\.."
set "CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_LINKER=%USERPROFILE%\.rustup\toolchains\stable-x86_64-pc-windows-msvc\lib\rustlib\x86_64-pc-windows-msvc\bin\rust-lld.exe"

"%USERPROFILE%\.cargo\bin\cargo.exe" test --manifest-path "%ROOT%\wrappers\rust\Cargo.toml"
