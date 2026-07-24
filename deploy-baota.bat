@echo off
chcp 65001 >nul
setlocal

cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File ".\deploy-baota.ps1"
set "BAOTA_EXIT=%ERRORLEVEL%"

echo.
echo ==== Git Sync ====
powershell -NoProfile -ExecutionPolicy Bypass -File ".\sync-git.ps1"
set "GIT_EXIT=%ERRORLEVEL%"

if not "%BAOTA_EXIT%"=="0" (
  echo.
  echo [Warn] Baota deploy failed with exit code %BAOTA_EXIT%.
)

if not "%GIT_EXIT%"=="0" (
  echo.
  echo [Error] Git sync failed with exit code %GIT_EXIT%.
)

echo.
pause

if not "%GIT_EXIT%"=="0" exit /b %GIT_EXIT%
if not "%BAOTA_EXIT%"=="0" exit /b %BAOTA_EXIT%
