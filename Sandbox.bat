@echo off
setlocal
cd /d "%~dp0"
title FightLab
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { & '.\run.ps1'; exit 0 } catch { Write-Host $_ -ForegroundColor Red; exit 1 }"
if errorlevel 1 pause
