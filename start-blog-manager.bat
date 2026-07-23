@echo off
cd /d "%~dp0"

if not exist ".\BlogManager.exe" (
  call ".\build-blog-manager.bat"
)

start "" ".\BlogManager.exe"
