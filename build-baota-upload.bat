@echo off
chcp 65001 >nul
setlocal

cd /d "%~dp0"

echo.
echo [Hexo] Generating blog for Baota upload...
echo Project: %cd%
echo.

if not exist ".\node_modules\.bin\hexo.cmd" (
  echo [Error] Cannot find .\node_modules\.bin\hexo.cmd
  echo Please make sure this file is in the Hexo project root.
  echo.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File ".\sync-typora-assets.ps1"

if errorlevel 1 (
  echo.
  echo [Error] Failed to sync Typora assets.
  echo.
  pause
  exit /b 1
)

call ".\node_modules\.bin\hexo.cmd" generate

if errorlevel 1 (
  echo.
  echo [Error] Hexo generate failed.
  echo Check the error message above, then try again.
  echo.
  pause
  exit /b 1
)

if exist ".\baota-upload.zip" del /f /q ".\baota-upload.zip"

tar.exe -a -c -f ".\baota-upload.zip" -C ".\public" .

if errorlevel 1 (
  echo.
  echo [Error] Failed to create baota-upload.zip.
  echo.
  pause
  exit /b 1
)

echo.
echo [Done] Created upload package:
echo %cd%\baota-upload.zip
echo.
echo Upload this zip to your Baota website root, then unzip it there.
echo.
pause
