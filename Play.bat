@echo off
setlocal
cd /d "%~dp0"
if errorlevel 1 goto failed
title FightLab
echo Updating FightLab...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { & '.\sync.ps1'; & '.\run.ps1'; exit 0 } catch { Write-Host $_ -ForegroundColor Red; exit 1 }"
if errorlevel 1 goto failed
exit /b 0

:failed
echo.
echo FightLab could not update or run. See the message above.
pause
exit /b 1
