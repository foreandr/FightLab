param([string]$GodotPath, [switch]$Editor)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/scripts/core/godot.ps1"
try {
    $executable = Find-Godot $GodotPath
} catch {
    if ($GodotPath -or $env:GODOT_PATH) { throw }
    Write-Host 'Godot not found. Installing the pinned portable version automatically...'
    $executable = & "$PSScriptRoot/scripts/core/install-godot.ps1"
    $executable = Find-Godot $executable
}
$arguments = @('--path', $PSScriptRoot)
if ($Editor) { $arguments += '--editor' }
& $executable @arguments
if ($LASTEXITCODE -ne 0) { throw "Godot exited with code $LASTEXITCODE" }
