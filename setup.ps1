param([string]$GodotPath)
$ErrorActionPreference = 'Stop'
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git is required.' }
. "$PSScriptRoot/scripts/core/godot.ps1"
$executable = Find-Godot $GodotPath
Write-Host "Git: $(git --version)"
Write-Host "Godot: $executable"
& "$PSScriptRoot/validate.ps1" -GodotPath $executable
Write-Host 'Setup complete. Use ./run.ps1 -Editor to open Godot, then F5.'
