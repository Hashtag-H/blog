@echo off
chcp 65001 >nul
setlocal

cd /d "%~dp0"

echo.
echo [Hexo] Generating blog...
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

echo.
echo [Done] Blog generated successfully.
echo Open: http://localhost:4000
echo.
pause
