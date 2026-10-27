param([string]$GodotPath, [switch]$Editor)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/scripts/core/godot.ps1"
$executable = Find-Godot $GodotPath
$arguments = @('--path', $PSScriptRoot)
if ($Editor) { $arguments += '--editor' }
& $executable @arguments
if ($LASTEXITCODE -ne 0) { throw "Godot exited with code $LASTEXITCODE" }
