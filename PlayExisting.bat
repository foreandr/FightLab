@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0PlayExisting.ps1"
if errorlevel 1 (
  echo.
  echo Could not launch upstream 3D Fighter. See error above.
  pause
  exit /b 1
)
