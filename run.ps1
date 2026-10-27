param([string]$GodotPath, [switch]$Editor)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/scripts/core/godot.ps1"
try {
    $executable = Find-Godot $GodotPath
} catch {
    if ($GodotPath -or $env:GODOT_PATH) { throw }
    & "$PSScriptRoot/scripts/core/install-godot.ps1" | Out-Host
    $executable = Find-Godot
}
# All combat assets are versioned; importing is safe on a fresh clone and offline.
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--editor','--path',$PSScriptRoot,'--import','--quit')
$arguments = @('--path', $PSScriptRoot)
if ($Editor) { $arguments += '--editor' }
& $executable @arguments
if ($LASTEXITCODE -ne 0) { throw "Godot exited with code $LASTEXITCODE" }
