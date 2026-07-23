@echo off
chcp 65001 >nul
setlocal

cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File ".\deploy-baota.ps1"

echo.
pause
