@echo off
chcp 65001 >nul
setlocal

cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File ".\sync-typora-assets.ps1"

echo.
pause
