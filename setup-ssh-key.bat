@echo off
chcp 65001 >nul
setlocal

cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File ".\setup-ssh-key.ps1"

echo.
pause
