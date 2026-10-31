@echo off
rem Build ShiftIt for Windows using the in-box .NET Framework C# compiler.
rem No SDK or Visual Studio required: csc.exe ships with Windows itself.
rem
rem Usage:  windows\build.cmd [output-dir]
rem Result: <output-dir>\ShiftIt.exe (default: windows\ShiftIt.exe)

setlocal
cd /d "%~dp0"

set "OUTDIR=%~dp0"
if not "%~1"=="" set "OUTDIR=%~1"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

set "FRAMEWORK=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319"
if not exist "%FRAMEWORK%\csc.exe" set "FRAMEWORK=%WINDIR%\Microsoft.NET\Framework\v4.0.30319"
if not exist "%FRAMEWORK%\csc.exe" (
    echo error: .NET Framework v4.0 C# compiler not found 1>&2
    exit /b 1
)

echo Building ShiftIt.exe with %FRAMEWORK%\csc.exe ...
"%FRAMEWORK%\csc.exe" /nologo /target:winexe /optimize+ ^
    /out:"%OUTDIR%ShiftIt.exe" ^
    /r:System.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll ^
    src\Native.cs src\Settings.cs src\Actions.cs src\WindowManager.cs src\TrayApp.cs src\Program.cs

if errorlevel 1 (
    echo error: build failed 1>&2
    exit /b 1
)

echo Done: %OUTDIR%ShiftIt.exe
exit /b 0
