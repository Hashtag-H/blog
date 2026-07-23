@echo off
chcp 65001 >nul
setlocal

cd /d "%~dp0"

set "CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist "%CSC%" set "CSC=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe"

if not exist "%CSC%" (
  echo [Error] Cannot find the .NET Framework C# compiler.
  echo Please install .NET Framework 4.x developer tools or use an Electron build instead.
  pause
  exit /b 1
)

if not exist ".\local-tools\blog-manager" mkdir ".\local-tools\blog-manager"

if not exist ".\local-tools\blog-manager\BlogManager.ico" (
  powershell -NoProfile -ExecutionPolicy Bypass -File ".\local-tools\blog-manager\create-icon.ps1"
)

echo [Build] Compiling BlogManager.exe...
"%CSC%" /nologo /codepage:65001 /target:winexe /platform:anycpu /win32icon:".\local-tools\blog-manager\BlogManager.ico" /out:".\BlogManager.exe" /reference:System.dll /reference:System.Core.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll /reference:System.Web.dll ".\local-tools\blog-manager\BlogManager.cs"

if errorlevel 1 (
  echo.
  echo [Error] Build failed.
  pause
  exit /b 1
)

echo.
echo [Done] .\BlogManager.exe
